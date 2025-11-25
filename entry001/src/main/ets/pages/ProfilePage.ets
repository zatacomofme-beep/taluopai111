import { router } from '@kit.ArkUI';
import { BottomNavBar } from '../common/BottomNavBar';
import { UserManager, UserInfo } from '../common/UserManager';
import { EnergyManager } from '../common/EnergyManager';
import { FortuneManager } from '../common/FortuneManager';
import { promptAction } from '@kit.ArkUI';
import common from '@ohos.app.ability.common'; // 🔴 1. 引入 common 模块

@Entry
@Component
struct ProfilePage {
  @State currentUser: UserInfo | null = null;
  @State currentEnergy: number = 0;
  @State isVip: boolean = false;
  @State birthDate: string = '未设置';
  @State isPrivacyMode: boolean = false;

  private userManager = UserManager.getInstance();
  private energyManager = EnergyManager.getInstance();
  private fortuneManager = FortuneManager.getInstance();

  // 🔴 2. 添加显式返回类型 Promise<void>
  async aboutToAppear(): Promise<void> {
    this.refreshData();
    this.isPrivacyMode = await this.fortuneManager.isPrivacyMode();
  }

  // 🔴 2. 添加显式返回类型 void
  onPageShow(): void {
    this.refreshData();
  }

  refreshData(): void {
    this.currentUser = this.userManager.getCurrentUser();
    this.currentEnergy = this.energyManager.getEnergy();
    void (async () => {
      this.isVip = await this.fortuneManager.isVip();
    })();
  }

  // 模拟选择出生日期
  handleEditBirth(): void {
    promptAction.showDialog({
      title: '设置出生年月',
      message: '请输入您的出生年月 (如 1995-08-05)',
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '确定', color: '#FF69B4' }
      ],
    }, (err, data) => {
      if (data.index === 1) {
        this.birthDate = '1998.06.15';
        promptAction.showToast({ message: '📅 生日已更新' });
      }
    });
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
        this.currentUser = null;
        promptAction.showToast({ message: '已退出' });
        this.refreshData();
      }
    });
  }

  async handleLogin(): Promise<void> {
    try {
      // 🔴 3. 修复 Context 类型报错：强制转换为 common.UIAbilityContext
      const context = getContext(this) as common.UIAbilityContext;
      const user = await this.userManager.login(context);
      this.currentUser = user;
      promptAction.showToast({ message: `欢迎回来，${user.nickname}` });
    } catch (e) {
      // 登录失败或取消
    }
  }

  @Builder
  InfoItem(icon: string, label: string, value: string, onClick?: () => void, showArrow: boolean = true) {
    Row() {
      Row() {
        Text(icon).fontSize(20).margin({ right: 12 })
        Text(label).fontSize(16).fontColor('#333')
      }
      Blank()
      Row() {
        Text(value).fontSize(14).fontColor('#999').margin({ right: 4 })
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
    Stack({ alignContent: Alignment.Bottom }) {
      // 背景
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [['#FDFBFB', 0.0], ['#F2F4F8', 1.0]]
        })

      Scroll() {
        Column() {
          // 1. 头部用户信息卡片
          Column() {
            if (this.currentUser) {
              Row() {
                // 🔴 4. 修复资源引用报错：改用 $r('app.media.startIcon')
                Image(this.currentUser.avatar || $r('app.media.startIcon'))
                  .width(72).height(72).borderRadius(36)
                  .objectFit(ImageFit.Cover)
                  .backgroundColor('#EEE')

                Column({ space: 6 }) {
                  Text(this.currentUser.nickname || '华为用户')
                    .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333')

                  Row({ space: 8 }) {
                    Text(this.isVip ? '👑 尊贵会员' : '🌱 治愈旅人')
                      .fontSize(12).fontColor(this.isVip ? '#D4AF37' : '#888')
                      .backgroundColor(this.isVip ? '#FFF8E1' : '#F0F0F0')
                      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                      .borderRadius(10)

                    Text(`ID: ${this.currentUser.userId.substring(0, 6)}...`)
                      .fontSize(12).fontColor('#AAA')
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .margin({ left: 16 })
              }
              .width('100%')
              .padding({ top: 20, bottom: 20 })
            } else {
              // 未登录状态
              Column({ space: 12 }) {
                Text('👤').fontSize(48)
                Text('登录华为账号，同步你的治愈之旅').fontSize(14).fontColor('#888')
                Button('立即登录')
                  .backgroundColor('#333')
                  .fontColor(Color.White)
                  .height(36)
                  .fontSize(14)
                  .onClick(() => this.handleLogin())
              }
              .width('100%')
              .padding({ top: 30, bottom: 30 })
              .alignItems(HorizontalAlign.Center)
            }
          }
          .backgroundColor(Color.White)
          .borderRadius(20)
          .padding(20)
          .margin({ top: 20, left: 20, right: 20 })
          .shadow({ radius: 20, color: 'rgba(0,0,0,0.03)', offsetY: 5 })

          // 2. 能量卡片
          Row() {
            Column() {
              Text(this.currentEnergy.toString()).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#FF69B4')
              Text('当前心力').fontSize(12).fontColor('#888').margin({ top: 4 })
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)

            Divider().vertical(true).height(30).color('#F0F0F0')

            Column() {
              Text('每日 00:00').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
              Text('自动恢复').fontSize(12).fontColor('#888').margin({ top: 4 })
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)
          }
          .backgroundColor(Color.White)
          .borderRadius(20)
          .padding(20)
          .margin({ top: 16, left: 20, right: 20 })
          .shadow({ radius: 20, color: 'rgba(0,0,0,0.03)', offsetY: 5 })

          // 3. 功能列表
          Column() {
            Text('个人资料').fontSize(14).fontColor('#888').margin({ left: 8, bottom: 8 })

            this.InfoItem('🎂', '出生年月', this.birthDate, () => this.handleEditBirth())
            this.InfoItem('☁️', '数据云同步', this.currentUser ? '已就绪' : '未登录', () => {
              // 跳转回首页触发同步，或者在这里复制同步逻辑
              router.back();
              promptAction.showToast({message: '请在首页点击云图标进行同步'});
            })

            Text('设置').fontSize(14).fontColor('#888').margin({ left: 8, top: 12, bottom: 8 })

            // 隐私模式开关
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
                .onChange((isOn) => this.togglePrivacy(isOn))
            }
            .width('100%')
            .padding(20)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .margin({ bottom: 12 })

            if (this.currentUser) {
              Button('退出登录')
                .backgroundColor('#FFF0F5')
                .fontColor('#FF69B4')
                .width('100%')
                .height(50)
                .borderRadius(16)
                .margin({ top: 20 })
                .onClick(() => this.handleLogout())
            }
          }
          .padding(20)
          .width('100%')

          Blank().height(100) // 底部留白
        }
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)

      // 底部导航栏 (需要更新 BottomNavBar 支持 Profile tab)
      BottomNavBar({ current: 'profile' })
    }
    .width('100%')
    .height('100%')
  }
}