// 路径: ets/pages/Index.ets
// V39.0 修复版：修复 rotate 语法报错，集成自动展览厅，优化光影特效

import { FortuneManager, CardRecord } from '../common/FortuneManager';
import { systemShare } from '@kit.ShareKit';
import { image } from '@kit.ImageKit';
import { fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { TarotCard, TAROT_DECK } from '../model/TarotData';
import common from '@ohos.app.ability.common';
import { abilityAccessCtrl } from '@kit.AbilityKit';
import { promptAction, curves, router, componentSnapshot } from '@kit.ArkUI';
import { formBindingData, formProvider } from '@kit.FormKit';
import { BottomNavBar } from '../common/BottomNavBar';
import { ImageSaver } from '../common/ImageSaver';

@Entry
@Component
struct Index {
  @State currentCard: TarotCard | null = null;
  @State isFlipped: boolean = false;
  @State showResultText: boolean = false;
  @State isVip: boolean = false;
  @State cardImage: Resource = $rawfile('card_back.png');

  // 🌈 珍稀度颜色 (用于光晕)
  @State rarityColor: string = 'rgba(0,0,0,0.15)';
  @State rarityLevel: number = 1; // 1(普通) - 7(传说)

  // 🎬 动画状态
  @State angle: number = 0;
  @State floatOffsetY: number = 0;
  @State floatRotateZ: number = 0;
  @State clickScale: number = 1;

  // ✨ 呼吸与光影
  @State mysteryScale: number = 1;
  @State shadowOpacity: number = 0.15;
  @State shadowRadius: number = 10;
  @State shadowOffsetY: number = 5;
  @State shadowColor: string = 'rgba(0,0,0,0.2)';

  @State guideOpacity: number = 1;

  // 🃏 洗牌动画变量
  @State shuffleOffsetX: number = 0;
  @State shuffleRotate: number = 0;
  @State shuffleScale: number = 1;

  // 弹窗与数据
  @State isShareSheetOpen: boolean = false;
  @State isGallerySheetOpen: boolean = false;
  @State isPosterReady: boolean = false;
  @State galleryList: CardRecord[] = [];
  @State collectionProgress: number = 0;

  @State todayDate: string = "";
  @State todayWeek: string = "";
  @State mainScale: number = 1;
  @State mainOffsetY: number = 0;
  @State mainRotateZ: number = 0;
  @State deckOffset1: number = 0;
  @State deckOffset2: number = 0;
  @State deckOpacity: number = 0;
  @State deckScale: number = 0.9;
  @State deckAngle1: number = -5;
  @State deckAngle2: number = 5;

  // P0：情绪签到与金句、小任务
  @State moodIndex: number = -1; // 0-4
  @State moodNote: string = '';
  @State goldQuote: string = '';
  @State dailyTask: string = '';

  // P1：分享主题与贴纸
  @State shareTheme: string = 'soft'; // soft|minimal|star
  @State stickers: string[] = [];

  // P2：呼吸引导
  @State isBreathingSheetOpen: boolean = false;
  @State breathingPhase: string = '准备';
  @State breathingRemaining: number = 60;
  private breathingTimerId: number | null = null;

  // P4：私密模式
  @State privacyMode: boolean = false;

  // 底部导航选中（仅样式）
  @State activeTab: number = 0;

  private manager = FortuneManager.getInstance();
  private context = getContext(this) as common.UIAbilityContext;
  private POSTER_ID = 'poster_component_id';

  private asyncAnimateTo(duration: number, curve: Curve | string | ICurve, updateFn: () => void): Promise<void> {
    return new Promise((resolve) => {
      animateTo({ duration: duration, curve: curve, onFinish: resolve }, updateFn);
    });
  }

  async aboutToAppear() {
    await this.manager.init(this.context);
    this.checkState();
    this.initDate();
    this.startGuideAnimation();
    const mood = await this.manager.getTodayMood();
    this.moodIndex = mood.mood;
    this.moodNote = mood.note;
    const aff = await this.manager.getTodayAffirmations();
    this.goldQuote = aff.quote;
    this.dailyTask = aff.task;
    this.privacyMode = await this.manager.isPrivacyMode();
  }

  initDate() {
    const now = new Date();
    this.todayDate = `${now.getFullYear()}.${(now.getMonth() + 1).toString().padStart(2, '0')}.${now.getDate().toString().padStart(2, '0')}`;
    const weeks = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    this.todayWeek = weeks[now.getDay()];
  }

  async checkState() {
    this.isVip = await this.manager.isVip();
    const savedCard = await this.manager.checkTodayCard();
    if (savedCard) {
      this.currentCard = savedCard;
      this.angle = 180;
      this.isFlipped = true;
      this.showResultText = true;
      this.startBreathingAnimation();
      this.updateForm(savedCard);
    } else {
      this.resetUI();
    }
  }

  resetUI() {
    this.currentCard = null;
    this.cardImage = $rawfile('card_back.png');
    this.angle = 0;
    this.isFlipped = false;
    this.showResultText = false;
    this.rarityColor = 'rgba(0,0,0,0.15)';

    this.stopBreathingAnimation();
    this.mainReset();
  }

  mainReset() {
    this.shuffleOffsetX = 0;
    this.shuffleRotate = 0;
    this.shuffleScale = 1;
  }

  updateForm(card: TarotCard) {
    try {
      const formData = formBindingData.createFormBindingData({
        'cardImage': card.image,
        'cardName': card.name,
        'cardDesc': card.meaning,
        'goldQuote': this.goldQuote,
        'dailyTask': this.dailyTask,
        'moodNote': this.moodNote,
        'privacyMode': this.privacyMode
      });
      void (async () => {
        const ids = await this.manager.getFormIds();
        for (const id of ids) {
          try { await formProvider.updateForm(id, formData); } catch (e) { const _err = e as Error | object; }
        }
      })();
    } catch (err) {
      console.error('Form Update Error');
    }
  }

  handleManualReset() {
    this.resetUI();
    promptAction.showToast({ message: '🔄 已重置', duration: 1000 });
  }

  async handleDebugReset() {
    this.handleManualReset();
  }

  /**
   * 计算珍稀度等级与颜色
   */
  calculateRarity() {
    const rand = Math.random() * 100;
    if (rand < 0.001) { this.rarityLevel = 7; this.rarityColor = 'rgba(0,0,0,0.9)'; }
    else if (rand < 0.101) { this.rarityLevel = 6; this.rarityColor = 'rgba(255,0,0,0.85)'; }
    else if (rand < 1.101) { this.rarityLevel = 5; this.rarityColor = 'rgba(255,215,0,0.85)'; }
    else if (rand < 6.101) { this.rarityLevel = 4; this.rarityColor = 'rgba(128,0,128,0.7)'; }
    else if (rand < 16.101) { this.rarityLevel = 3; this.rarityColor = 'rgba(0,0,255,0.7)'; }
    else if (rand < 36.101) { this.rarityLevel = 2; this.rarityColor = 'rgba(0,128,0,0.7)'; }
    else { this.rarityLevel = 1; this.rarityColor = 'rgba(255,255,255,0.5)'; }
  }

  /**
   * 根据珍稀度返回翻牌动画时长（最高 3000ms）
   */
  getFlipDurationByRarity(): number {
    const map = [700, 900, 1100, 1400, 1800, 2200, 2600];
    const idx = Math.min(Math.max(this.rarityLevel, 1), 7) - 1;
    return map[idx];
  }

  /**
   * 根据珍稀度返回光晕半径
   */
  getGlowRadiusByRarity(): number {
    const map = [18, 20, 22, 24, 26, 28, 30];
    const idx = Math.min(Math.max(this.rarityLevel, 1), 7) - 1;
    return map[idx];
  }

  /**
   * 获取分享海报主文字颜色（根据主题）
   */
  getThemePrimaryTextColor(): string {
    return this.shareTheme === 'star' ? '#EEEEEE' : '#333333';
  }

  /**
   * 获取分享海报副文字颜色（根据主题）
   */
  getThemeSecondaryTextColor(): string {
    return this.shareTheme === 'star' ? '#BBBBBB' : '#888888';
  }

  /**
   * 打开呼吸引导底部弹窗（函数级注释）
   */
  openBreathingGuide() {
    this.isBreathingSheetOpen = true;
    this.startBreathingGuide(60);
  }

  /**
   * 启动呼吸引导计时与动画（函数级注释）
   */
  startBreathingGuide(seconds: number) {
    this.breathingRemaining = seconds;
    this.breathingPhase = '吸气';
    if (this.breathingTimerId) {
      clearInterval(this.breathingTimerId);
      this.breathingTimerId = null;
    }
    const t = setInterval(() => {
      if (this.breathingRemaining <= 0) {
        this.stopBreathingGuide();
        return;
      }
      const mod = this.breathingRemaining % 6;
      if (mod >= 4) {
        this.breathingPhase = '吸气';
        animateTo({ duration: 800, curve: Curve.EaseInOut }, () => { this.mysteryScale = 1.06; this.shadowRadius = 22; });
      } else if (mod >= 2) {
        this.breathingPhase = '停留';
        animateTo({ duration: 800, curve: Curve.Linear }, () => { this.mysteryScale = 1.06; });
      } else {
        this.breathingPhase = '呼气';
        animateTo({ duration: 800, curve: Curve.EaseInOut }, () => { this.mysteryScale = 1.0; this.shadowRadius = 18; });
      }
      this.breathingRemaining -= 1;
    }, 1000);
    this.breathingTimerId = t as number;
  }

  /**
   * 停止呼吸引导并复位（函数级注释）
   */
  stopBreathingGuide() {
    if (this.breathingTimerId) {
      clearInterval(this.breathingTimerId);
      this.breathingTimerId = null;
    }
    this.isBreathingSheetOpen = false;
    this.breathingPhase = '完成';
    animateTo({ duration: 300 }, () => { this.mysteryScale = 1; this.shadowRadius = 20; });
  }

  /**
   * 切换私密模式并持久化（函数级注释）
   */
  async togglePrivacyMode() {
    this.privacyMode = !this.privacyMode;
    await this.manager.setPrivacyMode(this.privacyMode);
    promptAction.showToast({ message: this.privacyMode ? '🔒 私密模式已开启' : '🔓 私密模式已关闭', duration: 1200 });
  }

  // --- 动画函数 ---
  startGuideAnimation() { animateTo({ duration: 1500, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate }, () => { this.guideOpacity = 0.3; }); }

  startMysteryAnimation() {
    animateTo({ duration: 2000, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate }, () => {
      this.mysteryScale = 1.05;
      this.shadowRadius = 20;
      this.shadowColor = 'rgba(100,0,200,0.3)';
    });
  }

  stopMysteryAnimation() {
    animateTo({ duration: 300 }, () => {
      this.mysteryScale = 1;
      this.shadowRadius = 10;
      this.shadowColor = 'rgba(0,0,0,0.15)';
    });
  }

  startBreathingAnimation() {
    animateTo({ duration: 2000, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate }, () => { this.floatOffsetY = -15; });
    animateTo({ duration: 3000, curve: Curve.Smooth, iterations: -1, playMode: PlayMode.Alternate }, () => { this.floatRotateZ = 2; });
  }

  stopBreathingAnimation() {
    animateTo({ duration: 0 }, () => { this.floatOffsetY = 0; this.floatRotateZ = 0; });
  }

  handleClickFeedback() { animateTo({ duration: 100, curve: Curve.EaseOut }, () => { this.clickScale = 0.95; }); setTimeout(() => { animateTo({ duration: 400, curve: curves.springMotion(0.5, 0.6) }, () => { this.clickScale = 1; }); }, 100); }

  // --- 🃏 核心：洗牌+抽牌动画 ---
  async handleDrawCard() {
    if (this.isFlipped) {
      if (this.currentCard) {
        promptAction.showToast({ message: '📅 每天只能抽取一次哦', duration: 2000 });
        this.handleClickFeedback();
        return;
      }
    }

    this.guideOpacity = 0;
    this.stopMysteryAnimation();

    // 1. 展开三层牌堆
    await this.asyncAnimateTo(300, Curve.EaseOut, () => {
      this.mainScale = 0.9;
      this.shadowRadius = 5;
      this.shadowOffsetY = 2;
      this.deckOpacity = 1;
      this.deckOffset1 = -40;
      this.deckOffset2 = 40;
    });

    // 2. 左右交替洗牌（柔和物理效果）
    for (let i = 0; i < 5; i++) {
      const dir = i % 2 === 0 ? 1 : -1;
      await this.asyncAnimateTo(150, Curve.Sharp, () => {
        this.shuffleOffsetX = 60 * dir;
        this.shuffleRotate = 6 * dir;
        this.deckOffset1 = -60 * dir;
        this.deckOffset2 = -20 * dir;
      });
      await this.asyncAnimateTo(150, Curve.Sharp, () => {
        this.shuffleOffsetX = 0;
        this.shuffleRotate = 0;
        this.deckOffset1 = -40;
        this.deckOffset2 = 40;
      });
    }

    // 3. 抽牌
    this.currentCard = await this.manager.drawDailyCard();
    this.calculateRarity();

    // 自动保存到展览厅
    if (this.currentCard) {
      await this.manager.saveDrawResult(this.currentCard, this.rarityColor);
    }

    await this.asyncAnimateTo(500, curves.springMotion(0.6, 0.7), () => {
      this.mainScale = 1.05;
      this.floatOffsetY = 0;
      this.shuffleOffsetX = 0;
      this.shuffleRotate = 0;

      this.shadowColor = 'rgba(0,0,0,0.15)';
      this.shadowRadius = 20;
      this.shadowOffsetY = 10;
      this.deckOpacity = 0;
      this.deckOffset1 = -300;
      this.deckOffset2 = 300;
    });

    // 4. 单段翻转，保持卡片始终居中，光晕在翻面完成后渐显
    await this.asyncAnimateTo(this.getFlipDurationByRarity(), curves.springMotion(0.6, 0.8), () => {
      this.angle = 180;
      this.mainScale = 1.0;
      this.floatOffsetY = 0;
      this.shadowRadius = 20;
      this.shadowOffsetY = 10;
    });
    // 翻面完成后渐显珍稀度光晕
    await this.asyncAnimateTo(300, Curve.EaseOut, () => {
      this.shadowColor = this.rarityColor;
      this.shadowRadius = this.getGlowRadiusByRarity();
      this.shadowOffsetY = 0;
    });

    // 5. 收尾
    this.isFlipped = true;
    this.startBreathingAnimation();
    if (this.currentCard) {
      this.goldQuote = this.manager.createGoldQuote(this.currentCard);
      this.dailyTask = this.manager.createDailyTask(this.currentCard);
      await this.manager.setTodayAffirmations(this.goldQuote, this.dailyTask);
    }
    animateTo({ duration: 600 }, () => { this.showResultText = true; });
    if (this.currentCard) { this.updateForm(this.currentCard); }
  }

  /**
   * 打开分享弹窗，若状态异常先重置再打开
   */
  handleShare() {
    if (!this.currentCard) return;
    // 先强制关闭再打开，避免状态残留
    this.isShareSheetOpen = false;
    this.isGallerySheetOpen = false;
    this.isPosterReady = false;
    setTimeout(() => { this.isShareSheetOpen = true; }, 60);
    setTimeout(() => { this.isPosterReady = true; }, 140);
  }
  /**
   * 系统分享：先生成海报再调起系统分享
   */
  async handleSystemShare() {
    try {
      promptAction.showToast({ message: '正在生成分享卡片...', duration: 1000 });
      // 1. 生成海报截图
      const pixelMap = await componentSnapshot.get(this.POSTER_ID);
      // 2. 保存到沙箱（Cache）
      const fileName = `tarot_share_${new Date().getTime()}.jpg`;
      const filePath = `${this.context.cacheDir}/${fileName}`;
      const imagePacker = image.createImagePacker();
      const packOpts: image.PackingOption = { format: 'image/jpeg', quality: 90 };
      const data = await imagePacker.packing(pixelMap, packOpts);
      const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, data);
      fs.closeSync(file);
      // 3. 调起系统分享
      const utdTypeId = utd.getUniformDataTypeByFilenameExtension('.jpg', utd.UniformDataType.IMAGE);
      const shareData = new systemShare.SharedData({
        utd: utdTypeId,
        uri: fileUri.getUriFromPath(filePath),
        title: '治愈之书 · 今日指引',
        description: '快来看看我的塔罗牌运势吧！',
        thumbnail: new Uint8Array(data)
      });
      const controller = new systemShare.ShareController(shareData);
      await controller.show(this.context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DEFAULT
      });
    } catch (err) {
      console.error('handleSystemShare error:', err);
      promptAction.showToast({ message: '分享失败，请重试', duration: 2000 });
    }
  }
  async executeSave() {
    try {
      // 申请相册读写权限
      const ok = await this.ensureAlbumPermissions();
      if (!ok) {
        promptAction.showToast({ message: '需要相册权限，模拟器可能不支持，请在真机保存', duration: 2500 });
        return;
      }
      const pixelMap = await componentSnapshot.get(this.POSTER_ID);
      await ImageSaver.saveToAlbum(this.context, pixelMap);
      this.isShareSheetOpen = false;
    } catch (err) { promptAction.showToast({ message: '生成图片失败', duration: 2000 }); }
  }

  /**
   * 申请相册读写权限（READ/WRITE_IMAGEVIDEO），返回是否已授权
   */
  /**
   * 申请相册读写权限（READ/WRITE_IMAGEVIDEO），返回是否已授权
   */
  async ensureAlbumPermissions(): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(this.context, [
        'ohos.permission.READ_IMAGEVIDEO',
        'ohos.permission.WRITE_IMAGEVIDEO'
      ]);
      const ok = Array.isArray(result.authResults) ? result.authResults.every((v: number) => v === 0) : true;
      return ok;
    } catch {
      // 模拟器或未声明权限场景下，直接返回未授权以便业务降级
      promptAction.showToast({ message: '权限申请失败（模拟器或环境限制）', duration: 2000 });
      return false;
    }
  }
  /**
   * 选择并保存今日心情（函数级注释）
   */
  async setMood(index: number) {
    this.moodIndex = index;
    await this.manager.setTodayMood(index, this.moodNote);
    promptAction.showToast({ message: '🫶 心情已记录', duration: 1200 });
    const streak = await this.manager.getMoodStreak();
    const label = this.manager.getAchievementLabelByStreak(streak);
    if (label) {
      AlertDialog.show({
        title: '🎖️ 情绪成就',
        message: `${label}\n继续保持这份温柔的自我照顾。`
      });
    }
  }

  handleEnterSpread() { router.pushUrl({ url: 'pages/SpreadPage' }); }
  async handleBuyVip() {
    AlertDialog.show({
      title: '✨ 解锁深度疗愈',
      message: '解锁「时光流·三牌阵」与 AI 深度分析功能。\n\n价格：¥29.00',
      secondaryButton: {
        value: '解锁', fontColor: '#FF69B4',
        action: async () => { await this.manager.setVipStatus(true); this.isVip = true; promptAction.showToast({ message: '🎉 解锁成功！' }); }
      }
    });
  }

  async loadGalleryData() {
    this.isShareSheetOpen = false;
    // 获取图鉴数据
    this.galleryList = await this.manager.getGallery();
    this.collectionProgress = Math.round((this.galleryList.length / TAROT_DECK.length) * 100);
    this.isGallerySheetOpen = true;
  }

  /**
   * 分享面板：固定高度海报容器，避免首次布局 Decor 高度为 0
   */
  @Builder ShareSheetBuilder() {
    if (!this.currentCard) {
      Column() {
        Row().width(40).height(5).backgroundColor('#E0E0E0').borderRadius(10).margin({ top: 10, bottom: 20 })
        Column() { Text("正在生成海报...").margin(20) }
          .width('92%').constraintSize({ maxWidth: 420 }).backgroundColor(Color.White).borderRadius(16)
          .shadow({ radius: 10, color: 'rgba(0,0,0,0.06)', offsetY: 4 })
          .height(160)
      }
      .alignItems(HorizontalAlign.Center)
    }
    else {
      Column() {
        Row().width(40).height(5).backgroundColor('#E0E0E0').borderRadius(10).margin({ top: 10, bottom: 12 })

        // P1：主题切换与贴纸选择
        Row({ space: 8 }) {
          Button({ type: ButtonType.Capsule, stateEffect: true }) { Text('轻柔') }
            .backgroundColor(this.shareTheme === 'soft' ? '#333333' : '#EEEEEE').fontColor(this.shareTheme === 'soft' ? Color.White : Color.Black)
            .onClick(() => { this.shareTheme = 'soft'; })
          Button({ type: ButtonType.Capsule, stateEffect: true }) { Text('极简') }
            .backgroundColor(this.shareTheme === 'minimal' ? '#333333' : '#EEEEEE').fontColor(this.shareTheme === 'minimal' ? Color.White : Color.Black)
            .onClick(() => { this.shareTheme = 'minimal'; })
          Button({ type: ButtonType.Capsule, stateEffect: true }) { Text('星空') }
            .backgroundColor(this.shareTheme === 'star' ? '#333333' : '#EEEEEE').fontColor(this.shareTheme === 'star' ? Color.White : Color.Black)
            .onClick(() => { this.shareTheme = 'star'; })
        }.width('92%').constraintSize({ maxWidth: 420 }).justifyContent(FlexAlign.SpaceEvenly)

        Row({ space: 6 }) {
          ForEach(['✨','💫','🌙','🌟','🪽'], (emo: string) => {
            Button(emo).height(32).borderRadius(16).backgroundColor('#F0F0F0')
              .onClick(() => {
                const idx = this.stickers.indexOf(emo);
                if (idx >= 0) { this.stickers.splice(idx, 1); } else { this.stickers.push(emo); }
              })
          })
        }.width('92%').constraintSize({ maxWidth: 420 }).justifyContent(FlexAlign.Center).margin({ bottom: 8 })

        Column() {
          Row() {
            Column() {
              Text(this.todayDate).fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.getThemePrimaryTextColor())
              Text(this.todayWeek).fontSize(14).fontColor(this.getThemeSecondaryTextColor()).margin({ top: 2 })
            }.alignItems(HorizontalAlign.Start)
            Blank()
            Text("治愈之书").fontSize(16).fontColor('#FF69B4').fontWeight(FontWeight.Medium)
          }.width('100%').padding({ left: 16, right: 16, top: 12 })

          Image($rawfile(this.currentCard.image))
            .width('100%').aspectRatio(2/3).borderRadius(12)
            .shadow({ radius: 20, color: 'rgba(0,0,0,0.1)', offsetY: 10 })

          Row({ space: 6 }) {
            ForEach(this.stickers, (emo: string) => {
              Text(emo).fontSize(18)
            })
          }.width('100%').padding({ left: 16, right: 16, top: 8 })

          Column() {
            Text(this.currentCard.name).fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.getThemePrimaryTextColor()).margin({ bottom: 6 })
            Text(this.currentCard.meaning).fontSize(13).fontColor(this.getThemeSecondaryTextColor()).margin({ bottom: 10 })
            Text(this.currentCard.desc).fontSize(14).fontColor(this.shareTheme === 'star' ? '#DDDDDD' : '#555555').textAlign(TextAlign.Center).lineHeight(22).padding({ left: 18, right: 18 })
          }.padding({ top: 12, bottom: 12 })

          if (!this.privacyMode && (this.moodNote || this.goldQuote || this.dailyTask)) {
            Column({ space: 6 }) {
              if (this.moodNote) {
                Text("今日心情摘记").fontSize(12).fontColor(this.getThemeSecondaryTextColor())
                Text(this.moodNote).fontSize(13).fontColor(this.getThemePrimaryTextColor()).textAlign(TextAlign.Center)
              }
              if (this.goldQuote) {
                Text("治愈金句").fontSize(12).fontColor(this.getThemeSecondaryTextColor())
                Text(this.goldQuote).fontSize(13).fontColor(this.getThemePrimaryTextColor()).textAlign(TextAlign.Center)
              }
              if (this.dailyTask) {
                Text("今日小任务").fontSize(12).fontColor(this.getThemeSecondaryTextColor())
                Text(this.dailyTask).fontSize(13).fontColor(this.getThemePrimaryTextColor()).textAlign(TextAlign.Center)
              }
            }.width('100%').padding({ left: 18, right: 18, top: 8 })
          }
          if (this.privacyMode) {
            Row() {
              Text("私密模式已开启，海报仅展示卡面与标题").fontSize(12).fontColor(this.getThemeSecondaryTextColor())
            }.width('100%').padding({ left: 18, right: 18, top: 8 })
          }

          Row() {
            Text("保存图片后可分享给好友").fontSize(12).fontColor('#CCCCCC')
          }.width('100%').padding({ left: 18, right: 18, top: 8, bottom: 76 })
        }
        .width('92%').constraintSize({ maxWidth: 420 }).backgroundColor(this.shareTheme === 'soft' ? Color.White : (this.shareTheme === 'minimal' ? '#F7F7F7' : '#0B1623')).borderRadius(16)
        .shadow({ radius: 30, color: 'rgba(0,0,0,0.1)', offsetY: 10 })
        .id(this.POSTER_ID)
      }
      .alignItems(HorizontalAlign.Center)
    }
  }

  // 🏛️ 展览厅面板
  @Builder GallerySheetBuilder() {
    Column() {
      Row().width(40).height(5).backgroundColor('#E0E0E0').borderRadius(10).margin({ top: 10, bottom: 20 })
      Row() {
        Text("🏛️ 治愈展览厅").fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333333')
        Blank()
        Text(`已收集: ${this.galleryList.length} / ${TAROT_DECK.length}`).fontSize(14).fontColor('#999999')
      }.width('100%').padding({ left: 20, right: 20 }).margin({ bottom: 10 })
      Progress({ value: this.collectionProgress, total: 100, type: ProgressType.Linear }).color('#FF69B4').width('90%').height(10).margin({ bottom: 20 })

      Grid() {
        ForEach(TAROT_DECK, (card: TarotCard) => {
          GridItem() {
            Column() {
              if (this.isCollected(card.id)) {
                Stack() {
                  Image($rawfile(card.image)).width('100%').aspectRatio(2/3).borderRadius(8)
                    .shadow({ radius: 16, color: this.getCardRarityColor(card.id), offsetY: 0 })
                  Row() {
                    Text(this.getCardMoodEmoji(card.id)).fontSize(12).fontColor('#FFFFFF')
                      .backgroundColor('rgba(0,0,0,0.35)').borderRadius(10).padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  }.padding(6)
                  .width('100%').justifyContent(FlexAlign.Start)
                }.width('100%').aspectRatio(2/3)
                Text(card.name).fontSize(12).fontColor('#333333').margin({ top: 5 })
              } else {
                Stack() {
                  Rect().width('100%').height('100%').fill('#F0F0F0').borderRadius(8)
                  Text("?").fontSize(24).fontColor('#DDDDDD').fontWeight(FontWeight.Bold)
                }.width('100%').aspectRatio(2/3)
                Text("???").fontSize(12).fontColor('#CCCCCC').margin({ top: 5 })
              }
            }
          }
        })
      }.columnsTemplate('1fr 1fr 1fr').columnsGap(10).rowsGap(15).width('100%').layoutWeight(1).padding(20)
    }.width('100%').height('85%').backgroundColor(Color.White).borderRadius({ topLeft: 20, topRight: 20 })
  }

  isCollected(id: number): boolean { return this.galleryList.some(record => record.cardId === id); }
  getCardRarityColor(id: number): string { const record = this.galleryList.find(r => r.cardId === id); return record ? record.rarityColor : 'rgba(0,0,0,0.1)'; }

  /**
   * 获取卡片对应的心情角标 Emoji（函数级注释）
   */
  getCardMoodEmoji(id: number): string {
    const record = this.galleryList.find(r => r.cardId === id);
    const idx = record && typeof record.moodIndex === 'number' ? (record.moodIndex as number) : -1;
    const map = ['😭','😕','🙂','😊','🥳'];
    return idx >= 0 && idx < map.length ? map[idx] : '';
  }

  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor('#FAFAFA')
        // 兼容不同版本的安全区写法
        .padding({ top: 12, bottom: 12 })

      if (this.activeTab === 0) {
      Scroll() {
        Column() {
          // 顶部导航
          Stack({ alignContent: Alignment.Start }) {
            if (this.isFlipped) {
              Button({ type: ButtonType.Circle, stateEffect: true }) {
                Text('❮').fontSize(18).fontColor('#666666').fontWeight(FontWeight.Bold)
              }.width(40).height(40).backgroundColor('rgba(0,0,0,0.05)').margin({ left: 20 }).onClick(() => this.handleManualReset()).zIndex(10)
            }
            // 展览厅入口
            Stack({ alignContent: Alignment.End }) {
              Button({ type: ButtonType.Circle, stateEffect: true }) {
                Text('🏛️').fontSize(18)
              }.width(40).height(40).backgroundColor('rgba(0,0,0,0.05)').margin({ right: 20 })
              .onClick(() => this.loadGalleryData())
            }.width('100%')
          }
          .height(50).width('100%').margin({ top: 10, bottom: 5 })

          Blank().height(40)

          // --- 3D 卡牌容器 ---
          Stack() {
            Image($rawfile('card_back.png'))
              .width('100%').height('100%').borderRadius(16)
              .border({ width: 1, color: 'rgba(255,255,255,0.3)' })
              .scale({ x: this.deckScale, y: this.deckScale })
              .translate({ x: this.deckOffset1, y: 0 })
              .rotate({ z: 1, angle: this.deckAngle1 })
              .opacity(this.deckOpacity)
              .shadow({ radius: 5, color: 'rgba(0,0,0,0.2)', offsetY: 2 })
              .zIndex(0)

            Image($rawfile('card_back.png'))
              .width('100%').height('100%').borderRadius(16)
              .border({ width: 1, color: 'rgba(255,255,255,0.3)' })
              .scale({ x: this.deckScale, y: this.deckScale })
              .translate({ x: this.deckOffset2, y: 0 })
              .rotate({ z: 1, angle: this.deckAngle2 })
              .opacity(this.deckOpacity)
              .shadow({ radius: 5, color: 'rgba(0,0,0,0.2)', offsetY: 2 })
              .zIndex(0)

            Stack() {
              Image($rawfile('card_back.png')).width('100%').height('100%').borderRadius(16)
                .rotate({ x: 0, y: 1, z: 0, angle: this.angle }).opacity(this.angle < 90 ? 1 : 0)

            if (this.currentCard) {
              Image($rawfile(this.currentCard.image)).width('100%').height('100%').borderRadius(16)
                .rotate({ x: 0, y: 1, z: 0, angle: this.angle - 180 }).opacity(this.angle >= 90 ? 1 : 0)
            }
            }
            .zIndex(10)
            .width('100%').height('100%')
          }
          .width('75%').aspectRatio(2/3).margin({ top: 20, bottom: 20 })

          // 绑定所有复合动画
          .rotate({ z: 1, angle: this.mainRotateZ + this.shuffleRotate })
          .translate({ x: this.shuffleOffsetX, y: this.floatOffsetY + this.mainOffsetY })
          .scale({
            x: this.shuffleScale * this.clickScale * this.mysteryScale,
            y: this.shuffleScale * this.clickScale * this.mysteryScale
          })
          // ✨ 绑定光影 ✨
          .shadow({ radius: this.shadowRadius, color: this.shadowColor, offsetY: this.shadowOffsetY })
          .onClick(() => { this.handleDrawCard(); })

          if (!this.isFlipped) {
            // 文字已隐藏
          }

          if (this.showResultText && this.currentCard) {
            Column() {
              Column({ space: 8 }) {
                Text(this.currentCard.name + " · " + this.currentCard.name_en).fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333333')
                Text(this.currentCard.meaning).fontSize(14).fontColor('#888888').margin({ bottom: 15 })
                Text(this.currentCard.desc).fontSize(16).fontColor('#555555').textAlign(TextAlign.Center).lineHeight(26).padding({ left: 15, right: 15 }).opacity(0.9)
              }.padding({ top: 20, bottom: 20 })

          Row({ space: 15 }) {
            Button("分享日签").backgroundColor('#F0F0F0').fontColor('#333333').width('45%').height(45).borderRadius(22).onClick(() => this.handleShare())
            if (!this.isVip) {
              Button("深度解读 (¥29)").backgroundColor('#FFB6C1').fontColor(Color.White).width('45%').height(45).borderRadius(22).onClick(() => this.handleBuyVip())
            } else {
              Button("进入三牌阵").backgroundColor('#87CEEB').fontColor(Color.White).width('45%').height(45).borderRadius(22).onClick(() => router.pushUrl({ url: 'pages/SpreadPage' }))
            }
          }.width('90%').margin({ top: 20, bottom: 12 }).justifyContent(FlexAlign.Center)

          // P0：情绪签到与金句/小任务
          Column({ space: 10 }) {
                Row({ space: 8 }) {
                  ForEach([0,1,2,3,4], (i: number) => {
                    Button(['😭','😕','🙂','😊','🥳'][i]).height(36).borderRadius(18)
                      .backgroundColor(this.moodIndex === i ? '#333333' : '#EEEEEE')
                      .fontColor(this.moodIndex === i ? Color.White : Color.Black)
                      .onClick(() => this.setMood(i))
                  })
                }.width('90%').justifyContent(FlexAlign.Center)
                Row() {
                  TextInput({ text: this.moodNote, placeholder: '写一句今天的心情...' })
                    .layoutWeight(1).height(36).backgroundColor('#F9F9F9').borderRadius(18)
                    .padding({ left: 12 }).onChange((v) => { this.moodNote = v; })
                  Button("记录").width(70).height(36).backgroundColor('#333333').fontColor(Color.White)
                    .borderRadius(18).margin({ left: 8 }).onClick(() => this.setMood(this.moodIndex >= 0 ? this.moodIndex : 2))
                }.width('90%')
                Column() {
                  Text(this.goldQuote).fontSize(14).fontColor('#666666').textAlign(TextAlign.Center)
              Text(this.dailyTask).fontSize(13).fontColor('#999999').textAlign(TextAlign.Center).margin({ top: 4 })
            }.width('90%')
            Row({ space: 12 }) {
              Button("呼吸引导 60s").backgroundColor('#E6F2FF').fontColor('#1A73E8').height(40).borderRadius(20)
                .onClick(() => this.openBreathingGuide())
              Button(this.privacyMode ? '关闭私密' : '开启私密').backgroundColor('#F0F0F0').fontColor('#333333').height(40).borderRadius(20)
                .onClick(() => this.togglePrivacyMode())
            }.width('90%').justifyContent(FlexAlign.Center).margin({ top: 6 })
          }.alignItems(HorizontalAlign.Center)
          .transition({ type: TransitionType.Insert, opacity: 0, translate: { y: 20 } })
            }
            .width('90%').backgroundColor(Color.White).borderRadius(16)
            // 解读卡片的普通阴影
            .shadow({ radius: 10, color: 'rgba(0,0,0,0.1)', offsetY: 5 })
            .margin({ top: 20, bottom: 40 })
            .transition({ type: TransitionType.Insert, opacity: 0, translate: { y: 30 } })
          }
        }
        .width('100%').padding({ bottom: 100 })
      }
      .width('100%').layoutWeight(1).align(Alignment.Top)
      } 

      if (this.activeTab === 0 && this.isShareSheetOpen) {
        Stack({ alignContent: Alignment.Bottom }) {
          Column().width('100%').height('100%')
            .backgroundColor('rgba(0,0,0,0.35)')
            .onClick(() => { this.isShareSheetOpen = false; })

          Column() {
            Row().width(40).height(5).backgroundColor('#E0E0E0').borderRadius(10).margin({ top: 10, bottom: 12 })
            Scroll() {
              Column() { this.ShareSheetBuilder() }
                .width('100%').alignItems(HorizontalAlign.Center)
            }
            .layoutWeight(1).scrollBar(BarState.Off)

            Row({ space: 12 }) {
              Button({ type: ButtonType.Capsule, stateEffect: true }) { Text('保存到相册').fontColor(Color.Black) }
                .backgroundColor('#EEEEEE').layoutWeight(1).height(48)
                .onClick(async () => { await this.executeSave(); })

              Button({ type: ButtonType.Capsule, stateEffect: true }) { Text('分享给好友').fontColor(Color.White) }
                .backgroundColor('#333333').layoutWeight(1).height(48)
                .onClick(() => this.handleSystemShare())
                .shadow({ radius: 10, color: 'rgba(0,0,0,0.3)', offsetY: 5 })
            }
            .width('92%').constraintSize({ maxWidth: 420 }).margin({ top: 12, bottom: 24 })
          }
          .width('100%').height(600).backgroundColor('#F5F5F5').borderRadius({ topLeft: 20, topRight: 20 })
        }
        .width('100%').height('100%').zIndex(99)
      }

      if (this.activeTab === 0 && this.isBreathingSheetOpen) {
        Stack({ alignContent: Alignment.Bottom }) {
          Column().width('100%').height('100%')
            .backgroundColor('rgba(0,0,0,0.35)')
            .onClick(() => { this.stopBreathingGuide(); })

          Column() {
            Row().width(40).height(5).backgroundColor('#E0E0E0').borderRadius(10).margin({ top: 10, bottom: 12 })
            Column({ space: 10 }) {
              Text('呼吸引导').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333333')
              Text(`阶段：${this.breathingPhase} · 剩余 ${this.breathingRemaining}s`).fontSize(14).fontColor('#666666')
              Progress({ value: 60 - this.breathingRemaining, total: 60, type: ProgressType.Linear }).width('90%')
              Row({ space: 12 }) {
                Button('结束').backgroundColor('#F0F0F0').fontColor('#333333').height(40).borderRadius(20).onClick(() => this.stopBreathingGuide())
              }.justifyContent(FlexAlign.Center)
            }.width('100%').alignItems(HorizontalAlign.Center)
          }
          .width('100%').height(220).backgroundColor('#FFFFFF').borderRadius({ topLeft: 20, topRight: 20 })
        }
        .width('100%').height('100%').zIndex(98)
      }
      
      Stack({ alignContent: Alignment.Bottom }) {
        BottomNavBar({ current: 'index' }).width('100%')
      }
      .width('100%').height('100%').zIndex(5)
    }
    .bindSheet($$this.isGallerySheetOpen, this.GallerySheetBuilder(), {
      height: SheetSize.LARGE, backgroundColor: Color.Transparent, blurStyle: BlurStyle.Thin, showClose: true
    })
  }
}
