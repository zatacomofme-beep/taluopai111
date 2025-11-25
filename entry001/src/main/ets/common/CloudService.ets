import http from '@ohos.net.http';
import { UserManager } from './UserManager';
import { FortuneManager } from './FortuneManager';

export class CloudService {
  // 🔴 核心修改：换成你的华为云服务器公网 IP
  private static readonly BASE_URL = 'http://1.94.149.144:3000/api';
  private static readonly SERVER_ROOT = 'http://1.94.149.144:3000';

  static async checkConnection(): Promise<boolean> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(`${CloudService.SERVER_ROOT}/`, {
        method: http.RequestMethod.GET,
        readTimeout: 3000,
        connectTimeout: 3000
      });
      return response.responseCode === 200;
    } catch (err) {
      return false;
    } finally {
      httpRequest.destroy();
    }
  }

  static async backupData(userId: string, token: string, allData: string): Promise<boolean> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(`${CloudService.BASE_URL}/sync/upload`, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: { userId: userId, token: token, data: JSON.parse(allData) },
        expectDataType: http.HttpDataType.OBJECT,
      });
      if (response.responseCode === 200) {
        const res = response.result as Record<string, Object>;
        return res['code'] === 200;
      }
      return false;
    } catch (err) {
      return false;
    } finally {
      httpRequest.destroy();
    }
  }

  static async restoreData(userId: string, token: string): Promise<string | null> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(`${CloudService.BASE_URL}/sync/download`, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: { userId: userId, token: token },
        expectDataType: http.HttpDataType.OBJECT,
      });
      if (response.responseCode === 200) {
        const res = response.result as Record<string, Object>;
        if (res['code'] === 200 && res['data']) {
          return JSON.stringify(res['data']);
        }
      }
      return null;
    } catch (err) {
      return null;
    } finally {
      httpRequest.destroy();
    }
  }

  // 自动静默备份
  static async autoSave() {
    const userMgr = UserManager.getInstance();
    const fortuneMgr = FortuneManager.getInstance();

    const user = userMgr.getCurrentUser();
    if (!userMgr.isLoggedIn() || !user) {
      return;
    }

    const allData = await fortuneMgr.exportAllData();

    // 使用类名调用
    CloudService.backupData(user.userId, user.token, allData).then((success) => {
      if (success) console.info('✅ CloudService: 自动备份成功');
      else console.warn('⚠️ CloudService: 自动备份失败');
    });
  }

  // 自动静默恢复
  static async autoRestore(): Promise<boolean> {
    const userMgr = UserManager.getInstance();
    const fortuneMgr = FortuneManager.getInstance();

    const user = userMgr.getCurrentUser();
    if (!userMgr.isLoggedIn() || !user) return false;

    // 使用类名调用
    const jsonStr = await CloudService.restoreData(user.userId, user.token);

    if (jsonStr) {
      await fortuneMgr.importData(jsonStr);
      console.info('✅ CloudService: 数据已同步至本地');
      return true;
    }
    return false;
  }
}