import { router, promptAction } from '@kit.ArkUI';
import { FortuneManager } from '../common/FortuneManager';
import { UserManager } from '../common/UserManager';
import common from '@ohos.app.ability.common';

@Entry
@Component
struct SettingsPage {
  @State isPrivacyMode: boolean = false;
  private fortuneManager = FortuneManager.getInstance();
  private userManager = UserManager.getInstance();

  async aboutToAppear() {
    this.isPrivacyMode = await this.fortuneManager.isPrivacyMode();
  }

  async togglePrivacy(isOn: boolean): Promise<void> {
    this.isPrivacyMode = isOn;
    await this.fortuneManager.setPrivacyMode(isOn);
    promptAction.showToast({ message: isOn ? '🔒 隐私模式已开启' : '🔓 隐私模式已关闭' });
  }

  handleLogout(): void {
    promptAction.showDialog({
      title: '退出登录',
      message: '确定要退出当前账号吗？',
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '退出', color: '#FF0000' }
      ]
    }, (err, data) => {
      if (data.index === 1) {
        this.userManager.logout();
        promptAction.showToast({ message: '已退出' });
        router.back();
      }
    });
  }

  handleAccountCancellation(): void {
    promptAction.showDialog({
      title: '⚠️ 账号注销',
      message: '注销后，您的所有数据（包括心力、牌阵记录、会员权益）将永久丢失且无法恢复。\n\n确定要继续吗？',
      buttons: [
        { text: '取消', color: '#333333' },
        { text: '确认注销', color: '#FF0000' }
      ]
    }, (err, data) => {
      if (data.index === 1) {
        // 模拟注销逻辑
        this.userManager.logout();
        promptAction.showToast({ message: '账号已注销' });
        router.back();
      }
    });
  }

  handleFeedback(): void {
    // 实际项目中可以跳转到反馈页面或打开客服会话
    promptAction.showToast({ message: '请发送邮件至 alizabos@163.com 反馈问题' });
  }

  handleShareApp(): void {
    // 简单的分享提示，实际可调用系统分享
    promptAction.showToast({ message: '感谢分享！链接已复制到剪贴板' });
  }

  @Builder
  InfoItem(icon: string, label: string, onClick?: () => void, showArrow: boolean = true, value: string = '') {
    Row() {
      Row() {
        Text(icon).fontSize(20).margin({ right: 12 })
        Text(label).fontSize(16).fontColor('#333')
      }
      Blank()
      Row() {
        if (value) {
          Text(value).fontSize(14).fontColor('#999').margin({ right: 4 })
        }
        if (showArrow) {
          Text('›').fontSize(18).fontColor('#CCC').margin({ bottom: 2 })
        }
      }
    }
    .width('100%')
    .height(56)
    .backgroundColor(Color.White)
    .padding({ left: 20, right: 20 })
    .borderRadius(16)
    .margin({ bottom: 12 })
    .onClick(() => {
      if (onClick) onClick();
    })
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Image($r('app.media.ic_public_back')) // 假设有这个资源，或者用 Text 替代
          .width(24)
          .height(24)
          .onClick(() => router.back())
        
        Text('设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .margin({ left: 16 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

      Scroll() {
        Column() {
          // 1. 隐私设置
          Text('隐私').fontSize(14).fontColor('#888').margin({ left: 8, top: 20, bottom: 8 }).width('100%')
          
          Row() {
            Row() {
              Text('🔒').fontSize(20).margin({ right: 12 })
              Column() {
                Text('隐私保护模式').fontSize(16).fontColor('#333')
                Text('隐藏首页文字和分享内容').fontSize(12).fontColor('#AAA').margin({ top: 2 })
              }.alignItems(HorizontalAlign.Start)
            }
            Toggle({ type: ToggleType.Switch, isOn: this.isPrivacyMode })
              .selectedColor('#FF69B4')
              .onChange((isOn: boolean) => this.togglePrivacy(isOn))
          }
          .width('100%')
          .padding(20)
          .backgroundColor(Color.White)
          .borderRadius(16)
          .margin({ bottom: 12 })

          // 2. 通用
          Text('通用').fontSize(14).fontColor('#888').margin({ left: 8, top: 20, bottom: 8 }).width('100%')
          this.InfoItem('💬', '问题反馈', () => this.handleFeedback())
          this.InfoItem('🔗', '分享 App', () => this.handleShareApp())

          // 3. 账号
          Text('账号').fontSize(14).fontColor('#888').margin({ left: 8, top: 20, bottom: 8 }).width('100%')
          this.InfoItem('⚠️', '账号注销', () => this.handleAccountCancellation())
          
          Button('退出登录')
            .backgroundColor('#FFF0F5')
            .fontColor('#FF69B4')
            .width('100%')
            .height(50)
            .borderRadius(16)
            .margin({ top: 20 })
            .onClick(() => this.handleLogout())

        }
        .padding(20)
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }
}
