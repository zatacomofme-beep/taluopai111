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
  @State spreadType: string = 'time_flow';
  @State spreadName: string = '深度解读';
  
  @State isAnalyzing: boolean = true;
  @State showButton: boolean = false;
  @State isFree: boolean = false;
  
  // 解析后的文本段落 (对应每张牌的解读)
  @State sectionTexts: string[] = [];
  // 总结建议
  @State summaryText: string = "";
  
  // 动画控制：逐步显示
  @State visibleSections: boolean[] = [];
  @State showSummary: boolean = false;
  
  private context = getContext(this) as common.UIAbilityContext;
  private energyManager = EnergyManager.getInstance();
  private scroller: Scroller = new Scroller();

  async aboutToAppear() {
    await this.energyManager.init(this.context);
    
    const params = router.getParams() as Record<string, Object>;
    if (params && params['cards']) {
      this.cards = params['cards'] as TarotCard[];
      this.spreadType = params['spreadType'] as string || 'time_flow';
      this.spreadName = params['spreadName'] as string || (this.spreadType === 'time_flow' ? '时光流' : '深度解读');
      const todayMood = params['todayMood'] as MoodToday;
      this.isFree = params['isFree'] as boolean || false;
      
      // 初始化状态数组
      this.sectionTexts = new Array(this.cards.length).fill('');
      this.visibleSections = new Array(this.cards.length).fill(false);
      
      // 开始 AI 分析
      this.startAnalysis(todayMood);
    }
  }

  async startAnalysis(todayMood: MoodToday) {
    // 传递 spreadType 给 AIService
    const initialPrompt = AIService.createInitialPrompt(this.cards, todayMood, this.spreadType);
    const userMsg: ChatMessage = { role: 'user', content: initialPrompt };

    try {
      // 传递 isFree 参数
      const fullText = await AIService.requestChat([userMsg], this.context, true, this.isFree);
      this.isAnalyzing = false;
      this.parseAndAnimate(fullText);
    } catch (error) {
      this.isAnalyzing = false;
      this.sectionTexts[0] = "连接宇宙信号失败，请稍后重试...";
      this.visibleSections[0] = true;
      this.showButton = true;
    }
  }

  parseAndAnimate(fullText: string) {
    // 通用解析逻辑：<<<SECTION_N>>>
    const parts = fullText.split(/<<<(.*?)>>>/);
    
    // split 后结构: ["", "SECTION_0", "content...", "", "SECTION_1", "content...", ...]
    
    let maxSectionIndex = -1;

    for (let i = 1; i < parts.length; i += 2) {
      const tag = parts[i].trim();
      const content = parts[i+1] ? parts[i+1].trim() : "";
      
      if (tag.startsWith('SECTION_')) {
        const index = parseInt(tag.replace('SECTION_', ''));
        if (!isNaN(index)) {
          if (index < this.cards.length) {
            this.sectionTexts[index] = content;
          } else {
            // 超出卡牌数量的部分通常是总结
            this.summaryText = content;
          }
          if (index > maxSectionIndex) maxSectionIndex = index;
        }
      }
    }

    // Fallback: 如果解析失败，把全文放在第一段或总结
    if (maxSectionIndex === -1) {
      if (this.cards.length > 0) {
        this.sectionTexts[0] = fullText;
      } else {
        this.summaryText = fullText;
      }
    }

    // 启动序列动画
    this.startSequenceAnimation();
  }

  startSequenceAnimation() {
    let delay = 100;
    
    // 逐个显示卡牌解读
    this.cards.forEach((_, index) => {
      setTimeout(() => {
        animateTo({ duration: 800, curve: Curve.EaseOut }, () => {
          this.visibleSections[index] = true;
        });
        
        // 自动滚动逻辑优化：每显示一段稍微往下滚一点，但不要太频繁
        if (index > 0) {
          this.scroller.scrollBy(0, 100);
        }
      }, delay);
      
      // 增加延迟，阅读时间假设
      delay += 1500; 
    });

    // 显示总结
    setTimeout(() => {
      animateTo({ duration: 800, curve: Curve.EaseOut }, () => {
        this.showSummary = true;
      });
      this.scroller.scrollEdge(Edge.Bottom);
    }, delay);

    // 显示按钮
    setTimeout(() => {
      animateTo({ duration: 600 }, () => {
        this.showButton = true;
      });
    }, delay + 1000);
  }

  getCardImageSource(url: string): ResourceStr {
    if (url.startsWith('http')) {
      return url;
    }
    return $rawfile(url);
  }

  // 获取卡牌位置标题
  getCardTitle(index: number): string {
    if (this.spreadType === 'time_flow') {
      const titles = ['PAST · 过去', 'PRESENT · 现在', 'FUTURE · 未来'];
      return titles[index] || `Card ${index + 1}`;
    } else if (this.spreadType === 'celtic_cross') {
      const titles = [
        '1. 核心现状', '2. 阻碍/挑战', '3. 潜意识/基础', '4. 过去的影响', 
        '5. 最高愿景', '6. 即将发生的未来', '7. 自我态度', '8. 环境影响', '9. 希望与恐惧', '10. 最终结果'
      ];
      return titles[index] || `Card ${index + 1}`;
    } else if (this.spreadType === 'tree_of_life') {
      const titles = [
        '1. 精神源头', '2. 智慧', '3. 理解', '4. 慈悲', '5. 力量', 
        '6. 美/核心', '7. 胜利', '8. 荣耀', '9. 基础', '10. 王国'
      ];
      return titles[index] || `Card ${index + 1}`;
    }
    return `Card ${index + 1}`;
  }

  @Builder
  AnalysisNode(index: number, card: TarotCard, content: string, show: boolean) {
    Row() {
      if (show) {
        Column() {
          // 标题
          Text(`${this.getCardTitle(index)} (${card.name})`)
            .fontSize(14)
            .fontColor('#FF69B4')
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 })
            .width('100%')
            .textAlign(index % 2 === 0 ? TextAlign.Start : TextAlign.End) // 左右交替标题

          Row() {
            if (index % 2 === 0) {
              // 偶数索引：左图右文
              Image(this.getCardImageSource(card.image))
                .width(80).aspectRatio(2/3).borderRadius(6)
                .margin({ right: 12 })
                .shadow({ radius: 8, color: 'rgba(0,0,0,0.3)' })
              
              Text(content || "解读生成中...")
                .fontSize(14)
                .fontColor('#DDD')
                .lineHeight(22)
                .layoutWeight(1)
            } else {
              // 奇数索引：左文右图
              Text(content || "解读生成中...")
                .fontSize(14)
                .fontColor('#DDD')
                .lineHeight(22)
                .layoutWeight(1)
                .textAlign(TextAlign.End)

              Image(this.getCardImageSource(card.image))
                .width(80).aspectRatio(2/3).borderRadius(6)
                .margin({ left: 12 })
                .shadow({ radius: 8, color: 'rgba(0,0,0,0.3)' })
            }
          }
          .alignItems(VerticalAlign.Top)
          .width('100%')

          // 连接线（如果不是最后一个）
          if (index < this.cards.length - 1) {
            Column()
              .width(2)
              .height(30)
              .backgroundColor('rgba(255, 105, 180, 0.3)')
              .margin({ top: 10, bottom: 10 })
              .alignSelf(ItemAlign.Center)
          }
        }
        .width('100%')
        .transition({ type: TransitionType.Insert, opacity: 0, translate: { y: 20 } })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
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
        // 顶部导航栏
        Row() {
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Text('<')
              .fontSize(24)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Medium)
          }
          .width(40)
          .height(40)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            router.back();
          })
          
          Text(`${this.spreadName} · 深度解读`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .margin({ right: 40 })
        }
        .width('100%')
        .height(50)
        .padding({ left: 10, right: 10 })
        .margin({ top: 10 })

        Scroll(this.scroller) {
          Column() {
            if (this.isAnalyzing) {
              Column() {
                LoadingProgress().width(40).height(40).color('#FF69B4')
                Text('正在连接时空长河...')
                  .fontSize(14).fontColor('rgba(255,255,255,0.6)').margin({ top: 10 })
              }
              .height(300)
              .justifyContent(FlexAlign.Center)
            } else {
              Column({ space: 10 }) {
                // 1. 循环显示每张牌的解读
                ForEach(this.cards, (card: TarotCard, index: number) => {
                  this.AnalysisNode(index, card, this.sectionTexts[index], this.visibleSections[index])
                })
                
                // 2. 总结建议
                if (this.showSummary) {
                  Column() {
                    Text('💡 宇宙指引')
                      .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#FFD700').margin({ bottom: 10 })
                    Text(this.summaryText || "生成总结中...")
                      .fontSize(15).fontColor('#FFF').lineHeight(26).textAlign(TextAlign.Center)
                  }
                  .width('90%')
                  .padding(20)
                  .backgroundColor('rgba(255,255,255,0.1)')
                  .borderRadius(16)
                  .margin({ top: 20, bottom: 100 })
                  .transition({ type: TransitionType.Insert, opacity: 0, scale: { x: 0.9, y: 0.9 } })
                }
              }
              .width('100%')
              .padding({ top: 20 })
            }
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
            .height(50)
            .borderRadius(25)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .shadow({ radius: 15, color: 'rgba(255, 105, 180, 0.4)', offsetY: 5 })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/AIChatPage',
                params: {
                  fromDeepAnalysis: true
                }
              });
            })
        }
        .width('100%')
        .padding({ bottom: 30 })
        .transition({ type: TransitionType.Insert, opacity: 0, translate: { y: 30 } })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1A1A2E')
  }
}
