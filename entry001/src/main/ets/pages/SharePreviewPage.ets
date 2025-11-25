import { router } from '@kit.ArkUI';
import { componentSnapshot } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { abilityAccessCtrl } from '@kit.AbilityKit';
import common from '@ohos.app.ability.common';
import { ImageSaver } from '../common/ImageSaver';
import { ShareHelper } from '../common/ShareHelper';
import { TarotCard } from '../model/TarotData';

interface ShareParams {
  card: TarotCard;
  todayDate: string;
  todayWeek: string;
  goldQuote: string;
  privacyMode: boolean;
}

@Entry
@Component
struct SharePreviewPage {
  @State card: TarotCard | null = null;
  @State todayDate: string = '';
  @State todayWeek: string = '';
  @State goldQuote: string = '';
  @State privacyMode: boolean = false;
  @State shareTheme: string = 'soft'; // soft | minimal | star
  @State isPosterReady: boolean = false;

  private context = getContext(this) as common.UIAbilityContext;
  private POSTER_ID = 'poster_component_id';
  // 二维码链接常量
  private QR_CODE_URL = 'https://taluopai.obs.cn-southwest-2.myhuaweicloud.com/tarot_cards/qr_code.png';

  aboutToAppear() {
    const params = router.getParams() as ShareParams;
    if (params) {
      this.card = params.card;
      this.todayDate = params.todayDate;
      this.todayWeek = params.todayWeek;
      this.goldQuote = params.goldQuote;
      this.privacyMode = params.privacyMode;
    }
    // 稍微延迟一点显示海报，给转场动画留时间
    setTimeout(() => {
      this.isPosterReady = true;
    }, 300);
  }

  // 智能图片源处理
  getCardImageSource(url: string): ResourceStr {
    if (url.startsWith('http')) {
      return url;
    }
    return $rawfile(url);
  }

  getThemeBgColor(): ResourceColor {
    if (this.shareTheme === 'minimal') return '#F7F7F7';
    if (this.shareTheme === 'star') return '#1A1A2E';
    return Color.White; // soft
  }

  getThemePrimaryTextColor(): string {
    return this.shareTheme === 'star' ? '#EEEEEE' : '#333333';
  }

  getThemeSecondaryTextColor(): string {
    return this.shareTheme === 'star' ? '#BBBBBB' : '#888888';
  }

  async executeSave() {
    try {
      const ok = await this.ensureAlbumPermissions();
      if (!ok) { promptAction.showToast({ message: '需要相册权限', duration: 2500 }); return; }
      const pixelMap = await componentSnapshot.get(this.POSTER_ID);
      await ImageSaver.saveToAlbum(this.context, pixelMap);
    } catch (err) {
      promptAction.showToast({ message: '保存失败', duration: 2000 });
    }
  }

  async handleSystemShare() {
    try {
      promptAction.showToast({ message: '正在生成...', duration: 1000 });
      await ShareHelper.snapshotAndShare(this.context, this.POSTER_ID);
    } catch (err) {
      promptAction.showToast({ message: '分享失败', duration: 2000 });
    }
  }

  async ensureAlbumPermissions(): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(this.context, ['ohos.permission.READ_IMAGEVIDEO', 'ohos.permission.WRITE_IMAGEVIDEO']);
      return Array.isArray(result.authResults) ? result.authResults.every(v => v === 0) : true;
    } catch { return false; }
  }

  @Builder
  ThemeButton(themeKey: string, label: string) {
    Button(label)
      .onClick(() => { this.shareTheme = themeKey; })
      .backgroundColor(this.shareTheme === themeKey ? '#333' : '#EEE')
      .fontColor(this.shareTheme === themeKey ? '#FFF' : '#000')
      .height(32)
      .fontSize(12)
      .borderRadius(16)
      .animation({ duration: 200 })
  }

  build() {
    Column() {
      // 1. 顶部导航栏
      Row() {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Text('✕').fontSize(18).fontColor('#333')
        }
        .width(40).height(40).backgroundColor('rgba(0,0,0,0.05)')
        .onClick(() => router.back())

        Text('分享预览').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center).margin({ right: 40 })
      }
      .width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor(Color.White)

      // 2. 主题切换栏
      Row({ space: 12 }) {
        this.ThemeButton('soft', '轻柔')
        this.ThemeButton('minimal', '极简')
        this.ThemeButton('star', '星空')
      }
      .width('100%').justifyContent(FlexAlign.Center).padding({ top: 10, bottom: 10 }).backgroundColor(Color.White)

      // 3. 海报预览区域 (可滚动)
      Scroll() {
        Column() {
          if (this.card) {
            // --- 海报容器 ---
            Column() {
              // 头部日期
              Row() {
                Column() {
                  Text(this.todayDate).fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.getThemePrimaryTextColor())
                  Text(this.todayWeek).fontSize(12).fontColor(this.getThemeSecondaryTextColor())
                }.alignItems(HorizontalAlign.Start)
                Blank()
                Text("治愈之书").fontSize(14).fontColor('#FF69B4').fontWeight(FontWeight.Medium)
              }.width('100%').padding({ left: 20, right: 20, top: 24 })

              // 卡牌大图
              Image(this.getCardImageSource(this.card.image))
                .width('100%').aspectRatio(2/3).borderRadius(12).margin({ top: 16 })
                .shadow({ radius: 10, color: 'rgba(0,0,0,0.1)', offsetY: 5 })
                .alt($rawfile('card_back.png'))

              // 文字解读
              Column() {
                Text(this.card.name).fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.getThemePrimaryTextColor()).margin({ top: 20 })
                Text(this.card.meaning).fontSize(14).fontColor(this.getThemeSecondaryTextColor()).margin({ top: 6, bottom: 16 })

                if (!this.privacyMode) {
                  Text(this.card.desc).fontSize(15).fontColor(this.getThemePrimaryTextColor()).opacity(0.9).textAlign(TextAlign.Center).lineHeight(24)
                  if (this.goldQuote) {
                    Text(`“ ${this.goldQuote} ”`).fontSize(14).fontColor('#FF69B4').fontStyle(FontStyle.Italic).margin({ top: 16 })
                  }
                } else {
                  Text("🔒 私密模式").fontSize(12).fontColor(this.getThemeSecondaryTextColor()).margin({ top: 10 })
                }
              }.padding(20)

              // 底部二维码
              Row() {
                Text("扫码获取你的治愈卡片").fontSize(10).fontColor(this.getThemeSecondaryTextColor())
                Blank()
                Image(this.QR_CODE_URL).width(48).height(48).opacity(0.8).alt($rawfile('qr_code.png'))
              }.width('100%').padding({ left: 20, right: 20, bottom: 24 })

            }
            .width('90%') // 海报宽度占屏幕 90%
            .backgroundColor(this.getThemeBgColor())
            .borderRadius(20)
            .shadow({ radius: 30, color: 'rgba(0,0,0,0.15)', offsetY: 10 })
            .margin({ top: 20, bottom: 40 }) // 上下留白
            .id(this.POSTER_ID)
            // --- 海报结束 ---
          }
        }.width('100%')
      }
      .layoutWeight(1) // 占据剩余空间
      .backgroundColor('#F5F7FA')
      .scrollBar(BarState.Off)

      // 4. 底部操作栏
      Row({ space: 16 }) {
        Button('保存相册')
          .backgroundColor(Color.White)
          .fontColor('#333')
          .border({ width: 1, color: '#E0E0E0' })
          .layoutWeight(1)
          .height(50)
          .borderRadius(25)
          .fontSize(16)
          .onClick(() => this.executeSave())

        Button('发送给好友')
          .backgroundColor('#333')
          .fontColor('#FFF')
          .layoutWeight(1)
          .height(50)
          .borderRadius(25)
          .fontSize(16)
          .shadow({ radius: 10, color: 'rgba(0,0,0,0.2)', offsetY: 5 })
          .onClick(() => this.handleSystemShare())
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16, bottom: 16 })
      .backgroundColor(Color.White)
      .shadow({ radius: 20, color: 'rgba(0,0,0,0.05)', offsetY: -5 })
    }
    .width('100%')
    .height('100%')
  }
}