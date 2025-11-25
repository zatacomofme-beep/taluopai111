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
import { EnergyManager } from '../common/EnergyManager';
import { ShareHelper } from '../common/ShareHelper';
import { CloudService } from '../common/CloudService';
import { UserManager, UserInfo } from '../common/UserManager'; // 确保 UserManager.ets 文件存在
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  // === 核心数据 ===
  @State currentCard: TarotCard | null = null;
  @State isFlipped: boolean = false;
  @State showResultText: boolean = false;
  @State isVip: boolean = false;

  // === 🌈 珍稀度系统 ===
  @State rarityColor: string = 'rgba(0,0,0,0.15)';
  @State rarityLevel: number = 1;

  // === 🎬 动画状态 ===
  @State angle: number = 0;
  @State floatOffsetY: number = 0;
  @State floatRotateZ: number = 0;
  @State clickScale: number = 1;
  @State mysteryScale: number = 1;

  // 光影特效
  @State shadowOpacity: number = 0.15;
  @State shadowRadius: number = 10;
  @State shadowOffsetY: number = 5;
  @State shadowColor: string = 'rgba(0,0,0,0.2)';
  @State guideOpacity: number = 1;

  // 洗牌动画
  @State shuffleOffsetX: number = 0;
  @State shuffleRotate: number = 0;
  @State shuffleScale: number = 1;
  @State mainScale: number = 1;
  @State mainOffsetY: number = 0;
  @State mainRotateZ: number = 0;

  // 装饰性牌堆
  @State deckOffset1: number = 0;
  @State deckOffset2: number = 0;
  @State deckOpacity: number = 0;
  @State deckScale: number = 0.9;
  @State deckAngle1: number = -5;
  @State deckAngle2: number = 5;

  // === 🌈 特效变量 ===
  @State glowScale: number = 1;
  @State glowOpacity: number = 0;
  @State starScale: number = 0;

  // === 🏛️ 弹窗状态控制 ===
  @State isGallerySheetOpen: boolean = false;
  @State isEnergySheetOpen: boolean = false;
  @State isShareSheetOpen: boolean = false;

  // === 数据 ===
  @State galleryList: CardRecord[] = [];
  @State collectionProgress: number = 0;
  @State isPosterReady: boolean = false;
  @State shareTheme: string = 'soft';
  @State stickers: string[] = [];
  @State todayDate: string = "";
  @State todayWeek: string = "";

  // === P0：情绪与任务 ===
  @State moodIndex: number = -1;
  @State moodNote: string = '';
  @State goldQuote: string = '';
  @State dailyTask: string = '';

  // === P2/P4：呼吸与私密 ===
  @State isBreathingSheetOpen: boolean = false;
  @State breathingPhase: string = '准备';
  @State breathingRemaining: number = 60;
  @State privacyMode: boolean = false;

  // === ⚡ 能量显示与充值 ===
  @State currentEnergy: number = 0;

  // === 👤 用户信息 ===
  @State currentUserInfo: UserInfo | null = null; // 👈 新增：存储当前用户信息

  private manager = FortuneManager.getInstance();
  private energyManager = EnergyManager.getInstance();
  private userManager = UserManager.getInstance();
  private context = getContext(this) as common.UIAbilityContext;
  private POSTER_ID = 'poster_component_id';

  private asyncAnimateTo(duration: number, curve: Curve | string | ICurve, updateFn: () => void): Promise<void> {
    return new Promise((resolve) => {
      animateTo({ duration: duration, curve: curve, onFinish: resolve }, updateFn);
    });
  }

  async aboutToAppear() {
    await this.manager.init(this.context);
    await this.energyManager.init(this.context);
    this.refreshEnergy();

    this.checkState();
    this.initDate();
    this.startGuideAnimation();

    // 获取今日心情数据
    const mood = await this.manager.getTodayMood();
    this.moodIndex = mood.mood;
    this.moodNote = mood.note;

    const aff = await this.manager.getTodayAffirmations();
    this.goldQuote = aff.quote;
    this.dailyTask = aff.task;
    this.privacyMode = await this.manager.isPrivacyMode();

    // 👈 新增：初始化时检查登录状态
    this.refreshLoginStatus();
  }

  onPageShow() {
    this.refreshEnergy();
    void (async () => {
      const mood = await this.manager.getTodayMood();
      this.moodIndex = mood.mood;
    })();
    // 👈 每次页面显示也刷新登录状态
    this.refreshLoginStatus();
  }

  refreshEnergy() {
    this.currentEnergy = this.energyManager.getEnergy();
  }

  // 👈 新增：刷新登录状态方法
  refreshLoginStatus() {
    this.currentUserInfo = this.userManager.getCurrentUser();
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
      this.rarityColor = 'rgba(255, 182, 193, 0.5)';
      this.shadowColor = this.rarityColor;
      this.shadowRadius = 20;
      this.updateForm(savedCard);
    } else {
      this.resetUI();
    }
  }

  resetUI() {
    this.currentCard = null;
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
          try {
            await formProvider.updateForm(id, formData);
          } catch (e) {
            const _err = e as BusinessError;
            console.error(`Form update failed: ${_err.message}`);
          }
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

  handleBuyVip() {
    animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
      this.isEnergySheetOpen = true;
    });
  }

  async handleRecharge(amount: number) {
    await this.energyManager.recharge(amount);
    this.refreshEnergy();
    promptAction.showToast({ message: `⚡ 成功补充 ${amount} 点心力！` });
    animateTo({ duration: 300 }, () => {
      this.isEnergySheetOpen = false;
    });
  }

  calculateRarity() {
    const rand = Math.random() * 100;
    if (rand < 0.1) { this.rarityLevel = 7; this.rarityColor = 'rgba(255, 215, 0, 0.9)'; }
    else if (rand < 1.1) { this.rarityLevel = 6; this.rarityColor = 'rgba(255, 69, 0, 0.8)'; }
    else if (rand < 6.1) { this.rarityLevel = 5; this.rarityColor = 'rgba(138, 43, 226, 0.7)'; }
    else if (rand < 16.1) { this.rarityLevel = 4; this.rarityColor = 'rgba(30, 144, 255, 0.7)'; }
    else if (rand < 36.1) { this.rarityLevel = 3; this.rarityColor = 'rgba(60, 179, 113, 0.6)'; }
    else { this.rarityLevel = 1; this.rarityColor = 'rgba(200, 200, 200, 0.5)'; }
  }

  getFlipDurationByRarity(): number {
    const map = [800, 900, 1000, 1200, 1500, 1800, 2000];
    const idx = Math.min(Math.max(this.rarityLevel, 1), 7) - 1;
    return map[idx];
  }

  getGlowRadiusByRarity(): number {
    const map = [15, 18, 20, 25, 30, 35, 40];
    const idx = Math.min(Math.max(this.rarityLevel, 1), 7) - 1;
    return map[idx];
  }

  startGuideAnimation() { animateTo({ duration: 1500, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate }, () => { this.guideOpacity = 0.3; }); }

  startMysteryAnimation() {
    animateTo({ duration: 2000, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate }, () => {
      this.mysteryScale = 1.05;
      this.shadowRadius = 20;
      this.shadowColor = 'rgba(100,0,200,0.3)';
    });
  }
  stopMysteryAnimation() { animateTo({ duration: 300 }, () => { this.mysteryScale = 1; this.shadowRadius = 10; this.shadowColor = 'rgba(0,0,0,0.15)'; }); }

  startBreathingAnimation() {
    animateTo({ duration: 2500, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate }, () => { this.floatOffsetY = -12; });
    animateTo({ duration: 3500, curve: Curve.Smooth, iterations: -1, playMode: PlayMode.Alternate }, () => { this.floatRotateZ = 1.5; });
  }
  stopBreathingAnimation() { animateTo({ duration: 0 }, () => { this.floatOffsetY = 0; this.floatRotateZ = 0; }); }

  handleClickFeedback() { animateTo({ duration: 100, curve: Curve.EaseOut }, () => { this.clickScale = 0.95; }); setTimeout(() => { animateTo({ duration: 400, curve: curves.springMotion(0.5, 0.6) }, () => { this.clickScale = 1; }); }, 100); }

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

    await this.asyncAnimateTo(300, Curve.EaseOut, () => {
      this.mainScale = 0.9;
      this.shadowRadius = 5;
      this.shadowOffsetY = 2;
      this.deckOpacity = 1;
      this.deckOffset1 = -40;
      this.deckOffset2 = 40;
    });

    for (let i = 0; i < 3; i++) {
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

    this.currentCard = await this.manager.drawDailyCard();
    this.calculateRarity();

    if (this.currentCard) {
      await this.manager.saveDrawResult(this.currentCard, this.rarityColor);
    }

    await this.asyncAnimateTo(500, curves.springMotion(0.6, 0.7), () => {
      this.mainScale = 1.05;
      this.floatOffsetY = 0;
      this.shuffleOffsetX = 0;
      this.shuffleRotate = 0;
      this.shadowColor = 'rgba(0,0,0,0.15)';
      this.deckOpacity = 0;
      this.deckOffset1 = -300;
      this.deckOffset2 = 300;
    });

    const flipDuration = this.getFlipDurationByRarity();

    if (this.rarityLevel >= 5) {
      setTimeout(() => {
        this.glowScale = 0.8;
        this.glowOpacity = 1;
        animateTo({ duration: 800, curve: Curve.EaseOut }, () => {
          this.glowScale = 2.5;
          this.glowOpacity = 0;
        });
        this.starScale = 0;
        animateTo({ duration: 600, curve: curves.springMotion(0.6, 0.8) }, () => {
          this.starScale = 1.2;
        });
      }, flipDuration / 3);
    }

    await this.asyncAnimateTo(flipDuration, curves.springMotion(0.6, 0.8), () => {
      this.angle = 180;
      this.mainScale = 1.0;
      this.floatOffsetY = 0;
      this.shadowRadius = 20;
      this.shadowOffsetY = 10;
    });

    await this.asyncAnimateTo(500, Curve.EaseOut, () => {
      this.shadowColor = this.rarityColor;
      this.shadowRadius = this.getGlowRadiusByRarity();
      this.shadowOffsetY = 0;
    });

    this.isFlipped = true;
    this.startBreathingAnimation();

    if (this.currentCard) {
      this.goldQuote = this.manager.createGoldQuote(this.currentCard);
      this.dailyTask = this.manager.createDailyTask(this.currentCard);
      await this.manager.setTodayAffirmations(this.goldQuote, this.dailyTask);
      this.updateForm(this.currentCard);
    }

    animateTo({ duration: 600 }, () => { this.showResultText = true; });
  }

  handleShare() {
    if (!this.currentCard) return;
    this.isShareSheetOpen = false;
    this.isGallerySheetOpen = false;
    this.isPosterReady = false;
    animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
      this.isShareSheetOpen = true;
    });
    setTimeout(() => { this.isPosterReady = true; }, 140);
  }

  async handleSystemShare() {
    try {
      promptAction.showToast({ message: '正在生成...', duration: 1000 });
      await ShareHelper.snapshotAndShare(this.context, this.POSTER_ID);
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Share failed: ${error.message}`);
      promptAction.showToast({ message: '分享失败，请重试', duration: 2000 });
    }
  }

  async executeSave() {
    try {
      const ok = await this.ensureAlbumPermissions();
      if (!ok) { promptAction.showToast({ message: '需要相册权限', duration: 2500 }); return; }
      const pixelMap = await componentSnapshot.get(this.POSTER_ID);
      await ImageSaver.saveToAlbum(this.context, pixelMap);
      this.isShareSheetOpen = false;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Save failed: ${error.message}`);
      promptAction.showToast({ message: '保存失败', duration: 2000 });
    }
  }

  async ensureAlbumPermissions(): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(this.context, ['ohos.permission.READ_IMAGEVIDEO', 'ohos.permission.WRITE_IMAGEVIDEO']);
      return Array.isArray(result.authResults) ? result.authResults.every(v => v === 0) : true;
    } catch (err) {
      return false;
    }
  }

  async setMood(index: number) {
    this.moodIndex = index;
    await this.manager.setTodayMood(index, this.moodNote);
    promptAction.showToast({ message: '✨ 心情已记录', duration: 1200 });
  }

  togglePrivacyMode() {
    this.privacyMode = !this.privacyMode;
    this.manager.setPrivacyMode(this.privacyMode);
    promptAction.showToast({ message: this.privacyMode ? '🔒 私密模式已开启' : '🔓 私密模式已关闭' });
  }
  openBreathingGuide() { this.isBreathingSheetOpen = true; }

  async loadGalleryData() {
    this.isShareSheetOpen = false;
    this.isEnergySheetOpen = false;
    this.galleryList = await this.manager.getGallery();
    this.collectionProgress = Math.round((this.galleryList.length / TAROT_DECK.length) * 100);
    animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
      this.isGallerySheetOpen = true;
    });
  }
  isCollected(id: number): boolean { return this.galleryList.some(record => record.cardId === id); }

  getCardRarityColor(id: number): string {
    const record = this.galleryList.find(r => r.cardId === id);
    return record ? record.rarityColor : 'rgba(0,0,0,0.1)';
  }

  getThemePrimaryTextColor(): string { return this.shareTheme === 'star' ? '#EEEEEE' : '#333333'; }
  getThemeSecondaryTextColor(): string { return this.shareTheme === 'star' ? '#BBBBBB' : '#888888'; }

  // 🚀 改写后的云同步逻辑：集成华为登录
  async handleCloudSync() {
    // 1. 检查本地是否已登录
    let currentUser = this.userManager.getCurrentUser();

    if (!this.userManager.isLoggedIn()) {
      try {
        promptAction.showToast({ message: '正在连接华为账号...', duration: 1500 });
        // 调用 UserManager 执行登录（包含静默 + 交互重试）
        currentUser = await this.userManager.login(this.context);
        // 👈 登录成功后，刷新本地状态，触发 UI 更新
        this.refreshLoginStatus();
        promptAction.showToast({ message: `欢迎回来，${currentUser.nickname}`, duration: 2000 });
      } catch (err) {
        const error = err as BusinessError;
        console.error('登录失败', JSON.stringify(error));
        promptAction.showToast({ message: '需要登录才能同步数据哦', duration: 2000 });
        return;
      }
    }

    if (!currentUser) return;

    const realUserId = currentUser.userId;
    const realToken = currentUser.token;

    // 2. 连接服务器逻辑 (使用真实的 ID 和 Token)
    promptAction.showToast({ message: '正在连接云端...', duration: 1000 });
    const isOnline = await CloudService.checkConnection();
    const statusEmoji = isOnline ? '🟢' : '🔴';
    const statusText = isOnline ? '服务器在线' : '服务器连接失败';

    promptAction.showDialog({
      title: `☁️ 云端同步 (${statusEmoji} ${statusText})`,
      message: isOnline
        ? `当前账号: ${currentUser.nickname}\n请选择操作：\n• 上传：备份本机数据到云端\n• 下载：从云端恢复数据到本机`
        : '⚠️ 无法连接到云服务器，请检查网络。',
      buttons: [
        { text: '⬆️ 上传备份', color: isOnline ? '#007DFF' : '#CCCCCC' },
        { text: '⬇️ 下载恢复', color: isOnline ? '#007DFF' : '#CCCCCC' },
        { text: '取消', color: '#999999' }
      ]
    }, async (err, data) => {
      if (err || data.index === 2 || !isOnline) return;

      if (data.index === 0) {
        promptAction.showToast({ message: '正在上传备份...', duration: 2000 });
        const allData = await this.manager.exportAllData();
        // 传递真实用户数据给后端
        const success = await CloudService.backupData(realUserId, realToken, allData);
        if (success) {
          promptAction.showToast({ message: '✅ 备份成功！' });
        } else {
          promptAction.showToast({ message: '❌ 备份失败' });
        }
      } else {
        promptAction.showToast({ message: '正在下载恢复...', duration: 2000 });
        // 传递真实用户数据给后端
        const jsonStr = await CloudService.restoreData(realUserId, realToken);
        if (jsonStr) {
          const ok = await this.manager.importData(jsonStr);
          if (ok) {
            promptAction.showToast({ message: '✅ 恢复成功，即将刷新...' });
            this.checkState();
            this.initDate();
          } else {
            promptAction.showToast({ message: '⚠️ 数据解析失败' });
          }
        } else {
          promptAction.showToast({ message: '❌ 未找到云端备份或下载失败' });
        }
      }
    });
  }

  // 👈 新增：处理用户点击头像的逻辑
  async handleUserClick() {
    if (this.currentUserInfo) {
      // 已登录：询问是否退出
      promptAction.showDialog({
        title: '账号管理',
        message: `当前登录：${this.currentUserInfo.nickname}\n是否退出登录？`,
        buttons: [
          { text: '退出登录', color: '#FF0000' },
          { text: '取消', color: '#999999' }
        ]
      }, (err, data) => {
        if (data.index === 0) {
          this.userManager.logout();
          this.refreshLoginStatus();
          promptAction.showToast({ message: '已退出登录' });
        }
      });
    } else {
      // 未登录：触发登录流程
      try {
        const user = await this.userManager.login(this.context);
        this.refreshLoginStatus();
        promptAction.showToast({ message: `欢迎，${user.nickname}` });
      } catch (e) {
        // 登录取消或失败，不做处理
      }
    }
  }

  @Builder GallerySheetBuilder() {
    Column() {
      Row() {
        Column() {
          Text("治愈展览厅").fontSize(24).fontWeight(FontWeight.Bold).fontColor('#333333')
          Text(`已收集 ${this.galleryList.length} / ${TAROT_DECK.length} 张`).fontSize(13).fontColor('#888888').margin({ top: 4 })
        }.alignItems(HorizontalAlign.Start)
        Blank()
        Stack() {
          Progress({ value: this.collectionProgress, total: 100, type: ProgressType.Ring }).color('#FF69B4').width(44)
          Text(`${this.collectionProgress}%`).fontSize(10).fontColor('#FF69B4').fontWeight(FontWeight.Bold)
        }.margin({ right: 32 })
      }.width('100%').padding({ left: 24, right: 24, top: 24, bottom: 10 })
      Divider().color('#F9F9F9').width('90%')
      Grid() {
        ForEach(TAROT_DECK, (card: TarotCard) => {
          GridItem() {
            Column() {
              if (this.isCollected(card.id)) {
                Stack() {
                  Image($rawfile(card.image)).width('100%').aspectRatio(2/3).borderRadius(10)
                    .shadow({ radius: 8, color: this.getCardRarityColor(card.id), offsetY: 2 })
                }
                Text(card.name).fontSize(12).fontColor('#333').fontWeight(FontWeight.Medium).margin({ top: 8 })
              } else {
                Stack() {
                  Rect().width('100%').height('100%').fill('#F7F8FA').borderRadius(10).strokeWidth(1).stroke('#F0F0F0')
                  Column({space: 4}) { Text("🔒").fontSize(18).fontColor('#DDD'); Text("???").fontSize(10).fontColor('#EEE') }
                }.width('100%').aspectRatio(2/3)
                Text("待解锁").fontSize(12).fontColor('#EEE').margin({ top: 8 })
              }
            }
          }
        })
      }.columnsTemplate('1fr 1fr 1fr').columnsGap(12).rowsGap(20).padding({ left: 20, right: 20, top: 20, bottom: 80 }).layoutWeight(1)
    }
    .width('100%').height('85%').backgroundColor(Color.White).borderRadius({ topLeft: 24, topRight: 24 })
  }

  @Builder EnergySheetBuilder() {
    Column() {
      Row().width(40).height(5).backgroundColor('#E0E0E0').borderRadius(10).margin({ top: 10, bottom: 20 })
      Text("⚡ 心力加油站").fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 8 })
      Text(`当前剩余: ${this.currentEnergy}`).fontSize(14).fontColor('#999').margin({ bottom: 30 })

      Row() {
        Column() { Text("每日补给").fontSize(16).fontWeight(FontWeight.Bold); Text("每天 00:00 自动恢复至 20 点").fontSize(12).fontColor('#999').margin({ top: 4 }) }.alignItems(HorizontalAlign.Start)
        Blank()
        Button("已领取").backgroundColor('#F5F5F5').fontColor('#BBB').height(32).fontSize(12).enabled(false)
      }.width('90%').padding(16).backgroundColor('#FAFAFA').borderRadius(16).margin({ bottom: 12 })

      Row() {
        Column() { Text("观看广告").fontSize(16).fontWeight(FontWeight.Bold); Text("立即获得 +10 心力").fontSize(12).fontColor('#999').margin({ top: 4 }) }.alignItems(HorizontalAlign.Start)
        Blank()
        Button("去观看").backgroundColor('#E0F7FA').fontColor('#006064').height(32).fontSize(12).onClick(() => this.handleRecharge(10))
      }.width('90%').padding(16).backgroundColor('#FAFAFA').borderRadius(16).margin({ bottom: 12 })

      Row() {
        Column() { Text("心力礼包").fontSize(16).fontWeight(FontWeight.Bold); Text("获得 +100 心力").fontSize(12).fontColor('#999').margin({ top: 4 }) }.alignItems(HorizontalAlign.Start)
        Blank()
        Button("¥ 6.00").backgroundColor('#FFF0F5').fontColor('#FF69B4').height(32).fontSize(12).onClick(() => this.handleRecharge(100))
      }.width('90%').padding(16).backgroundColor('#FAFAFA').borderRadius(16)
    }
    .width('100%').height('50%').backgroundColor(Color.White).borderRadius({ topLeft: 24, topRight: 24 })
  }

  @Builder ShareSheetBuilder() {
    if (!this.currentCard) {
      Column().height(100)
    } else {
      Column() {
        Row({ space: 8 }) {
          Button('轻柔').onClick(() => { this.shareTheme = 'soft'; }).backgroundColor(this.shareTheme === 'soft' ? '#333' : '#EEE').fontColor(this.shareTheme === 'soft' ? '#FFF' : '#000').height(32).fontSize(12)
          Button('极简').onClick(() => { this.shareTheme = 'minimal'; }).backgroundColor(this.shareTheme === 'minimal' ? '#333' : '#EEE').fontColor(this.shareTheme === 'minimal' ? '#FFF' : '#000').height(32).fontSize(12)
          Button('星空').onClick(() => { this.shareTheme = 'star'; }).backgroundColor(this.shareTheme === 'star' ? '#333' : '#EEE').fontColor(this.shareTheme === 'star' ? '#FFF' : '#000').height(32).fontSize(12)
        }.margin({ top: 15, bottom: 15 })

        Column() {
          Row() {
            Column() {
              Text(this.todayDate).fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.getThemePrimaryTextColor())
              Text(this.todayWeek).fontSize(12).fontColor(this.getThemeSecondaryTextColor())
            }.alignItems(HorizontalAlign.Start)
            Blank()
            Text("治愈之书").fontSize(14).fontColor('#FF69B4').fontWeight(FontWeight.Medium)
          }.width('100%').padding({ left: 16, right: 16, top: 16 })

          Image($rawfile(this.currentCard.image))
            .width('100%').aspectRatio(2/3).borderRadius(12).margin({ top: 12 })
            .shadow({ radius: 10, color: 'rgba(0,0,0,0.1)', offsetY: 5 })

          Column() {
            Text(this.currentCard.name).fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.getThemePrimaryTextColor()).margin({ top: 16 })
            Text(this.currentCard.meaning).fontSize(14).fontColor(this.getThemeSecondaryTextColor()).margin({ top: 4, bottom: 12 })

            if (!this.privacyMode) {
              Text(this.currentCard.desc).fontSize(14).fontColor(this.getThemePrimaryTextColor()).opacity(0.8).textAlign(TextAlign.Center).lineHeight(20)
              if (this.goldQuote) {
                Text(`“ ${this.goldQuote} ”`).fontSize(13).fontColor('#FF69B4').fontStyle(FontStyle.Italic).margin({ top: 12 })
              }
            } else {
              Text("🔒 私密模式").fontSize(12).fontColor(this.getThemeSecondaryTextColor()).margin({ top: 10 })
            }
          }.padding(16)

          Row() {
            Text("扫码获取你的治愈卡片").fontSize(10).fontColor(this.getThemeSecondaryTextColor())
            Blank()
            Image($rawfile('qr_code.png')).width(40).height(40).opacity(0.8)
          }.width('100%').padding({ left: 16, right: 16, bottom: 16 })

        }
        .width('88%')
        .backgroundColor(this.shareTheme === 'soft' ? Color.White : (this.shareTheme === 'minimal' ? '#F7F7F7' : '#1A1A2E'))
        .borderRadius(16)
        .shadow({ radius: 20, color: 'rgba(0,0,0,0.1)', offsetY: 10 })
        .id(this.POSTER_ID)
      }
      .width('100%')
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column() {
          Row() {
            // 👈 修改：左侧显示用户头像或登录提示
            Row() {
              if (this.currentUserInfo && this.currentUserInfo.avatar) {
                Image(this.currentUserInfo.avatar)
                  .width(32).height(32).borderRadius(16).margin({ right: 8 })
              } else {
                // 未登录显示默认图标
                Text('👤').fontSize(24).margin({ right: 8 })
              }

              if (this.currentUserInfo) {
                Text(this.currentUserInfo.nickname || '用户')
                  .fontSize(14).fontColor('#333').fontWeight(FontWeight.Medium)
              } else {
                Text('登录').fontSize(14).fontColor('#666')
              }
            }
            .backgroundColor('rgba(255,255,255,0.6)')
            .padding({ left: 8, right: 12, top: 6, bottom: 6 })
            .borderRadius(20)
            .onClick(() => this.handleUserClick())

            Blank()

            // ☁️ 云同步入口 (已绑定新逻辑)
            Button({ type: ButtonType.Circle }) { Text('☁️').fontSize(16) }
            .width(36).height(36).backgroundColor('rgba(255,255,255,0.8)')
            .margin({ right: 12 })
            .onClick(() => this.handleCloudSync())

            Row() {
              Text('⚡').fontSize(14)
              Text(`${this.currentEnergy}`).fontSize(14).fontColor('#FF69B4').fontWeight(FontWeight.Bold).margin({left: 2})
            }.backgroundColor('rgba(255,255,255,0.6)').padding({left: 10, right: 10, top: 6, bottom: 6}).borderRadius(14).margin({right: 12}).onClick(() => this.handleBuyVip())

            Button({ type: ButtonType.Circle }) { Text('🏛️').fontSize(18) }
            .width(40).height(40).backgroundColor(Color.White).shadow({ radius: 8, color: 'rgba(0,0,0,0.05)' })
            .onClick(() => this.loadGalleryData())
          }.width('100%').padding({ left: 24, right: 24, top: 16 }).height(60)

          Blank().height(20)

          Stack() {
            Circle({ width: 260, height: 260 }).fill('#FFFFFF').opacity(0.5)
              .scale({ x: this.mysteryScale, y: this.mysteryScale }).blur(40)

            if (this.rarityLevel >= 5) {
              Circle({ width: 200, height: 200 })
                .fill(this.rarityColor)
                .scale({ x: this.glowScale, y: this.glowScale })
                .opacity(this.glowOpacity)
                .blur(20)
            }

            Image($rawfile('card_back.png')).width('100%').height('100%').borderRadius(16)
              .scale({ x: this.deckScale, y: this.deckScale }).translate({ x: this.deckOffset1 }).rotate({ z: 1, angle: this.deckAngle1 }).opacity(this.deckOpacity)
            Image($rawfile('card_back.png')).width('100%').height('100%').borderRadius(16)
              .scale({ x: this.deckScale, y: this.deckScale }).translate({ x: this.deckOffset2 }).rotate({ z: 1, angle: this.deckAngle2 }).opacity(this.deckOpacity)

            Image($rawfile('card_back.png')).width('100%').height('100%').borderRadius(16)
              .rotate({ x: 0, y: 1, z: 0, angle: this.angle }).opacity(this.angle < 90 ? 1 : 0)

            if (this.currentCard) {
              Image($rawfile(this.currentCard.image))
                .width('100%').height('100%').borderRadius(16)
                .rotate({ x: 0, y: 1, z: 0, angle: this.angle - 180 }).opacity(this.angle >= 90 ? 1 : 0)
            }

            if (this.currentCard && this.rarityLevel >= 6 && this.isFlipped) {
              Text("✨").fontSize(40).position({x: -20, y: -20})
                .scale({x: this.starScale, y: this.starScale})
                .rotate({angle: -15})
                .animation({duration: 1000, iterations: -1, playMode: PlayMode.Alternate})
              Text("✨").fontSize(30).position({x: '85%', y: '85%'})
                .scale({x: this.starScale, y: this.starScale})
                .rotate({angle: 15})
                .animation({duration: 1200, iterations: -1, playMode: PlayMode.Alternate, delay: 200})
            }
          }
          .width('70%').aspectRatio(2/3).margin({ top: 20, bottom: 30 })
          .rotate({ z: 1, angle: this.mainRotateZ + this.shuffleRotate })
          .translate({ x: this.shuffleOffsetX, y: this.floatOffsetY + this.mainOffsetY })
          .scale({ x: this.shuffleScale * this.clickScale, y: this.shuffleScale * this.clickScale })
          .shadow({ radius: this.shadowRadius, color: this.shadowColor, offsetY: this.shadowOffsetY })
          .onClick(() => { this.handleDrawCard(); })

          if (this.showResultText && this.currentCard) {
            Column() {
              Text(this.currentCard.name).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#333333').margin({bottom: 4})
              Text(this.currentCard.name_en).fontSize(14).fontColor('#AAAAAA').fontStyle(FontStyle.Italic).margin({bottom: 16})
              Text(this.currentCard.desc).fontSize(16).fontColor('#555555').textAlign(TextAlign.Center).lineHeight(26).padding({ left: 20, right: 20 }).opacity(0.9)
              Divider().color('#F0F0F0').width('80%').margin({top: 24, bottom: 24})
              Row({ space: 12 }) {
                Button("✨ 分享").backgroundColor('#333333').fontColor(Color.White).height(44).layoutWeight(1).borderRadius(22).onClick(() => this.handleShare())
                Button("🔮 深度解读").backgroundColor('#E0F7FA').fontColor('#006064').height(44).layoutWeight(1).borderRadius(22).onClick(() => router.pushUrl({ url: 'pages/SpreadPage' }))
              }.width('90%').margin({ bottom: 12 })

              if (this.moodIndex === -1) {
                Button("📝 记录此刻心情")
                  .backgroundColor('#FFF0F5')
                  .fontColor('#FF69B4')
                  .height(44)
                  .width('90%')
                  .borderRadius(22)
                  .margin({ bottom: 12 })
                  .onClick(() => router.pushUrl({ url: 'pages/MoodPage' }))
              }

              Button("⚡ 补充心力").backgroundColor(this.moodIndex === -1 ? '#FFFFFF' : '#FFF0F5').fontColor('#FF69B4').height(44).width('90%').borderRadius(22)
                .border(this.moodIndex === -1 ? { width: 1, color: '#FF69B4' } : { width: 0 })
                .onClick(() => this.handleBuyVip())
            }
            .width('92%').backgroundColor('rgba(255,255,255,0.8)').backdropBlur(10).borderRadius(24).padding({ top: 30, bottom: 20 })
            .shadow({ radius: 20, color: 'rgba(0,0,0,0.04)', offsetY: 5 })
            .transition({ type: TransitionType.Insert, opacity: 0, translate: { y: 20 } })
          } else {
            Text("点击卡牌，开启今日指引").fontSize(14).fontColor('#AAAAAA').letterSpacing(1).opacity(this.guideOpacity).margin({ top: 20 })
          }
          Blank().height(120)
        }.width('100%')
      }
      .width('100%').height('100%').scrollBar(BarState.Off)

      BottomNavBar({ current: 'index' })

      if (this.isGallerySheetOpen) {
        Column() {
          Column()
            .width('100%').height('100%').backgroundColor('rgba(0,0,0,0.4)')
            .onClick(() => { animateTo({ duration: 300, curve: Curve.EaseOut }, () => { this.isGallerySheetOpen = false; }); })
            .transition({ opacity: 0 })
            .zIndex(100)
          Column() { this.GallerySheetBuilder() }
          .width('100%')
          .transition({ type: TransitionType.Insert, translate: { y: '100%' } })
          .zIndex(101).position({ y: '15%' }).constraintSize({ maxWidth: 480 })
        }.width('100%').height('100%').zIndex(200)
      }

      if (this.isEnergySheetOpen) {
        Column() {
          Column()
            .width('100%').height('100%').backgroundColor('rgba(0,0,0,0.4)')
            .onClick(() => { animateTo({ duration: 300, curve: Curve.EaseOut }, () => { this.isEnergySheetOpen = false; }); })
            .transition({ opacity: 0 })
            .zIndex(100)
          Column() { this.EnergySheetBuilder() }
          .width('100%')
          .transition({ type: TransitionType.Insert, translate: { y: '100%' } })
          .zIndex(101).position({ y: '50%' }).constraintSize({ maxWidth: 480 })
        }.width('100%').height('100%').zIndex(200)
      }

      if (this.isShareSheetOpen) {
        Column() {
          Column()
            .width('100%').height('100%').backgroundColor('rgba(0,0,0,0.4)')
            .onClick(() => { animateTo({ duration: 300, curve: Curve.EaseOut }, () => { this.isShareSheetOpen = false; }); })
            .transition({ opacity: 0 })
            .zIndex(100)

          Column() {
            this.ShareSheetBuilder()
            Row({ space: 16 }) {
              Button('保存相册').backgroundColor('#F5F5F5').fontColor('#333').layoutWeight(1).height(48).borderRadius(24).fontSize(14).onClick(() => this.executeSave())
              Button('发送给好友').backgroundColor('#333').fontColor('#FFF').layoutWeight(1).height(48).borderRadius(24).fontSize(14).onClick(() => this.handleSystemShare())
            }.width('90%').margin({ top: 20, bottom: 30 })
          }
          .width('100%').backgroundColor(Color.White).borderRadius({ topLeft: 24, topRight: 24 })
          .transition({ type: TransitionType.Insert, translate: { y: '100%' } })
          .zIndex(101).position({ y: '30%' }).constraintSize({ maxWidth: 480 })
        }.width('100%').height('100%').zIndex(200)
      }
    }
    .width('100%').height('100%')
    .linearGradient({ direction: GradientDirection.Top, colors: [['#FDFBFB', 0.0], ['#F2F4F8', 1.0]] })
  }
}