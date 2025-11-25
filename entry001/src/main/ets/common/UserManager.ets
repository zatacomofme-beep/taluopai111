import { authentication } from '@kit.AccountKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import common from '@ohos.app.ability.common';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN_ID = 0x0000;
const LOG_TAG = 'UserManager';

// 定义用户信息接口
export interface UserInfo {
  userId: string; // 对应 unionID
  token: string;  // idToken
  nickname?: string;
  avatar?: string;
}

export class UserManager {
  private static instance: UserManager;
  private currentUser: UserInfo | null = null;

  private constructor() {}

  public static getInstance(): UserManager {
    if (!UserManager.instance) {
      UserManager.instance = new UserManager();
    }
    return UserManager.instance;
  }

  public isLoggedIn(): boolean {
    return this.currentUser !== null;
  }

  public getCurrentUser(): UserInfo | null {
    return this.currentUser;
  }

  /**
   * 核心登录方法
   * 修改为 Authorization 模式以获取头像和昵称
   */
  public async login(context: common.UIAbilityContext): Promise<UserInfo> {
    if (this.currentUser) {
      return this.currentUser;
    }

    // 1. 改用 AuthorizationRequest，这样才能申请 'profile' 权限获取头像昵称
    const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
    authRequest.scopes = ['openid', 'profile']; // 请求 openid 和 个人信息
    authRequest.forceAuthorization = false; // 先尝试静默登录
    authRequest.state = util.generateRandomUUID();

    const controller = new authentication.AuthenticationController(context);

    try {
      hilog.info(DOMAIN_ID, LOG_TAG, '尝试静默登录...');
      // 执行请求
      const response = await controller.executeRequest(authRequest);
      // 断言为 Authorization 响应类型
      return this.processLoginSuccess(response as authentication.AuthorizationWithHuaweiIDResponse);
    } catch (err) {
      const error = err as BusinessError;
      hilog.warn(DOMAIN_ID, LOG_TAG, `静默登录失败 Code: ${error.code}`);

      // 1001502001: 未登录华为账号
      // 1001500003: 账号不支持静默登录
      if (this.shouldTryInteractiveLogin(error.code)) {
        hilog.info(DOMAIN_ID, LOG_TAG, '尝试交互式登录...');
        authRequest.forceAuthorization = true; // 强制拉起授权页
        try {
          const response = await controller.executeRequest(authRequest);
          return this.processLoginSuccess(response as authentication.AuthorizationWithHuaweiIDResponse);
        } catch (interactiveErr) {
          const iErr = interactiveErr as BusinessError;
          hilog.error(DOMAIN_ID, LOG_TAG, `交互登录失败: ${iErr.code}, ${iErr.message}`);
          throw iErr as Error;
        }
      } else {
        throw error as Error;
      }
    }
  }

  private shouldTryInteractiveLogin(errorCode: number): boolean {
    const interactiveCodes = [1001502001, 1001500003, 1001500001, 1001500002];
    return interactiveCodes.includes(errorCode);
  }

  /**
   * 处理登录成功的响应
   * 参数类型改为 AuthorizationWithHuaweiIDResponse
   */
  private processLoginSuccess(response: authentication.AuthorizationWithHuaweiIDResponse): UserInfo {
    const credential = response.data;

    if (!credential) {
      throw new Error("登录失败: 未获取到凭证信息");
    }

    const userId = credential.unionID || credential.openID;

    // 修复 'any' 报错：
    // idToken 在 AuthorizationWithHuaweiIDCredential 中通常是可选属性
    // 如果类型定义中包含 idToken，直接使用；如果不包含，使用 Record 类型安全访问
    let idToken = credential.idToken;
    if (!idToken) {
      // 尝试从对象中以字符串索引方式获取，避开类型检查，同时不使用 any
      const credMap = credential as Record<string, Object>;
      if (credMap['idToken'] && typeof credMap['idToken'] === 'string') {
        idToken = credMap['idToken'] as string;
      } else {
        // 降级使用 authorizationCode (后端需支持 code 换 token)
        idToken = credential.authorizationCode;
      }
    }

    if (!userId || !idToken) {
      throw new Error("获取用户信息不完整 (缺少 UnionID 或 Token)");
    }

    this.currentUser = {
      userId: userId,
      token: idToken,
      // AuthorizationCredential 中包含 nickName (注意大小写) 和 avatarUri
      nickname: credential.nickName || '华为用户',
      avatar: credential.avatarUri || ''
    };

    hilog.info(DOMAIN_ID, LOG_TAG, `登录成功, User: ${this.currentUser.nickname}`);
    return this.currentUser;
  }

  public logout() {
    this.currentUser = null;
    hilog.info(DOMAIN_ID, LOG_TAG, '用户已退出');
  }
}