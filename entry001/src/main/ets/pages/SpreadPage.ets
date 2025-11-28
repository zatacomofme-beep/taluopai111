import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { FortuneManager } from '../common/FortuneManager';
import { TarotCard } from '../model/TarotData';
import curves from '@ohos.curves';
import promptAction from '@ohos.promptAction';
import { BusinessError } from '@kit.BasicServicesKit';
import { AIService, ChatMessage } from '../common/AIService';
import { EnergyManager } from '../common/EnergyManager';

import { BottomNavBar } from '../common/BottomNavBar';

@Entry
@Component
struct SpreadPage {
  @State cards: TarotCard[] = [];
  @State cardStates: number[] = [0, 0, 0];
  // 🟢 修复：ResourceStr 类型兼容字符串(URL)和Resource(本地)
  @State cardImages: ResourceStr[] = [$rawfile('card_back.png'), $rawfile('card_back.png'), $rawfile('card_back.png')];

  // 动画变量
  @State cardAngles: number[] = [0, 0, 0];
  @State cardFlightScales: number[] = [1, 1, 1];
  @State cardFloatOffsets: number[] = [0, 0, 0];
  @State cardFloatAngles: number[] = [0, 0, 0];
  @State cardClickScales: number[] = [1, 1, 1];

  // 文字
  @State displayNames: string[] = ['', '', ''];
  @State displayMeanings: string[] = ['', '', ''];
  @State cardTextOpacities: number[] = [0, 0, 0];
  @State currentReadingCardIndex: number = -1;

  // AI & 能量
  @State currentEnergy: number = 0;
  @State guideScale: number = 1.0;

  private manager = FortuneManager.getInstance();
  private energyManager = EnergyManager.getInstance();
  private positions = ['过去 · The Past', '现在 · The Present', '未来 · The Future'];
  private context = getContext(this) as common.UIAbilityContext;

  // 🟢 新增：智能图片源处理方法
  getCardImageSource(url: string): ResourceStr {
    if (url.startsWith('http')) {
      return url; // 网络图片直接返回字符串
    }
    return $rawfile(url); // 本地图片包裹 $rawfile
  }

  async aboutToAppear() {
    this.cards = this.manager.drawThreeSpread();
    await this.energyManager.init(this.context);
    this.currentEnergy = this.energyManager.getEnergy();
    this.startGuideAnimation();
  }

  startGuideAnimation() {
    animateTo({
      duration: 1000,
      curve: Curve.EaseInOut,
      iterations: -1,
      playMode: PlayMode.Alternate
    }, () => {
      this.guideScale = 1.05;
    });
  }

  startTypewriter(index: number) {
    const card = this.cards[index];
    const fullMeaning = card.meaning;
    this.displayNames[index] = card.name;
    let charIndex = 0;
    let intervalID = setInterval(() => {
      if (charIndex < fullMeaning.length) {
        this.displayMeanings[index] += fullMeaning.charAt(charIndex);
        charIndex++;
      } else {
        clearInterval(intervalID);
      }
    }, 60);
  }

  startBreathing(index: number) {
    const delay = index * 150;
    animateTo({ duration: 2000, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate, delay: delay }, () => { this.cardFloatOffsets[index] = -8; });
    animateTo({ duration: 3000, curve: Curve.Smooth, iterations: -1, playMode: PlayMode.Alternate, delay: delay + 500 }, () => { this.cardFloatAngles[index] = 1; });
  }

  playClickFeedback(index: number) {
    animateTo({ duration: 100, curve: Curve.EaseOut }, () => { this.cardClickScales[index] = 0.95; });
    setTimeout(() => { animateTo({ duration: 400, curve: curves.springMotion(0.5, 0.6) }, () => { this.cardClickScales[index] = 1.0; }); }, 100);
  }

  handleCardClick(index: number) {
    if (index > 0 && this.cardStates[index - 1] !== 2) {
      promptAction.showToast({ message: `请先翻开「${this.positions[index - 1].split('·')[0].trim()}」的牌`, duration: 2000 });
      return;
    }
    if (this.cardStates[index] === 2) { this.playClickFeedback(index); return; }
    if (this.cardStates[index] !== 0) return;

    this.cardStates[index] = 1;
    animateTo({ duration: 400, curve: curves.springMotion(0.6, 0.8) }, () => { this.cardAngles[index] = 90; this.cardFlightScales[index] = 1.15; });

    setTimeout(() => {
      // 🟢 修复：这里不再强制包裹 $rawfile，而是让 Image 组件自己处理
      // 实际上这行可能不需要，因为 build 里面是直接读 cards 数据的，但为了逻辑严谨保留
      this.cardImages[index] = this.cards[index].image;

      animateTo({ duration: 500, curve: curves.springMotion(0.5, 0.7) }, () => { this.cardAngles[index] = 180; this.cardFlightScales[index] = 1.0; });
      setTimeout(() => {
        this.cardStates[index] = 2;
        this.currentReadingCardIndex = index;
        this.startBreathing(index);
        animateTo({ duration: 400 }, () => { this.cardTextOpacities[index] = 1; });
        this.startTypewriter(index);
      }, 300);
    }, 400);
  }

  async handleAIAnalyze() {
    this.currentEnergy = this.energyManager.getEnergy();

    if (this.currentEnergy < AIService.COST_DEEP_ANALYSIS) {
      promptAction.showToast({ message: '心力不足，请先补充', duration: 2000 });
      return;
    }

    const todayMood = await this.manager.getTodayMood();
    
    // 跳转到 深度解读结果页面
    router.pushUrl({
      url: 'pages/DeepAnalysisResultPage',
      params: {
        cards: this.cards,
        todayMood: todayMood
      }
    });
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // 标题栏
        Row() {
          Text('时光流 · 三牌阵').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
            .layoutWeight(1).textAlign(TextAlign.Center)
        }
        .width('100%')
        .height(50)
        .padding({ left: 20, right: 20 })
        .margin({ top: 10, bottom: 10 })
        .backgroundColor('#1A1A2E') // 保持背景色一致，防止滚动内容透出
        .zIndex(1)

        Column() {
          // 引导提示
          if (this.currentReadingCardIndex < 2) {
            Text('👇 点击下方卡牌，揭示命运指引')
              .fontSize(14)
              .fontColor('rgba(255,255,255,0.6)')
              .margin({ bottom: 10, top: 10 })
              .animation({ duration: 300 })
          }

          // 卡牌区域 - 水平排列
          Row({ space: 10 }) {
            ForEach([0, 1, 2], (index: number) => {
              Column() {
                Stack() {
                  Image($rawfile('card_back.png'))
                    .width('100%').height('100%').borderRadius(8)
                    .rotate({ x: 0, y: 1, z: 0, angle: this.cardAngles[index] })
                    .opacity(this.cardAngles[index] < 90 ? 1 : 0)

                  Image(this.getCardImageSource(this.cards[index].image))
                    .width('100%').height('100%').borderRadius(8)
                    .rotate({ x: 0, y: 1, z: 0, angle: this.cardAngles[index] - 180 })
                    .opacity(this.cardAngles[index] >= 90 ? 1 : 0)
                    .scale({ x: 1, y: this.cardFlightScales[index] })
                    .alt($rawfile('card_back.png'))
                }
                .width('100%').aspectRatio(2/3)
                .shadow({ radius: 10, color: 'rgba(0,0,0,0.4)', offsetY: 5 })
                .translate({ y: this.cardFloatOffsets[index] })
                .rotate({ z: 1, angle: this.cardFloatAngles[index] })
                .scale({ 
                  x: (index === this.currentReadingCardIndex + 1 && this.cardStates[index] === 0) ? this.guideScale : this.cardClickScales[index],
                  y: (index === this.currentReadingCardIndex + 1 && this.cardStates[index] === 0) ? this.guideScale : this.cardClickScales[index]
                })
                .onClick(() => this.handleCardClick(index))
                .animation({ duration: 0 })

                Text(this.positions[index].split('·')[0].trim())
                  .fontSize(12)
                  .fontColor('rgba(255,255,255,0.5)')
                  .margin({ top: 8 })
                  .textAlign(TextAlign.Center)
              }
              .layoutWeight(1)
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Top)

          // 底部滚动文字区域
          Scroll() {
            Column({ space: 16 }) {
              ForEach([0, 1, 2], (index: number) => {
                if (this.cardStates[index] === 2) {
                  Column() {
                    Text(this.positions[index]).fontSize(12).fontColor('#FFD700').margin({ bottom: 4 })
                    Text(this.displayNames[index]).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#FFFFFF').margin({ bottom: 8 })
                    Text(this.displayMeanings[index])
                      .fontSize(14)
                      .fontColor('rgba(255,255,255,0.9)')
                      .lineHeight(24)
                      .opacity(this.cardTextOpacities[index])
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Start)
                  .padding(16)
                  .backgroundColor('rgba(255,255,255,0.1)')
                  .borderRadius(12)
                  .backdropBlur(10)
                }
              })

              if (this.cardStates[2] === 2) {
                Column() {
                  Button(`🔮 深度分析 (消耗 ${AIService.COST_DEEP_ANALYSIS} 心力)`)
                    .backgroundColor('#FF69B4')
                    .fontColor(Color.White)
                    .width('80%')
                    .height(50)
                    .borderRadius(25)
                    .shadow({ radius: 10, color: 'rgba(255, 105, 180, 0.4)', offsetY: 5 })
                    .onClick(() => this.handleAIAnalyze())
                }
                .width('100%')
                .margin({ top: 20, bottom: 40 })
                .transition({ type: TransitionType.Insert, opacity: 0, translate: { y: 20 } })
              }
            }
            .width('100%')
            .padding({ left: 20, right: 20, bottom: 100 })
          }
          .layoutWeight(1)
          .margin({ top: 20 })
          .scrollBar(BarState.Off)
          .align(Alignment.Top)
        }
        .layoutWeight(1)
      }
      .width('100%').height('100%').backgroundColor('#1A1A2E') // 背景色

      BottomNavBar({ current: 'spread' })
    }
    .width('100%').height('100%').backgroundColor('#1A1A2E')
  }
}