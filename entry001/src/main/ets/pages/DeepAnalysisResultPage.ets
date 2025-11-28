import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { AIService, ChatMessage } from '../common/AIService';
import { EnergyManager } from '../common/EnergyManager';
import { MoodToday } from '../common/FortuneManager';
import { TarotCard } from '../model/TarotData';
import curves from '@ohos.curves';

@Entry
@Component
struct DeepAnalysisResultPage {
  @State cards: TarotCard[] = [];
  @State resultText: string = "";
  @State isAnalyzing: boolean = true;
  @State showButton: boolean = false;
  
  // 动画相关
  @State opacityValues: number[] = [0, 0, 0];
  @State contentOpacity: number = 0;
  
  private context = getContext(this) as common.UIAbilityContext;
  private energyManager = EnergyManager.getInstance();
  private scroller: Scroller = new Scroller();

  async aboutToAppear() {
    await this.energyManager.init(this.context);
    
    const params = router.getParams() as Record<string, Object>;
    if (params && params['cards']) {
      this.cards = params['cards'] as TarotCard[];
      const todayMood = params['todayMood'] as MoodToday;
      
      // 启动卡片入场动画
      this.animateCardsEntry();
      
      // 开始 AI 分析
      this.startAnalysis(todayMood);
    }
  }

  animateCardsEntry() {
    this.cards.forEach((_, index) => {
      setTimeout(() => {
        animateTo({ duration: 600, curve: Curve.EaseOut }, () => {
          this.opacityValues[index] = 1;
        });
      }, index * 200);
    });
  }

  async startAnalysis(todayMood: MoodToday) {
    const initialPrompt = AIService.createInitialPrompt(this.cards, todayMood);
    const userMsg: ChatMessage = { role: 'user', content: initialPrompt };

    try {
      // 流式效果模拟（因为 requestChat 目前是一次性返回，我们这里先获取全文，再模拟打字机）
      const fullText = await AIService.requestChat([userMsg], this.context, true);
      this.isAnalyzing = false;
      this.typewriterEffect(fullText);
    } catch (error) {
      this.isAnalyzing = false;
      this.resultText = "连接宇宙信号失败，请稍后重试...";
      this.showButton = true;
    }
  }

  typewriterEffect(fullText: string) {
    let index = 0;
    this.contentOpacity = 1;
    
    const intervalId = setInterval(() => {
      if (index < fullText.length) {
        this.resultText += fullText.charAt(index);
        index++;
        this.scroller.scrollEdge(Edge.Bottom);
      } else {
        clearInterval(intervalId);
        // 显示底部按钮
        animateTo({ duration: 500 }, () => {
          this.showButton = true;
        });
      }
    }, 30);
  }

  getCardImageSource(url: string): ResourceStr {
    if (url.startsWith('http')) {
      return url;
    }
    return $rawfile(url);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#1A1A2E')
        .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [['#1A1A2E', 0.0], ['#2E1A4E', 1.0]]
        })

      Column() {
        // 顶部导航栏（透明）
        Row() {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            Text('❮').fontSize(18).fontColor('#FFFFFF')
          }
          .width(40)
          .height(40)
          .backgroundColor('rgba(255,255,255,0.1)')
          .onClick(() => router.back())
          
          Text('深度启示')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .margin({ right: 40 }) // 平衡左侧按钮
        }
        .width('100%')
        .height(50)
        .padding({ left: 20, right: 20 })
        .margin({ top: 10 })

        Scroll(this.scroller) {
          Column() {
            // 1. 三张牌展示区
            Row({ space: 10 }) {
              ForEach(this.cards, (card: TarotCard, index: number) => {
                Column() {
                  Image(this.getCardImageSource(card.image))
                    .width('100%')
                    .aspectRatio(2/3)
                    .borderRadius(8)
                    .shadow({ radius: 10, color: 'rgba(0,0,0,0.5)', offsetY: 5 })
                  
                  Text(index === 0 ? '过去' : index === 1 ? '现在' : '未来')
                    .fontSize(12)
                    .fontColor('rgba(255,255,255,0.7)')
                    .margin({ top: 8 })
                }
                .layoutWeight(1)
                .opacity(this.opacityValues[index])
                .translate({ y: this.opacityValues[index] === 0 ? 20 : 0 })
                .animation({ duration: 600 })
              })
            }
            .width('100%')
            .padding(20)

            // 2. 解读内容区
            Column() {
              if (this.isAnalyzing) {
                Row() {
                  LoadingProgress()
                    .width(24)
                    .height(24)
                    .color('#FF69B4')
                    .margin({ right: 10 })
                  Text('正在接收宇宙讯息...')
                    .fontSize(16)
                    .fontColor('#FF69B4')
                }
                .margin({ top: 40 })
              } else {
                Text(this.resultText)
                  .fontSize(16)
                  .fontColor('#EEEEEE')
                  .lineHeight(28)
                  .letterSpacing(1)
                  .opacity(this.contentOpacity)
                  .animation({ duration: 500 })
              }
            }
            .width('90%')
            .backgroundColor('rgba(255, 255, 255, 0.05)')
            .borderRadius(16)
            .padding(24)
            .margin({ top: 10, bottom: 100 }) // 底部留白
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')

      // 底部按钮：去倾诉
      if (this.showButton) {
        Column() {
          Button("✨ 去倾诉 (与 AI 对话)")
            .backgroundColor('#FF69B4')
            .fontColor(Color.White)
            .width('80%')
            .height(56)
            .borderRadius(28)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .shadow({ radius: 15, color: 'rgba(255, 105, 180, 0.4)', offsetY: 5 })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/AIChatPage',
                params: {
                  fromDeepAnalysis: true // 标记来源，但不触发自动解读
                }
              });
            })
        }
        .width('100%')
        .padding({ bottom: 40 })
        .transition({ type: TransitionType.Insert, opacity: 0, translate: { y: 30 } })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1A1A2E')
  }
}
