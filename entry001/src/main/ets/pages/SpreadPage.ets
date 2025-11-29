import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { FortuneManager } from '../common/FortuneManager';
import { TarotCard } from '../model/TarotData';
import curves from '@ohos.curves';
import promptAction from '@ohos.promptAction';
import { AIService } from '../common/AIService';
import { EnergyManager } from '../common/EnergyManager';
import { BottomNavBar } from '../common/BottomNavBar';

// 🌟 牌阵定义接口
interface SpreadPosition {
  x: number;
  y: number;
  rotate: number;
  label: string;
  zIndex: number;
}

interface SpreadDef {
  id: string;
  name: string;
  description: string;
  cardCount: number;
  positions: SpreadPosition[];
}

// 🌟 预设牌阵数据
const SPREADS: SpreadDef[] = [
  {
    id: 'celtic_cross',
    name: '凯尔特十字',
    description: '最经典的塔罗牌阵，全方位解析现状、阻碍、潜意识、过去、未来及最终结果。适用于重大决策与深度自我探索。',
    cardCount: 10,
    positions: [
      { x: -60, y: 0, rotate: 0, label: '1. 核心现状', zIndex: 1 },
      { x: -60, y: 0, rotate: 90, label: '2. 阻碍/挑战', zIndex: 2 },
      { x: -60, y: 110, rotate: 0, label: '3. 潜意识/基础', zIndex: 1 },
      { x: -150, y: 0, rotate: 0, label: '4. 过去的影响', zIndex: 1 },
      { x: -60, y: -110, rotate: 0, label: '5. 最高愿景', zIndex: 1 },
      { x: 30, y: 0, rotate: 0, label: '6. 即将发生的未来', zIndex: 1 },
      { x: 120, y: 120, rotate: 0, label: '7. 自我态度', zIndex: 1 },
      { x: 120, y: 40, rotate: 0, label: '8. 环境影响', zIndex: 1 },
      { x: 120, y: -40, rotate: 0, label: '9. 希望与恐惧', zIndex: 1 },
      { x: 120, y: -120, rotate: 0, label: '10. 最终结果', zIndex: 1 }
    ]
  },
  {
    id: 'tree_of_life',
    name: '生命之树',
    description: '基于卡巴拉生命之树的深度灵性牌阵，探索身心灵的整体状态与成长路径。',
    cardCount: 10,
    positions: [
      { x: 0, y: -140, rotate: 0, label: '1. 精神源头', zIndex: 1 },
      { x: 60, y: -110, rotate: 0, label: '2. 智慧/阳性', zIndex: 1 },
      { x: -60, y: -110, rotate: 0, label: '3. 理解/阴性', zIndex: 1 },
      { x: 60, y: -50, rotate: 0, label: '4. 慈悲', zIndex: 1 },
      { x: -60, y: -50, rotate: 0, label: '5. 力量', zIndex: 1 },
      { x: 0, y: 0, rotate: 0, label: '6. 美/核心', zIndex: 1 },
      { x: 60, y: 50, rotate: 0, label: '7. 胜利', zIndex: 1 },
      { x: -60, y: 50, rotate: 0, label: '8. 荣耀', zIndex: 1 },
      { x: 0, y: 100, rotate: 0, label: '9. 基础', zIndex: 1 },
      { x: 0, y: 150, rotate: 0, label: '10. 王国/现实', zIndex: 1 }
    ]
  }
];

@Entry
@Component
struct SpreadPage {
  // === 状态变量 ===
  @State selectedSpreadId: string = '';
  @State currentSpread: SpreadDef | null = null;
  @State cards: TarotCard[] = [];
  @State isDrawing: boolean = false; // 是否正在抽牌过程中（UI状态）
  @State drawnCount: number = 0; // 已抽取的数量

  // 动画相关
  @State cardOpacities: number[] = []; // 控制每张牌的显示
  @State cardScales: number[] = [];
  @State deckScale: number = 1.0;

  // 能量与服务
  @State currentEnergy: number = 0;
  @State isFreeAnalysis: boolean = false;

  private manager = FortuneManager.getInstance();
  private energyManager = EnergyManager.getInstance();
  private context = getContext(this) as common.UIAbilityContext;

  // 智能图片源处理方法
  getCardImageSource(url: string): ResourceStr {
    if (url.startsWith('http')) {
      return url;
    }
    return $rawfile(url);
  }

  async aboutToAppear() {
    await this.energyManager.init(this.context);
    this.currentEnergy = this.energyManager.getEnergy();
    this.isFreeAnalysis = await this.manager.isDailyDeepAnalysisFree();
  }

  onPageShow() {
    this.currentEnergy = this.energyManager.getEnergy();
  }

  // 选择牌阵
  selectSpread(spread: SpreadDef) {
    this.currentSpread = spread;
    this.selectedSpreadId = spread.id;
    this.resetDrawingBoard();
  }

  // 重置抽牌台
  resetDrawingBoard() {
    if (!this.currentSpread) return;
    this.cards = [];
    this.drawnCount = 0;
    this.cardOpacities = new Array(this.currentSpread.cardCount).fill(0);
    this.cardScales = new Array(this.currentSpread.cardCount).fill(0.5);
    this.isDrawing = true;
  }

  // 抽取下一张牌
  async drawNextCard() {
    if (!this.currentSpread || this.drawnCount >= this.currentSpread.cardCount) return;

    // 震动反馈
    // try { vibrator.startVibration({ type: 'time', duration: 50 }, { id: 0, usage: 'touch' }); } catch(e) {}

    // 动画效果：牌堆点击
    animateTo({ duration: 100, curve: Curve.EaseOut }, () => {
      this.deckScale = 0.9;
    });
    setTimeout(() => {
      animateTo({ duration: 200, curve: curves.springMotion(0.6, 0.8) }, () => {
        this.deckScale = 1.0;
      });
    }, 100);

    // 抽牌逻辑
    const newCard = await this.manager.drawRandomCard();
    this.cards.push(newCard);
    const currentIndex = this.drawnCount;
    
    // 动画：牌飞入位置
    animateTo({ duration: 600, curve: curves.springMotion(0.6, 0.7) }, () => {
      this.cardOpacities[currentIndex] = 1;
      this.cardScales[currentIndex] = 1;
    });

    this.drawnCount++;
  }

  // 完成抽牌，开始分析
  async handleAnalyze() {
    if (this.currentEnergy < AIService.COST_DEEP_ANALYSIS && !this.isFreeAnalysis) {
      promptAction.showToast({ message: '心力不足，请先补充', duration: 2000 });
      return;
    }

    if (!this.currentSpread) return;

    // 获取今日心情作为背景信息
    const todayMood = await this.manager.getTodayMood();

    // 跳转到结果页
    router.pushUrl({
      url: 'pages/DeepAnalysisResultPage',
      params: {
        cards: this.cards,
        spreadType: this.currentSpread.id, // 传递牌阵类型
        spreadName: this.currentSpread.name,
        isFree: this.isFreeAnalysis,
        todayMood: todayMood
      }
    });
  }

  // 返回选择页
  handleBack() {
    this.isDrawing = false;
    this.currentSpread = null;
    this.selectedSpreadId = '';
  }

  @Builder
  SpreadSelector() {
    Column() {
      Text('选择深度解读牌阵')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .margin({ top: 40, bottom: 20 })

      List({ space: 20 }) {
        ForEach(SPREADS, (spread: SpreadDef) => {
          ListItem() {
            Column() {
              Text(spread.name)
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFD700')
                .margin({ bottom: 8 })
              
              Text(spread.description)
                .fontSize(14)
                .fontColor('rgba(255,255,255,0.7)')
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .lineHeight(20)
              
              Row() {
                Text(`${spread.cardCount} 张牌`)
                  .fontSize(12)
                  .fontColor('rgba(255,255,255,0.5)')
                  .padding({ top: 4, bottom: 4, left: 8, right: 8 })
                  .backgroundColor('rgba(255,255,255,0.1)')
                  .borderRadius(4)
                  .margin({ top: 12 })
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)
            }
            .width('100%')
            .padding(20)
            .backgroundColor('rgba(255,255,255,0.08)')
            .borderRadius(16)
            .backdropBlur(10)
            .border({ width: 1, color: 'rgba(255,255,255,0.1)' })
            .onClick(() => this.selectSpread(spread))
          }
        })
      }
      .width('90%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  DrawingBoard() {
    Stack() {
      // 1. 背景/返回按钮
      Column() {
        Row() {
          Text('< 返回')
            .fontColor('rgba(255,255,255,0.8)')
            .fontSize(16)
            .onClick(() => this.handleBack())
          
          Blank()
          
          Text(this.currentSpread?.name)
            .fontColor('#FFFFFF')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 10, bottom: 10 })
        .height(50)
        .zIndex(10)
      }
      .position({ x: 0, y: 0 })

      // 2. 牌阵布局区域 (居中)
      if (this.currentSpread) {
        Stack() {
          ForEach(this.currentSpread.positions, (pos: SpreadPosition, index: number) => {
            // 占位框 (虚线)
            Column() {
              Text((index + 1).toString())
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('rgba(255,255,255,0.1)')
            }
            .width(50).height(80) // 小尺寸以适应屏幕
            .justifyContent(FlexAlign.Center)
            .border({ width: 1, color: 'rgba(255,255,255,0.15)', style: BorderStyle.Dashed })
            .borderRadius(4)
            .position({ x: '50%', y: '50%' })
            .translate({ x: pos.x - 25, y: pos.y - 40 }) // 居中修正
            .rotate({ angle: pos.rotate })
            .zIndex(0)

            // 实际卡牌 (如果已抽取)
            if (index < this.cards.length) {
              Image(this.getCardImageSource(this.cards[index].image))
                .width(50).height(80)
                .borderRadius(4)
                .position({ x: '50%', y: '50%' })
                .translate({ x: pos.x - 25, y: pos.y - 40 })
                .rotate({ angle: pos.rotate })
                .zIndex(pos.zIndex)
                .opacity(this.cardOpacities[index])
                .scale({ x: this.cardScales[index], y: this.cardScales[index] })
                .shadow({ radius: 5, color: 'rgba(0,0,0,0.5)' })
            }
          })
        }
        .width('100%')
        .height('100%')
        // 整体缩放以适应不同屏幕
        .scale({ x: 0.9, y: 0.9 }) 
      }

      // 3. 底部操作区
      Column() {
        if (this.currentSpread && this.drawnCount < this.currentSpread.cardCount) {
          // 抽牌按钮 (牌堆样式)
          Stack() {
            Image($rawfile('card_back.png'))
              .width(80).height(120)
              .borderRadius(8)
              .shadow({ radius: 10, color: 'rgba(0,0,0,0.3)' })
              .rotate({ angle: -5 })
            
            Image($rawfile('card_back.png'))
              .width(80).height(120)
              .borderRadius(8)
              .shadow({ radius: 10, color: 'rgba(0,0,0,0.3)' })
              .rotate({ angle: 5 })
            
            Column() {
              Text('点击抽牌')
                .fontColor('#FFFFFF')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .textShadow({ radius: 2, color: 'rgba(0,0,0,0.5)' })
            }
            .width(80).height(120)
            .justifyContent(FlexAlign.Center)
          }
          .scale({ x: this.deckScale, y: this.deckScale })
          .onClick(() => this.drawNextCard())
          .margin({ bottom: 40 })
        } else {
          // 分析按钮
          Button(this.isFreeAnalysis ? '开始深度解读 (免费)' : `开始深度解读 (消耗 ${AIService.COST_DEEP_ANALYSIS} 心力)`)
            .backgroundColor('#FF69B4')
            .fontColor(Color.White)
            .width('80%')
            .height(50)
            .borderRadius(25)
            .shadow({ radius: 10, color: 'rgba(255, 105, 180, 0.4)', offsetY: 5 })
            .onClick(() => this.handleAnalyze())
            .margin({ bottom: 40 })
            .transition({ type: TransitionType.Insert, opacity: 0, translate: { y: 20 } })
        }
      }
      .width('100%')
      .position({ y: '100%' })
      .translate({ y: -100 }) // 抬高
    }
    .width('100%')
    .height('100%')
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#1A1A2E')
        // .backgroundImage($rawfile('bg_stars.png')) 

        .backgroundImageSize(ImageSize.Cover)

      // 主内容
      if (this.isDrawing) {
        this.DrawingBoard()
      } else {
        this.SpreadSelector()
      }

      BottomNavBar({ current: 'spread' })
    }
    .width('100%')
    .height('100%')
  }
}
