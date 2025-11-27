import { FortuneManager, CardRecord } from '../common/FortuneManager';
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
  @State currentCard: TarotCard | null = null;
  @State isFlipped: boolean = false;
  @State showResultText: boolean = false;
  @State isVip: boolean = false;

  // === 🌈 珍稀度系统 ===
  @State rarityColor: string = 'rgba(0,0,0,0.15)';
  @State rarityLevel: number = 1;
  @State rarityLabel: string = 'N'; // 新增：显示稀有度标签

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

  // 👻 幻影牌堆（用于更华丽的洗牌/扇形动画）
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
  @State flashOpacity: number = 0; // 新增：全屏闪光透明度
  @State flashColor: string = '#FFFFFF'; // 新增：全屏闪光颜色
  @State godRayRotate: number = 0; // 新增：圣光旋转角度
  @State godRayOpacity: number = 0; // 新增：圣光透明度

  // === 🖼️ 边框动画状态 ===
  @State borderProgress: number = 0; // 0-4: 0-1(Top), 1-2(Right), 2-3(Bottom), 3-4(Left)
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

  // 智能图片源处理：兼容网络图片和本地 rawfile
  getCardImageSource(url: string): ResourceStr {
    // 尝试根据当前牌组解析动态 URL
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
    if (savedData) {
      this.currentCard = savedData.card;
      this.rarityLevel = savedData.rarityLevel;
      this.rarityColor = savedData.rarityColor;
      
      // 根据稀有度获取对应的标签
      const config = RARITY_CONFIG.find(c => c.level === this.rarityLevel);
      this.rarityLabel = config ? config.label : 'N';

      this.angle = 180;
      this.isFlipped = true;
      this.showResultText = true;
      this.startBreathingAnimation();
      
      // 恢复边框状态
      this.borderProgress = 4;
      this.borderOpacity = 1;
      
      // 恢复阴影效果
      this.shadowColor = this.rarityLevel >= 5 ? this.rarityColor : 'rgba(0,0,0,0.2)';
      this.shadowRadius = this.rarityLevel >= 5 ? 30 : 10;
      
      this.updateForm(savedData.card);
    } else {
      this.resetUI();
    }

    // 🟢 启动时尝试自动同步（不阻塞 UI）
    void (async () => {
      const restored = await CloudService.autoRestore();
      if (restored) {
        // 如果有新数据恢复，重新刷新状态
        const newSavedCard = await this.manager.checkTodayCard();
        if (newSavedCard && !this.currentCard) {
          this.checkState();
        }
        promptAction.showToast({ message: '☁️ 数据已从云端同步' });
      }
    })();
  }

  resetUI() {
    this.currentCard = null;
    this.angle = 0;
    this.isFlipped = false;
    this.showResultText = false;
    this.rarityColor = 'rgba(0,0,0,0.15)';
    this.stopBreathingAnimation();
    this.mainReset();
    // 重置边框动画
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
  }

  @Builder ComplexBorderBuilder() {
    Stack() {
      // 1. 顶部线条 (从左到右)
      Row()
        .width(`${Math.min(Math.max(this.borderProgress, 0), 1) * 92}%`) // 留出角的位置
        .height(3)
        .backgroundColor('#FFD700') // 金色
        .shadow({ radius: 2, color: '#AA8800', offsetY: 0 })
        .position({ x: '4%', y: 8 }) // 内缩一点

      // 2. 右侧线条 (从上到下)
      Column()
        .height(`${Math.min(Math.max(this.borderProgress - 1, 0), 1) * 92}%`)
        .width(3)
        .backgroundColor('#FFD700')
        .shadow({ radius: 2, color: '#AA8800', offsetY: 0 })
        .position({ x: '94%', y: '4%' }) // x = 100% - 8px - width

      // 3. 底部线条 (从右到左 - 这里简化为从左到右显示，视觉上一样，如果需要方向感可以反转对其方式)
      // 为了实现从右到左的绘制感，我们可以让它右对齐
      Row()
        .width(`${Math.min(Math.max(this.borderProgress - 2, 0), 1) * 92}%`)
        .height(3)
        .backgroundColor('#FFD700')
        .shadow({ radius: 2, color: '#AA8800', offsetY: 0 })
        .position({ x: '4%', y: '94%' }) // y = 100% - 8px - height
        // 注意：ArkTS Row 默认左对齐，如果想从右边长出来，需要嵌套在 Stack 且 alignment: TopEnd，或者用 direction
        // 这里简单处理，统一顺时针感觉

      // 4. 左侧线条 (从下到上)
      Column()
        .height(`${Math.min(Math.max(this.borderProgress - 3, 0), 1) * 92}%`)
        .width(3)
        .backgroundColor('#FFD700')
        .shadow({ radius: 2, color: '#AA8800', offsetY: 0 })
        .position({ x: 8, y: '4%' })

      // 5. 四角装饰 (当进度到达对应阶段时显现)
      if (this.borderProgress > 0.1) {
        Text("✦").fontSize(16).fontColor('#FFD700').position({ x: 2, y: 2 })
          .transition({ type: TransitionType.Insert, opacity: 0, scale: { x: 0, y: 0 } })
      }
      if (this.borderProgress > 1.1) {
        Text("✦").fontSize(16).fontColor('#FFD700').position({ x: '92%', y: 2 })
          .transition({ type: TransitionType.Insert, opacity: 0, scale: { x: 0, y: 0 } })
      }
      if (this.borderProgress > 2.1) {
        Text("✦").fontSize(16).fontColor('#FFD700').position({ x: '92%', y: '92%' })
          .transition({ type: TransitionType.Insert, opacity: 0, scale: { x: 0, y: 0 } })
      }
      if (this.borderProgress > 3.1) {
        Text("✦").fontSize(16).fontColor('#FFD700').position({ x: 2, y: '92%' })
          .transition({ type: TransitionType.Insert, opacity: 0, scale: { x: 0, y: 0 } })
      }
      
      // 6. 内框装饰线 (细线，固定显示，随透明度渐变)
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
      // 主光束
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
      // 副光束
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
    .hitTestBehavior(HitTestMode.None) // 不拦截点击
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
    let config = RARITY_CONFIG[0]; // Default N

    if (rand < 1) config = RARITY_CONFIG.find(c => c.level === 6) || config;      // UR 1%
    else if (rand < 6) config = RARITY_CONFIG.find(c => c.level === 5) || config; // SSR 5%
    else if (rand < 20) config = RARITY_CONFIG.find(c => c.level === 4) || config;// SR 14%
    else if (rand < 50) config = RARITY_CONFIG.find(c => c.level === 3) || config;// R 30%
    else config = RARITY_CONFIG.find(c => c.level === 1) || config;               // N 50%

    this.rarityLevel = config.level;
    this.rarityColor = config.color;
    this.rarityLabel = config.label;
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

    // 🔒 防止重复点击
    if (this.isAnimating) return;
    this.isAnimating = true;

    this.guideOpacity = 0;
    this.stopMysteryAnimation();

    // === 🎬 阶段 1：唤醒牌堆 (0ms - 300ms) ===
    // 显现所有牌，准备洗牌
    await this.asyncAnimateTo(300, Curve.EaseOut, () => {
      this.mainScale = 0.9;
      this.shadowRadius = 5;
      this.shadowOffsetY = 2;
      this.deckOpacity = 1;
      this.phantomOpacity = 1; // 显示幻影牌
      // 归位
      this.deckOffset1 = 0; this.deckOffset2 = 0;
      this.phantomOffset1 = 0; this.phantomOffset2 = 0;
    });

    // === 🎬 阶段 2：华丽洗牌 (300ms - 900ms) ===
    // 模拟洗牌动作：牌左右交错
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

    // 在洗牌间隙获取数据
    this.currentCard = await this.manager.drawDailyCard();
    this.calculateRarity();

    if (this.currentCard) {
      await this.manager.saveDrawResult(this.currentCard, this.rarityColor, this.rarityLevel);
      CloudService.autoSave();
    }

    // === 🎬 阶段 3：扇形展开 (900ms - 1400ms) ===
    await this.asyncAnimateTo(500, curves.springMotion(0.6, 0.8), () => {
      this.shuffleRotate = 0;
      this.mainScale = 1.0;
      // 扇形展开
      this.deckOffset1 = -60;   this.deckAngle1 = -10;
      this.deckOffset2 = 60;    this.deckAngle2 = 10;
      this.phantomOffset1 = -120; this.phantomAngle1 = -20;
      this.phantomOffset2 = 120;  this.phantomAngle2 = 20;
    });

    // 稍作停顿
    await new Promise<void>(r => setTimeout(r, 200));

    // === 🎬 阶段 4：选中抽离 (1600ms - 2100ms) ===
    await this.asyncAnimateTo(500, curves.springMotion(0.7, 0.7), () => {
      // 主牌突出并上浮
      this.mainScale = 1.1;
      this.floatOffsetY = -50;
      this.shadowRadius = 30;
      this.shadowColor = 'rgba(0,0,0,0.3)';
      
      // 其他牌退散
      this.deckOpacity = 0;
      this.phantomOpacity = 0;
      this.deckOffset1 = -200; this.deckOffset2 = 200;
      this.phantomOffset1 = -300; this.phantomOffset2 = 300;
    });

    // === 🎬 阶段 5：翻转揭晓 ===
    const flipDuration = this.getFlipDurationByRarity();

    // 🌟 SSR/UR 专属炫酷特效
    if (this.rarityLevel >= 5) {
      setTimeout(() => {
        // 1. 全屏闪光
        this.flashColor = this.rarityLevel === 6 ? '#FFD700' : '#FF4500'; // UR金光，SSR红光
        animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
          this.flashOpacity = 0.8;
        });
        setTimeout(() => {
          animateTo({ duration: 800, curve: Curve.EaseIn }, () => {
            this.flashOpacity = 0;
          });
        }, 300);

        // 2. 圣光降临 (God Ray)
        this.godRayOpacity = 0;
        this.godRayRotate = 0;
        
        // 启动圣光旋转 (持续旋转)
        animateTo({ duration: 10000, curve: Curve.Linear, iterations: -1, playMode: PlayMode.Normal }, () => {
            this.godRayRotate = 360;
        });

        // 圣光渐显
        animateTo({ duration: 1000, curve: Curve.EaseOut }, () => {
          this.godRayOpacity = 1;
        });

        // 3. 星光粒子浮现
        this.starScale = 0;
        animateTo({ duration: 800, curve: curves.springMotion(0.6, 0.8) }, () => {
          this.starScale = 1.5;
        });
      }, flipDuration / 2 - 200); // 在翻转快结束时触发
    }

    await this.asyncAnimateTo(flipDuration, curves.springMotion(0.6, 0.8), () => {
      this.angle = 180;
      this.mainScale = 1.0;
      this.floatOffsetY = 0;
      this.shadowRadius = 20;
      this.shadowOffsetY = 10;
    });

    // 普通卡牌不需要光晕常驻，或者仅保留微弱光晕
    await this.asyncAnimateTo(500, Curve.EaseOut, () => {
      // 只有 SSR/UR 保留圣光，其他无额外光晕
      this.shadowColor = this.rarityLevel >= 5 ? this.rarityColor : 'rgba(0,0,0,0.2)'; 
      this.shadowRadius = this.rarityLevel >= 5 ? 30 : 10;
      this.shadowOffsetY = 0;
    });

    this.isFlipped = true;

    // 🌟 启动边框绘制动画
    this.borderOpacity = 1;
    animateTo({ duration: 2500, curve: Curve.EaseOut }, () => {
      this.borderProgress = 4;
    });

    this.isAnimating = false; // 解锁
    this.startBreathingAnimation();

    if (this.currentCard) {
      this.goldQuote = this.manager.createGoldQuote(this.currentCard);
      this.dailyTask = this.manager.createDailyTask(this.currentCard);
      await this.manager.setTodayAffirmations(this.goldQuote, this.dailyTask);
      this.updateForm(this.currentCard);
    }

    animateTo({ duration: 600 }, () => { this.showResultText = true; });
  }

  // 🟢 跳转到分享预览页
  handleShare() {
    if (!this.currentCard) return;
    router.pushUrl({
      url: 'pages/SharePreviewPage',
      params: {
        card: this.currentCard,
        todayDate: this.todayDate,
        todayWeek: this.todayWeek,
        goldQuote: this.goldQuote,
        privacyMode: this.privacyMode
      }
    });
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
    let currentUser = this.userManager.getCurrentUser();

    if (!this.userManager.isLoggedIn()) {
      try {
        promptAction.showToast({ message: '正在连接华为账号...', duration: 1500 });
        currentUser = await this.userManager.login(this.context);
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
        if (success) {
          promptAction.showToast({ message: '✅ 备份成功！' });
        } else {
          promptAction.showToast({ message: '❌ 备份失败' });
        }
      } else {
        promptAction.showToast({ message: '正在下载恢复...', duration: 2000 });
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

  async handleAIAnalyze() {
    // ... 调用 SpreadPage 同款的 AI 分析逻辑，或者跳转到 SpreadPage
    router.pushUrl({ url: 'pages/SpreadPage' });
  }

  // 🟢 补回 loadGalleryData
  async loadGalleryData() {
    this.isGallerySheetOpen = true;
    this.isEnergySheetOpen = false;
    this.galleryList = await this.manager.getGallery();
    this.collectionProgress = Math.round((this.galleryList.length / TAROT_DECK.length) * 100);
  }

  // 🟢 补回 isCollected
  isCollected(id: number): boolean {
    return this.galleryList.some(record => record.cardId === id);
  }

  // 🟢 补回 getCardRarityColor
  getCardRarityColor(id: number): string {
    const record = this.galleryList.find(r => r.cardId === id);
    return record ? record.rarityColor : 'rgba(0,0,0,0.1)';
  }

  // 🟢 新增：获取卡牌稀有度标签
  getCardRarityLabel(id: number): string {
    const record = this.galleryList.find(r => r.cardId === id);
    if (!record || !record.rarityLevel) return 'N';
    const config = RARITY_CONFIG.find(c => c.level === record.rarityLevel);
    return config ? config.label : 'N';
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
          Progress({ value: this.collectionProgress, total: 100, type: ProgressType.Ring }).color('#FB7299').width(44)
          Text(`${this.collectionProgress}%`).fontSize(10).fontColor('#FB7299').fontWeight(FontWeight.Bold)
        }.margin({ right: 32 })
      }.width('100%').padding({ left: 24, right: 24, top: 24, bottom: 10 })
      Divider().color('#F9F9F9').width('90%')
      Grid() {
        ForEach(TAROT_DECK, (card: TarotCard) => {
          GridItem() {
            Column() {
              if (this.isCollected(card.id)) {
                Stack() {
                  Image(this.getCardImageSource(card.image))
                    .width('100%').aspectRatio(2/3).borderRadius(10)
                    .shadow({ radius: 8, color: this.getCardRarityColor(card.id), offsetY: 2 })
                    .alt($rawfile('card_back.png'))
                  
                  // 🌟 稀有度标签
                  Text(this.getCardRarityLabel(card.id))
                    .fontSize(10).fontWeight(FontWeight.Bold).fontColor(Color.White)
                    .backgroundColor(this.getCardRarityColor(card.id))
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius({ topLeft: 8, bottomRight: 8 })
                    .position({ x: 0, y: 0 })
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
        Button("去观看").backgroundColor('#E1F5FE').fontColor('#0277BD').height(32).fontSize(12).onClick(() => this.handleRecharge(10))
      }.width('90%').padding(16).backgroundColor('#FAFAFA').borderRadius(16).margin({ bottom: 12 })

      Row() {
        Column() { Text("心力礼包").fontSize(16).fontWeight(FontWeight.Bold); Text("获得 +100 心力").fontSize(12).fontColor('#999').margin({ top: 4 }) }.alignItems(HorizontalAlign.Start)
        Blank()
        Button("¥ 6.00").backgroundColor('#FCE4EC').fontColor('#FB7299').height(32).fontSize(12).onClick(() => this.handleRecharge(100))
      }.width('90%').padding(16).backgroundColor('#FAFAFA').borderRadius(16)
    }
    .width('100%').height('50%').backgroundColor(Color.White).borderRadius({ topLeft: 24, topRight: 24 })
  }

  @Builder
  DeckSheetBuilder() {
    DeckSelectionSheet({ isOpen: $isDeckSheetOpen })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column() {
          Row() {
            // 左侧显示用户头像或登录提示
            Row() {
              if (this.currentUserInfo && this.currentUserInfo.avatar) {
                // 头像使用 getCardImageSource 兼容本地/网络
                Image(this.getCardImageSource(this.currentUserInfo.avatar))
                  .width(32).height(32).borderRadius(16).margin({ right: 8 })
                  .alt($r('app.media.startIcon'))
              } else {
                // 未登录显示默认图标
                Text('👤').fontSize(24).margin({ right: 8 })
              }

              if (this.currentUserInfo) {
                Text(this.currentUserInfo.nickname || '用户')
                  .fontSize(14).fontColor('#555').fontWeight(FontWeight.Medium)
              } else {
                Text('登录').fontSize(14).fontColor('#666')
              }
            }
            .backgroundColor('rgba(255,255,255,0.85)')
            .backdropBlur(10)
            .padding({ left: 8, right: 12, top: 6, bottom: 6 })
            .borderRadius(20)
            .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
            .onClick(() => this.handleUserClick())

            Blank()

            // 云同步入口
            Button({ type: ButtonType.Circle }) { Text('☁️').fontSize(16) }
            .width(36).height(36)
            .backgroundColor('rgba(255,255,255,0.85)')
            .backdropBlur(10)
            .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
            .margin({ right: 12 })
            .onClick(() => {
              // 点击时手动触发一次同步检查
              promptAction.showToast({ message: '正在同步云端数据...', duration: 1500 });
              CloudService.autoSave();
              void (async () => {
                const restored = await CloudService.autoRestore();
                if(restored) {
                  this.checkState();
                  promptAction.showToast({ message: '✅ 同步完成' });
                }
              })();
            })

            Row() {
              Text('⚡').fontSize(14)
              Text(`${this.currentEnergy}`).fontSize(14).fontColor('#FB7299').fontWeight(FontWeight.Bold).margin({left: 2})
            }
            .backgroundColor('rgba(255,255,255,0.85)')
            .backdropBlur(10)
            .padding({left: 12, right: 12, top: 8, bottom: 8})
            .borderRadius(18)
            .margin({right: 12})
            .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
            .onClick(() => this.handleBuyVip())

            Button({ type: ButtonType.Circle }) { Text('🏛️').fontSize(18) }
            .width(40).height(40)
            .backgroundColor('rgba(255,255,255,0.9)')
            .backdropBlur(10)
            .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
            .onClick(() => this.loadGalleryData())
          }.width('100%').padding({ left: 24, right: 24, top: 16 }).height(60)

          Blank().height(20)

          Stack() {
            Circle({ width: 260, height: 260 }).fill('#FFFFFF').opacity(0.4)
              .scale({ x: this.mysteryScale, y: this.mysteryScale }).blur(50)

            if (this.rarityLevel >= 5) {
              this.GodRayBuilder()
            }

            // 装饰性牌堆使用 CARD_BACK_URL
            // 👻 幻影牌 1 (左远)
            Image(CARD_BACK_URL).width('100%').height('100%').borderRadius(16)
              .scale({ x: this.deckScale, y: this.deckScale })
              .translate({ x: this.phantomOffset1 })
              .rotate({ z: 1, angle: this.phantomAngle1 })
              .opacity(this.phantomOpacity)
              .alt($rawfile('card_back.png'))

            // 👻 幻影牌 2 (右远)
            Image(CARD_BACK_URL).width('100%').height('100%').borderRadius(16)
              .scale({ x: this.deckScale, y: this.deckScale })
              .translate({ x: this.phantomOffset2 })
              .rotate({ z: 1, angle: this.phantomAngle2 })
              .opacity(this.phantomOpacity)
              .alt($rawfile('card_back.png'))

            // 原有装饰牌 1 (左)
            Image(CARD_BACK_URL).width('100%').height('100%').borderRadius(16)
              .scale({ x: this.deckScale, y: this.deckScale }).translate({ x: this.deckOffset1 }).rotate({ z: 1, angle: this.deckAngle1 }).opacity(this.deckOpacity)
              .alt($rawfile('card_back.png'))

            // 原有装饰牌 2 (右)
            Image(CARD_BACK_URL).width('100%').height('100%').borderRadius(16)
              .scale({ x: this.deckScale, y: this.deckScale }).translate({ x: this.deckOffset2 }).rotate({ z: 1, angle: this.deckAngle2 }).opacity(this.deckOpacity)
              .alt($rawfile('card_back.png'))

            // 翻转动画的背面使用 CARD_BACK_URL
            Image(CARD_BACK_URL).width('100%').height('100%').borderRadius(16)
              .rotate({ x: 0, y: 1, z: 0, angle: this.angle }).opacity(this.angle < 90 ? 1 : 0)
              .alt($rawfile('card_back.png'))

            if (this.currentCard) {
              // 使用通用方法获取图片
              Image(this.getCardImageSource(this.currentCard.image))
                .width('100%').height('100%').borderRadius(16)
                .rotate({ x: 0, y: 1, z: 0, angle: this.angle - 180 }).opacity(this.angle >= 90 ? 1 : 0)
                .alt($rawfile('card_back.png')) // 添加加载占位图
              
              // 🌟 绘制边框动画 (跟随卡牌翻转)
              if (this.isFlipped) {
                Column() {
                  this.ComplexBorderBuilder()
                }
                .width('100%').height('100%')
                .rotate({ x: 0, y: 1, z: 0, angle: this.angle - 180 })
                .opacity(this.angle >= 90 ? 1 : 0)
                .hitTestBehavior(HitTestMode.None)
              }
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
              Row() {
                // 🌟 结果页稀有度标签
                Text(this.rarityLabel)
                  .fontSize(14).fontWeight(FontWeight.Bold).fontColor(Color.White)
                  .backgroundColor(this.rarityColor)
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .borderRadius(6)
                  .margin({ right: 8 })

                Text(this.currentCard.name).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#333333')
              }.margin({bottom: 4})

              Text(this.currentCard.name_en).fontSize(14).fontColor('#AAAAAA').fontStyle(FontStyle.Italic).margin({bottom: 16})
              Text(this.currentCard.desc).fontSize(16).fontColor('#555555').textAlign(TextAlign.Center).lineHeight(26).padding({ left: 20, right: 20 }).opacity(0.9)
              Divider().color('rgba(0,0,0,0.05)').width('80%').margin({top: 24, bottom: 24})

              // 1. 主要操作：深度解读 (强调色，占据C位)
              Button("🔮 深度解读")
                .backgroundColor('#87CEEB') // 天空蓝，治愈系
                .linearGradient({
                  direction: GradientDirection.Right,
                  colors: [['#89CFF0', 0], ['#B0E0E6', 1]]
                })
                .fontColor(Color.White)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .height(56)
                .width('100%')
                .borderRadius(28)
                .shadow({ radius: 15, color: 'rgba(137, 207, 240, 0.4)', offsetY: 5 })
                .margin({ bottom: 16 })
                .stateStyles({ pressed: { .scale({ x: 0.98, y: 0.98 }) }, normal: { .scale({ x: 1, y: 1 }) } })
                .onClick(() => router.pushUrl({ url: 'pages/SpreadPage' }))

              // 2. 次要操作：分享 & 记录 (并排，轻量化)
              Row({ space: 12 }) {
                Button("✨ 分享")
                  .backgroundColor('#F5F7FA')
                  .fontColor('#555')
                  .height(48)
                  .layoutWeight(1)
                  .borderRadius(24)
                  .stateStyles({ pressed: { .scale({ x: 0.96, y: 0.96 }) }, normal: { .scale({ x: 1, y: 1 }) } })
                  .onClick(() => this.handleShare())

                if (this.moodIndex === -1) {
                  Button("📝 记录心情")
                    .backgroundColor('#FFF0F5')
                    .fontColor('#DB7093') // 苍紫罗兰色
                    .height(48)
                    .layoutWeight(1)
                    .borderRadius(24)
                    .stateStyles({ pressed: { .scale({ x: 0.96, y: 0.96 }) }, normal: { .scale({ x: 1, y: 1 }) } })
                    .onClick(() => router.pushUrl({ url: 'pages/MoodPage' }))
                } else {
                  // 如果已记录，显示查看按钮或占位
                  Button("✅ 已记录")
                    .backgroundColor('#F0FFF0')
                    .fontColor('#3CB371')
                    .height(48)
                    .layoutWeight(1)
                    .borderRadius(24)
                    .stateStyles({ pressed: { .scale({ x: 0.96, y: 0.96 }) }, normal: { .scale({ x: 1, y: 1 }) } })
                    .onClick(() => router.pushUrl({ url: 'pages/MoodPage' }))
                }
              }
              .width('100%')
              .margin({ bottom: 20 })

              // 3. 底部功能：补充心力 & 牌组
              Row() {
                Row() {
                  Text("⚡ 补充心力").fontSize(14).fontColor('#AAA').margin({ right: 4 })
                  Text("获得更多指引").fontSize(12).fontColor('#CCC')
                }
                .layoutWeight(1)
                .justifyContent(FlexAlign.Center)
                .onClick(() => this.handleBuyVip())

                Divider().vertical(true).height(20).color('#DDD').margin({ left: 8, right: 8 })

                Row() {
                  Text("🎨 更换牌组").fontSize(14).fontColor('#AAA')
                }
                .layoutWeight(1)
                .justifyContent(FlexAlign.Center)
                .onClick(() => {
                   animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
                     this.isDeckSheetOpen = true;
                   })
                })
              }
              .width('100%')
              .height(40)
              .backgroundColor('rgba(255,255,255,0.5)')
              .borderRadius(20)
            }
            .width('90%').backgroundColor('rgba(255,255,255,0.90)').backdropBlur(40).borderRadius(32).padding({ left: 24, right: 24, top: 32, bottom: 24 })
            .shadow({ radius: 40, color: 'rgba(0, 0, 0, 0.08)', offsetY: 10 })
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

      if (this.isDeckSheetOpen) {
        Column() {
          Column()
            .width('100%').height('100%').backgroundColor('rgba(0,0,0,0.4)')
            .onClick(() => { animateTo({ duration: 300, curve: Curve.EaseOut }, () => { this.isDeckSheetOpen = false; }); })
            .transition({ opacity: 0 })
            .zIndex(100)
          Column() { this.DeckSheetBuilder() }
          .width('100%')
          .transition({ type: TransitionType.Insert, translate: { y: '100%' } })
          .zIndex(101).position({ y: '35%' }).constraintSize({ maxWidth: 480 }) // Higher position
        }.width('100%').height('100%').zIndex(200)
      }

      // 🌟 全屏闪光 (Flash Effect)
      Rect().width('100%').height('100%').fill(this.flashColor).opacity(this.flashOpacity)
        .hitTestBehavior(HitTestMode.None)
        .zIndex(999)
    }
    .width('100%').height('100%')
    .linearGradient({ direction: GradientDirection.Top, colors: [['#FFF9F9', 0.0], ['#FFF0F5', 1.0]] })
  }
}