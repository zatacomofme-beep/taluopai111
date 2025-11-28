import { router } from '@kit.ArkUI';
import { BottomNavBar } from '../common/BottomNavBar';
import { UserManager, UserInfo } from '../common/UserManager';
import { EnergyManager } from '../common/EnergyManager';
import { FortuneManager } from '../common/FortuneManager';
import { promptAction } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ProfilePage {
  @State currentUser: UserInfo | null = null;
  @State currentEnergy: number = 0;
  @State isVip: boolean = false;
  // 用于 DatePicker 的日期对象
  @State selectedDate: Date = new Date('1995-01-01');
  // 用于展示的字符串
  @State birthDateText: string = '未设置';

  private userManager = UserManager.getInstance();
  private energyManager = EnergyManager.getInstance();
  private fortuneManager = FortuneManager.getInstance();

  async aboutToAppear(): Promise<void> {
    this.refreshData();
  }

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

  // 🟢 修复2：使用 DatePickerDialog 选择出生年月
  handleEditBirth(): void {
    DatePickerDialog.show({
      start: new Date("1900-1-1"),
      end: new Date(), // 结束时间为今天
      selected: this.selectedDate,
      onAccept: (value: DatePickerResult) => {
        // value.year, value.month(0-11), value.day
        if (value.year !== undefined && value.month !== undefined && value.day !== undefined) {
          this.selectedDate.setFullYear(value.year, value.month, value.day);
          // 格式化显示：YYYY-MM-DD
          this.birthDateText = `${value.year}-${(value.month + 1).toString().padStart(2, '0')}-${value.day.toString().padStart(2, '0')}`;
          promptAction.showToast({ message: '📅 生日已更新' });
          // TODO: 如果需要，这里可以调用 FortuneManager 保存生日信息
        }
      }
    });
  }


  // 🟢 修复1：完善登录逻辑与反馈
  async handleLogin(): Promise<void> {
    try {
      // 显式获取 UIAbilityContext
      const context = getContext(this) as common.UIAbilityContext;

      // 给用户一个反馈，防止点击没反应
      promptAction.showToast({ message: '正在唤起华为登录...', duration: 1500 });

      const user = await this.userManager.login(context);
      this.currentUser = user;
      promptAction.showToast({ message: `欢迎回来，${user.nickname}` });
    } catch (e) {
      const err = e as BusinessError;
      console.error(`ProfilePage Login Error: ${err.code} - ${err.message}`);

      // 根据错误码给出更友好的提示
      let msg = '登录失败';
      if (err.code === 1001502001) msg = '请先在系统设置中登录华为账号'; // 模拟器常见
      else if (err.code === 1001500001) msg = '签名指纹未配置 (Client ID)';
      else if (err.code === 12300001) msg = '系统服务不可用';

      promptAction.showToast({ message: msg, duration: 3000 });
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
                // 使用 resource 引用本地图片作为默认头像
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
            if (this.currentUser) {
              Text('个人资料').fontSize(14).fontColor('#888').margin({ left: 8, bottom: 8 })
              // 🟢 修复：点击弹出 DatePicker 选择器
              this.InfoItem('🎂', '出生年月', this.birthDateText, () => this.handleEditBirth())
            }

            Text('更多服务').fontSize(14).fontColor('#888').margin({ left: 8, top: 20, bottom: 8 })
            this.InfoItem('📖', '关于我们', '', () => promptAction.showToast({ message: '关于我们：治愈系塔罗 v1.0' }))
            this.InfoItem('📄', '用户协议', '', () => router.pushUrl({ url: 'pages/UserAgreementPage' }))
            this.InfoItem('🛡️', '隐私政策', '', () => router.pushUrl({ url: 'pages/PrivacyPolicyPage' }))
            this.InfoItem('🎧', '联系客服', '', () => promptAction.showToast({ message: '客服将会尽快联系您' }))
            this.InfoItem('💪', '常见鼓励', '', () => promptAction.showToast({ message: '相信自己，未来可期！' }))
            this.InfoItem('⭐', '五星鼓励', '', () => promptAction.showToast({ message: '感谢您的五星好评！' }))
            this.InfoItem('⚙️', '设置', '', () => router.pushUrl({ url: 'pages/SettingsPage' }))
          }
          .padding(20)
          .width('100%')

          Blank().height(100) // 底部留白
        }
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)

      // 底部导航栏
      BottomNavBar({ current: 'profile' })
    }
    .width('100%')
    .height('100%')
  }
}