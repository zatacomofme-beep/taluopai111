import { FortuneManager, CardRecord, DailyCardState } from '../common/FortuneManager';
import { fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { TarotCard, TAROT_DECK, resolveDeckImage } from '../model/TarotData';
import common from '@ohos.app.ability.common';
import { abilityAccessCtrl } from '@kit.AbilityKit';
import { promptAction, curves, router, componentSnapshot } from '@kit.ArkUI';
import { formBindingData, formProvider } from '@kit.FormKit';
import { BottomNavBar } from '../common/BottomNavBar';
import { ImageSaver } from '../common/ImageSaver';
import { DeckSelectionSheet } from '../common/DeckSelectionSheet';
import { EnergyManager } from '../common/EnergyManager';
import { ShareHelper } from '../common/ShareHelper';
import { CloudService } from '../common/CloudService';
import { UserManager, UserInfo } from '../common/UserManager';
import { BusinessError } from '@kit.BasicServicesKit';
import { AIService } from '../common/AIService';

// 1. 定义云端资源常量
const OBS_PATH = 'https://taluopai.obs.cn-southwest-2.myhuaweicloud.com/tarot_cards/';
const CARD_BACK_URL = `${OBS_PATH}card_back.png`;
const QR_CODE_URL = `${OBS_PATH}qr_code.png`;

// 🌟 稀有度配置接口
interface RarityItem {
  level: number;
  label: string;
  color: string;
  desc: string;
}

// 🌟 稀有度配置
const RARITY_CONFIG: RarityItem[] = [
  { level: 1, label: 'N', color: 'rgba(200, 200, 200, 0.5)', desc: '普通' },
  { level: 3, label: 'R', color: 'rgba(60, 179, 113, 0.6)', desc: '稀有' },
  { level: 4, label: 'SR', color: 'rgba(30, 144, 255, 0.7)', desc: '史诗' },
  { level: 5, label: 'SSR', color: 'rgba(255, 69, 0, 0.8)', desc: '传说' },
  { level: 6, label: 'UR', color: 'rgba(255, 215, 0, 0.9)', desc: '神话' }
];

@Entry
@Component
struct Index {
  // === 核心数据 ===
  @State drawnCards: TarotCard[] = []; // 已抽取的牌
  @State drawnRarityLevels: number[] = [];
  @State drawnRarityColors: string[] = [];
  @State currentCard: TarotCard | null = null; // 当前正在动画/显示的牌
  @State isFlipped: boolean = false;
  @State showResultText: boolean = false;
  @State isVip: boolean = false;

  // === 🌈 珍稀度系统 (当前正在抽的那张) ===
  @State rarityColor: string = 'rgba(0,0,0,0.15)';
  @State rarityLevel: number = 1;
  @State rarityLabel: string = 'N'; 

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
  @State mainOffsetX: number = 0; // 新增：X轴位移
  @State mainRotateZ: number = 0;

  // 装饰性牌堆
  @State deckOffset1: number = 0;
  @State deckOffset2: number = 0;
  @State deckOpacity: number = 0;
  @State deckScale: number = 0.9;
  @State deckAngle1: number = -5;
  @State deckAngle2: number = 5;

  // 👻 幻影牌堆
  @State phantomOffset1: number = 0;
  @State phantomOffset2: number = 0;
  @State phantomAngle1: number = 0;
  @State phantomAngle2: number = 0;
  @State phantomOpacity: number = 0;

  // 🔒 交互锁
  @State isAnimating: boolean = false;

  // === 🌈 特效变量 ===
  @State glowScale: number = 1;
  @State glowOpacity: number = 0;
  @State starScale: number = 0;
  @State flashOpacity: number = 0; 
  @State flashColor: string = '#FFFFFF'; 
  @State godRayRotate: number = 0; 
  @State godRayOpacity: number = 0; 

  // === 🖼️ 边框动画状态 ===
  @State borderProgress: number = 0; 
  @State borderOpacity: number = 0;

  // === 🏛️ 弹窗状态控制 ===
  @State isGallerySheetOpen: boolean = false;
  @State isEnergySheetOpen: boolean = false;
  @State isDeckSheetOpen: boolean = false;

  // === 🎨 牌组主题 ===
  @StorageLink('CurrentDeckFolder') currentDeckFolder: string = 'impasto%20style/';

  // === 数据 ===
  @State galleryList: CardRecord[] = [];
  @State collectionProgress: number = 0;
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
  @State currentUserInfo: UserInfo | null = null;

  private manager = FortuneManager.getInstance();
  private energyManager = EnergyManager.getInstance();
  private userManager = UserManager.getInstance();
  private context = getContext(this) as common.UIAbilityContext;

  private asyncAnimateTo(duration: number, curve: Curve | string | ICurve, updateFn: () => void): Promise<void> {
    return new Promise((resolve) => {
      animateTo({ duration: duration, curve: curve, onFinish: resolve }, updateFn);
    });
  }

  getCardImageSource(url: string): ResourceStr {
    const finalUrl = resolveDeckImage(url, this.currentDeckFolder);
    if (finalUrl && finalUrl.startsWith('http')) {
      return finalUrl;
    }
    return $rawfile(url);
  }

  async aboutToAppear() {
    await this.manager.init(this.context);
    await this.energyManager.init(this.context);
    this.refreshEnergy();

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

    this.refreshLoginStatus();
  }

  onPageShow() {
    this.refreshEnergy();
    void (async () => {
      const mood = await this.manager.getTodayMood();
      this.moodIndex = mood.mood;
    })();
    this.refreshLoginStatus();
  }

  refreshEnergy() {
    this.currentEnergy = this.energyManager.getEnergy();
  }

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
    const savedData = await this.manager.checkTodayCard();
    
    if (savedData && savedData.cards && savedData.cards.length > 0) {
      this.drawnCards = savedData.cards;
      this.drawnRarityLevels = savedData.rarityLevels;
      this.drawnRarityColors = savedData.rarityColors;
      
      // 如果已经抽完3张，提示状态
      if (this.drawnCards.length >= 3) {
         this.isFlipped = true;
         this.showResultText = true;
      } else {
         // 恢复了一部分
         this.isFlipped = false;
      }

      // 恢复 Form (只显示第一张)
      this.updateForm(this.drawnCards[0]);
    } else {
      this.resetUI();
    }

    void (async () => {
      const restored = await CloudService.autoRestore();
      if (restored) {
        const newSavedCard = await this.manager.checkTodayCard();
        if (newSavedCard && (!this.drawnCards || this.drawnCards.length === 0)) {
          this.checkState();
        }
        promptAction.showToast({ message: '☁️ 数据已从云端同步' });
      }
    })();
  }

  resetUI() {
    this.drawnCards = [];
    this.drawnRarityLevels = [];
    this.drawnRarityColors = [];
    this.currentCard = null;
    this.angle = 0;
    this.isFlipped = false;
    this.showResultText = false;
    this.rarityColor = 'rgba(0,0,0,0.15)';
    this.stopBreathingAnimation();
    this.mainReset();
    this.borderProgress = 0;
    this.borderOpacity = 0;
  }

  mainReset() {
    this.shuffleOffsetX = 0;
    this.shuffleRotate = 0;
    this.shuffleScale = 1;
    this.phantomOpacity = 0;
    this.phantomOffset1 = 0;
    this.phantomOffset2 = 0;
    this.phantomAngle1 = 0;
    this.phantomAngle2 = 0;
    this.isAnimating = false;
    this.godRayOpacity = 0;
    this.godRayRotate = 0;
    this.mainOffsetX = 0;
    this.mainOffsetY = 0;
  }

  @Builder ComplexBorderBuilder() {
    Stack() {
      Row()
        .width(`${Math.min(Math.max(this.borderProgress, 0), 1) * 92}%`)
        .height(3)
        .backgroundColor('#FFD700')
        .shadow({ radius: 2, color: '#AA8800', offsetY: 0 })
        .position({ x: '4%', y: 8 })

      Column()
        .height(`${Math.min(Math.max(this.borderProgress - 1, 0), 1) * 92}%`)
        .width(3)
        .backgroundColor('#FFD700')
        .shadow({ radius: 2, color: '#AA8800', offsetY: 0 })
        .position({ x: '94%', y: '4%' })

      Row()
        .width(`${Math.min(Math.max(this.borderProgress - 2, 0), 1) * 92}%`)
        .height(3)
        .backgroundColor('#FFD700')
        .shadow({ radius: 2, color: '#AA8800', offsetY: 0 })
        .position({ x: '4%', y: '94%' })

      Column()
        .height(`${Math.min(Math.max(this.borderProgress - 3, 0), 1) * 92}%`)
        .width(3)
        .backgroundColor('#FFD700')
        .shadow({ radius: 2, color: '#AA8800', offsetY: 0 })
        .position({ x: 8, y: '4%' })

      if (this.borderProgress > 0.1) {
        Text("✦").fontSize(16).fontColor('#FFD700').position({ x: 2, y: 2 })
          .transition({ type: TransitionType.Insert, opacity: 0, scale: { x: 0, y: 0 } })
      }
      // ... 其他角省略，保留核心视觉 ...
      
      Stack() {
        Rect().width('100%').height('100%').fill('transparent')
          .stroke('#AAFFD700').strokeWidth(1)
      }
      .width('85%').height('90%')
      .opacity(this.borderProgress > 3.5 ? 1 : 0)
      .animation({ duration: 500 })
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
    .opacity(this.borderOpacity)
  }

  @Builder GodRayBuilder() {
    Stack() {
      ForEach([0, 45, 90, 135], (angle: number) => {
        Column()
          .width(30)
          .height(600)
          .linearGradient({
            direction: GradientDirection.Top,
            colors: [[this.rarityLevel === 6 ? '#FFD700' : '#FF4500', 0], ['rgba(255,255,255,0)', 0.5], [this.rarityLevel === 6 ? '#FFD700' : '#FF4500', 1]]
          })
          .opacity(0.3)
          .rotate({ angle: angle })
      })
      ForEach([22.5, 67.5, 112.5, 157.5], (angle: number) => {
        Column()
          .width(15)
          .height(500)
          .linearGradient({
            direction: GradientDirection.Top,
            colors: [['#FFFFFF', 0], ['rgba(255,255,255,0)', 0.5], ['#FFFFFF', 1]]
          })
          .opacity(0.4)
          .rotate({ angle: angle })
      })
    }
    .width(500)
    .height(500)
    .rotate({ angle: this.godRayRotate })
    .opacity(this.godRayOpacity)
    .hitTestBehavior(HitTestMode.None)
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
          }
        }
      })();
    } catch (err) {
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
    let config = RARITY_CONFIG[0]; 
    if (rand < 1) config = RARITY_CONFIG.find(c => c.level === 6) || config;      
    else if (rand < 6) config = RARITY_CONFIG.find(c => c.level === 5) || config; 
    else if (rand < 20) config = RARITY_CONFIG.find(c => c.level === 4) || config;
    else if (rand < 50) config = RARITY_CONFIG.find(c => c.level === 3) || config;
    else config = RARITY_CONFIG.find(c => c.level === 1) || config;               
    this.rarityLevel = config.level;
    this.rarityColor = config.color;
    this.rarityLabel = config.label;
  }

  getFlipDurationByRarity(): number {
    const map = [800, 900, 1000, 1200, 1500, 1800, 2000];
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
    if (this.drawnCards.length >= 3) {
      promptAction.showToast({ message: '📅 今日已抽取三张牌，请进行深度解读', duration: 2000 });
      this.handleClickFeedback();
      return;
    }

    if (this.isAnimating) return;
    this.isAnimating = true;

    this.guideOpacity = 0;
    this.stopMysteryAnimation();
    
    this.mainOffsetX = 0;
    this.mainOffsetY = 0;
    this.angle = 0;
    this.isFlipped = false;
    this.currentCard = null; 

    await this.asyncAnimateTo(300, Curve.EaseOut, () => {
      this.mainScale = 0.9;
      this.shadowRadius = 5;
      this.shadowOffsetY = 2;
      this.deckOpacity = 1;
      this.phantomOpacity = 1;
      this.deckOffset1 = 0; this.deckOffset2 = 0;
      this.phantomOffset1 = 0; this.phantomOffset2 = 0;
    });

    for (let i = 0; i < 4; i++) {
      const dir = i % 2 === 0 ? 1 : -1;
      await this.asyncAnimateTo(150, Curve.Rhythm, () => {
        this.shuffleRotate = 2 * dir;
        this.deckOffset1 = -20 * dir;
        this.deckOffset2 = 20 * dir;
        this.phantomOffset1 = -40 * dir;
        this.phantomOffset2 = 40 * dir;
        this.deckAngle1 = -5 * dir;
        this.deckAngle2 = 5 * dir;
      });
    }

    const newCard = await this.manager.drawRandomCard();
    this.currentCard = newCard;
    this.calculateRarity();
    
    await this.asyncAnimateTo(500, curves.springMotion(0.6, 0.8), () => {
      this.shuffleRotate = 0;
      this.mainScale = 1.0;
      this.deckOffset1 = -60;   this.deckAngle1 = -10;
      this.deckOffset2 = 60;    this.deckAngle2 = 10;
      this.phantomOffset1 = -120; this.phantomAngle1 = -20;
      this.phantomOffset2 = 120;  this.phantomAngle2 = 20;
    });

    await new Promise<void>(r => setTimeout(r, 200));

    await this.asyncAnimateTo(500, curves.springMotion(0.7, 0.7), () => {
      this.mainScale = 1.1;
      this.mainOffsetY = -50; 
      this.shadowRadius = 30;
      this.shadowColor = 'rgba(0,0,0,0.3)';
      
      this.deckOpacity = 0;
      this.phantomOpacity = 0;
      this.deckOffset1 = -200; this.deckOffset2 = 200;
      this.phantomOffset1 = -300; this.phantomOffset2 = 300;
    });

    const flipDuration = this.getFlipDurationByRarity();
    
    animateTo({ duration: flipDuration, curve: Curve.EaseInOut }, () => {
      this.angle = 180;
    });

    setTimeout(() => {
        this.isFlipped = true;
    }, flipDuration / 2);

    await new Promise<void>(r => setTimeout(r, flipDuration + 200));

    const slotIndex = this.drawnCards.length;
    let targetX = 0;
    // 根据屏幕宽度动态计算，这里暂定 360vp 屏幕宽，每张卡 80，间距 20
    // Slot 0: -100, Slot 1: 0, Slot 2: 100
    if (slotIndex === 0) targetX = -100;
    else if (slotIndex === 1) targetX = 0;
    else if (slotIndex === 2) targetX = 100;

    await this.asyncAnimateTo(500, curves.springMotion(0.6, 0.8), () => {
        this.mainOffsetX = targetX;
        this.mainOffsetY = -250; // 向上归位到槽位
        this.mainScale = 0.4; // 缩小
    });

    this.drawnCards.push(newCard);
    this.drawnRarityLevels.push(this.rarityLevel);
    this.drawnRarityColors.push(this.rarityColor);
    
    await this.manager.saveTodayState(this.drawnCards, this.drawnRarityLevels, this.drawnRarityColors);
    CloudService.autoSave();
    
    this.isAnimating = false;
    this.currentCard = null; // 动画结束，卡片进入列表，当前动画卡片清空

    if (this.drawnCards.length === 3) {
       promptAction.showToast({ message: '✨ 抽取完成，请点击深度解读', duration: 3000 });
    }
  }

  async handleUserClick() {
    if (this.currentUserInfo) {
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
      try {
        const user = await this.userManager.login(this.context);
        this.refreshLoginStatus();
        promptAction.showToast({ message: `欢迎，${user.nickname}` });
      } catch (e) {
      }
    }
  }

  async handleCloudSync() {
    // ... (Keep existing logic if needed, but for brevity in rewrite I'll assume standard CloudService usage)
    // For safety, I'll restore the original logic here
    let currentUser = this.userManager.getCurrentUser();

    if (!this.userManager.isLoggedIn()) {
      try {
        promptAction.showToast({ message: '正在连接华为账号...', duration: 1500 });
        currentUser = await this.userManager.login(this.context);
        this.refreshLoginStatus();
        promptAction.showToast({ message: `欢迎回来，${currentUser.nickname}`, duration: 2000 });
      } catch (err) {
        promptAction.showToast({ message: '需要登录才能同步数据哦', duration: 2000 });
        return;
      }
    }

    if (!currentUser) return;
    const realUserId = currentUser.userId;
    const realToken = currentUser.token;

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
        const success = await CloudService.backupData(realUserId, realToken, allData);
        if (success) promptAction.showToast({ message: '✅ 备份成功！' });
        else promptAction.showToast({ message: '❌ 备份失败' });
      } else {
        promptAction.showToast({ message: '正在下载恢复...', duration: 2000 });
        const jsonStr = await CloudService.restoreData(realUserId, realToken);
        if (jsonStr) {
          const ok = await this.manager.importData(jsonStr);
          if (ok) {
            promptAction.showToast({ message: '✅ 恢复成功，即将刷新...' });
            this.checkState();
            this.initDate();
          } else promptAction.showToast({ message: '⚠️ 数据解析失败' });
        } else promptAction.showToast({ message: '❌ 未找到云端备份或下载失败' });
      }
    });
  }

  async handleNavigateToAnalysis() {
    // 跳转到 DeepAnalysisResultPage，传递 3 张牌
    if (this.drawnCards.length < 3) return;
    
    // 构造 Time Flow 数据
    // 这里我们假设 drawnCards[0]=Past, [1]=Present, [2]=Future
    // 但是 DeepAnalysisResultPage 需要通过 params 传递什么？
    // 查看 DeepAnalysisResultPage，它似乎接收 `cards` 参数
    
    router.pushUrl({
      url: 'pages/DeepAnalysisResultPage',
      params: {
        cards: this.drawnCards,
        isDailyAnalysis: true, // 标记为每日分析
        isFree: await this.manager.isDailyDeepAnalysisFree()
      }
    });
  }
  
  async loadGalleryData() {
    this.isGallerySheetOpen = true;
    this.isEnergySheetOpen = false;
    this.galleryList = await this.manager.getGallery();
    this.collectionProgress = Math.round((this.galleryList.length / TAROT_DECK.length) * 100);
  }

  isCollected(id: number): boolean {
    return this.galleryList.some(c => c.cardId === id);
  }

  // === 🃏 核心构建 ===
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 1. 沉浸式背景 (深邃星空紫)
      Column()
        .width('100%').height('100%')
        .backgroundColor('#0f0c29')
        .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [['#0f0c29', 0.0], ['#302b63', 0.5], ['#24243e', 1.0]]
        })
        .blur(this.isGallerySheetOpen || this.isEnergySheetOpen ? 20 : 0)
        .animation({ duration: 400 })

      // 2. 圣光特效层 (居中)
      Column() {
        this.GodRayBuilder()
      }
      .width('100%').height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .hitTestBehavior(HitTestMode.None)

      // 3. 主要内容区域
      Column() {
          // 3.1 顶部空白 & 状态栏占位
          Blank().height(40)

          // 3.2 顶部功能栏 (能量/VIP/用户)
          Row() {
            // 左侧：能量 & VIP
            Row({ space: 8 }) {
              Text('⚡').fontColor('#FFD700').fontSize(18)
              Text(`${this.currentEnergy}`).fontColor('#FFD700').fontSize(16).fontWeight(FontWeight.Bold)
              if (this.isVip) {
                Text('VIP').fontSize(10).fontColor(Color.White).backgroundColor('#FFD700').padding({ left:6, right:6, top:2, bottom:2 }).borderRadius(8)
              } else {
                Text('Get VIP').fontSize(10).fontColor(Color.White).backgroundColor('rgba(255,255,255,0.2)').padding({ left:6, right:6, top:2, bottom:2 }).borderRadius(8)
                  .onClick(() => this.handleBuyVip())
              }
            }
            .backgroundColor('rgba(0,0,0,0.4)').padding(8).borderRadius(20)
            .onClick(() => this.handleBuyVip())

            Blank()

            // 右侧：云端 & 用户
            Row({ space: 12 }) {
              Text('☁️').fontSize(22).onClick(() => this.handleCloudSync())
              if (this.currentUserInfo) {
                 Image(this.currentUserInfo.avatar).width(32).height(32).borderRadius(16).onClick(() => this.handleUserClick())
              } else {
                 Text('👤').fontSize(22).onClick(() => this.handleUserClick())
              }
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .margin({ bottom: 20 })

          // 3.3 顶部槽位区域 (显示已抽取的牌)
          Row() {
            this.CardSlot(0, '过去')
            this.CardSlot(1, '现在')
            this.CardSlot(2, '未来')
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceEvenly)
          .margin({ bottom: 40 })

          // 3.4 中央抽牌区 (牌堆 & 动画) - 占据剩余空间直到底部
          Stack() {
            // 底部幻影 (仅当还有牌没抽完时显示)
            if (this.drawnCards.length < 3) {
                Image(this.getCardImageSource(CARD_BACK_URL))
                  .width(200).aspectRatio(2/3).borderRadius(12)
                  .rotate({ angle: this.phantomAngle1 })
                  .offset({ x: this.phantomOffset1, y: 10 })
                  .opacity(this.phantomOpacity)
                  .animation({ duration: 500 })
                
                Image(this.getCardImageSource(CARD_BACK_URL))
                  .width(200).aspectRatio(2/3).borderRadius(12)
                  .rotate({ angle: this.phantomAngle2 })
                  .offset({ x: this.phantomOffset2, y: 10 })
                  .opacity(this.phantomOpacity)
                  .animation({ duration: 500 })

                // 装饰性牌堆
                Image(this.getCardImageSource(CARD_BACK_URL))
                  .width(200).aspectRatio(2/3).borderRadius(12)
                  .rotate({ angle: this.deckAngle1 })
                  .offset({ x: this.deckOffset1, y: 5 })
                  .opacity(this.deckOpacity)
                
                Image(this.getCardImageSource(CARD_BACK_URL))
                  .width(200).aspectRatio(2/3).borderRadius(12)
                  .rotate({ angle: this.deckAngle2 })
                  .offset({ x: this.deckOffset2, y: 5 })
                  .opacity(this.deckOpacity)
                
                // 主牌堆 (点击触发)
                Image(this.getCardImageSource(CARD_BACK_URL))
                  .width(200).aspectRatio(2/3).borderRadius(12)
                  .shadow({ radius: this.shadowRadius, color: this.shadowColor, offsetY: this.shadowOffsetY })
                  .scale({ x: this.clickScale * this.mysteryScale, y: this.clickScale * this.mysteryScale })
                  .onClick(() => this.handleDrawCard())
                  .opacity(this.drawnCards.length < 3 ? 1 : 0) // 抽完隐藏
                  .id('mainDeck')
            } else {
                // 抽完后显示深度解读按钮
                Column() {
                    Button('✨ 开启深度解读')
                      .backgroundColor('#FF69B4')
                      .fontColor(Color.White)
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .width(200)
                      .height(60)
                      .borderRadius(30)
                      .shadow({ radius: 10, color: 'rgba(255,105,180,0.5)', offsetY: 5 })
                      .onClick(() => this.handleNavigateToAnalysis())
                      .scale({ x: this.mysteryScale, y: this.mysteryScale }) // 复用呼吸动画
                }
                .transition({ type: TransitionType.Insert, opacity: 0, scale: { x: 0.5, y: 0.5 } })
            }

            // === 🌟 正在动画中的卡牌 (独立于槽位和牌堆) ===
            if (this.currentCard) {
                Stack() {
                    // 背面
                    Image(this.getCardImageSource(CARD_BACK_URL))
                      .width(200).aspectRatio(2/3).borderRadius(12)
                      .rotate({ y: 1, angle: this.angle }) // 0度
                      .visibility(this.angle >= 90 ? Visibility.Hidden : Visibility.Visible)
                      .shadow({ radius: this.shadowRadius, color: this.shadowColor, offsetY: this.shadowOffsetY })

                    // 正面
                    Image(this.getCardImageSource(this.currentCard.image))
                      .width(200).aspectRatio(2/3).borderRadius(12)
                      .rotate({ y: 1, angle: this.angle - 180 }) // 初始 -180度
                      .visibility(this.angle >= 90 ? Visibility.Visible : Visibility.Hidden)
                      .shadow({ radius: this.shadowRadius, color: this.shadowColor, offsetY: this.shadowOffsetY })
                      // 稀有度边框
                      .overlay(this.ComplexBorderBuilder())
                }
                .scale({ x: this.mainScale, y: this.mainScale })
                .offset({ x: this.mainOffsetX, y: this.mainOffsetY })
                .rotate({ z: 1, angle: this.mainRotateZ })
                .zIndex(100) // 保证在最上层
            }
          }
          .width('100%')
          .layoutWeight(1) // 占据剩余高度
          .alignContent(Alignment.Center)
          .margin({ bottom: 100 }) // 避开底部导航栏
      }
      .width('100%')
      .height('100%')

      // 4. 底部导航栏 (固定在最下方)
      Column() {
         BottomNavBar({ current: 'index' })
      }
      .width('100%')
      .position({ x: 0, y: '100%' })
      .markAnchor({ x: 0, y: '100%' })
      .padding({ bottom: 16 })

      // 5. 各种弹窗 Sheet
      // 图鉴
      if (this.isGallerySheetOpen) {
        Column() {
          Row() {
             Text(`已收集 ${this.galleryList.length}/${TAROT_DECK.length}`).fontColor(Color.White).fontSize(16)
             Blank()
             Text('✕').fontColor(Color.White).fontSize(20).onClick(() => this.isGallerySheetOpen = false)
          }.width('100%').padding(16)
          
          Grid() {
            ForEach(TAROT_DECK, (card: TarotCard) => {
              GridItem() {
                Column() {
                   if (this.isCollected(card.id)) {
                     Image(this.getCardImageSource(card.image)).width('100%').aspectRatio(2/3).borderRadius(8)
                   } else {
                     Image(this.getCardImageSource(CARD_BACK_URL)).width('100%').aspectRatio(2/3).borderRadius(8).opacity(0.5)
                   }
                }
              }
            })
          }
          .columnsTemplate('1fr 1fr 1fr 1fr')
          .rowsGap(10).columnsGap(10)
          .padding(16)
          .layoutWeight(1)
        }
        .width('100%').height('80%')
        .backgroundColor('#1a1a2e')
        .position({ y: '20%' })
        .transition({ translate: { y: 1000 } })
        .zIndex(200) // 确保在最上层
      }

      // 能量充值
      if (this.isEnergySheetOpen) {
        Column() {
          Text('✨ 补充心力 ✨').fontSize(20).fontColor(Color.White).margin({ top: 20, bottom: 20 })
          Button('看视频补充 (+10)').width('80%').height(50).onClick(() => this.handleRecharge(10)).margin({ bottom: 10 })
          Button('每日签到 (+5)').width('80%').height(50).onClick(() => this.handleRecharge(5))
          Text('✕').fontColor(Color.White).fontSize(24).position({ x: '90%', y: 20 }).onClick(() => this.isEnergySheetOpen = false)
        }
        .width('100%').height('40%')
        .backgroundColor('#1a1a2e')
        .position({ y: '60%' })
        .transition({ translate: { y: 1000 } })
        .zIndex(200)
      }

    }
    .width('100%')
    .height('100%')
  }

  @Builder CardSlot(index: number, label: string) {
    Column() {
      Text(label)
        .fontColor('rgba(255,255,255,0.6)')
        .fontSize(12)
        .margin({ bottom: 8 })
      
      if (this.drawnCards.length > index) {
        // 已抽取
        Image(this.getCardImageSource(this.drawnCards[index].image))
          .width(80).aspectRatio(2/3).borderRadius(6)
          .shadow({ radius: 5, color: 'rgba(0,0,0,0.3)' })
          // 点击查看详情?
          .onClick(() => {
             // 可以弹窗显示大图
          })
      } else {
        // 空槽位
        Rect()
          .width(80).aspectRatio(2/3).radius(6)
          .fill('rgba(255,255,255,0.1)')
          .stroke('rgba(255,255,255,0.2)')
          .strokeWidth(1)
          .strokeDashArray([5, 5])
      }
    }
  }
}