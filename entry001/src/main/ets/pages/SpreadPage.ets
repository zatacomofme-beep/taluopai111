import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { FortuneManager } from '../common/FortuneManager';
import { TarotCard } from '../model/TarotData';
import curves from '@ohos.curves';
import promptAction from '@ohos.promptAction';
import { BusinessError } from '@kit.BasicServicesKit';
import { AIService, ChatMessage } from '../common/AIService';
import { EnergyManager } from '../common/EnergyManager';

@Entry
@Component
struct SpreadPage {
  @State cards: TarotCard[] = [];
  @State cardStates: number[] = [0, 0, 0];
  @State cardImages: Resource[] = [$rawfile('card_back.png'), $rawfile('card_back.png'), $rawfile('card_back.png')];

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
  @State isSheetOpen: boolean = false;
  @State isAnalyzing: boolean = false;
  @State chatHistory: ChatMessage[] = [];
  @State inputText: string = "";
  @State currentEnergy: number = 0;

  private listScroller: Scroller = new Scroller();
  private manager = FortuneManager.getInstance();
  private energyManager = EnergyManager.getInstance();
  private positions = ['过去 · The Past', '现在 · The Present', '未来 · The Future'];
  private context = getContext(this) as common.UIAbilityContext;

  async aboutToAppear() {
    this.cards = this.manager.drawThreeSpread();
    await this.energyManager.init(this.context);
    this.currentEnergy = this.energyManager.getEnergy();
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
      this.cardImages[index] = $rawfile(this.cards[index].image);
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

  // 🚀 关键修改：获取心情并传给 AI
  async handleAIAnalyze() {
    this.isSheetOpen = true;
    this.currentEnergy = this.energyManager.getEnergy();

    if (this.chatHistory.length > 0) return;
    this.isAnalyzing = true;

    // 1. 获取今日心情
    const todayMood = await this.manager.getTodayMood();

    // 2. 生成包含心情的 Prompt
    const initialPrompt = AIService.createInitialPrompt(this.cards, todayMood);

    const userMsg: ChatMessage = { role: 'user', content: initialPrompt };
    this.chatHistory.push(userMsg);
    const aiMsg: ChatMessage = { role: 'assistant', content: '' };
    this.chatHistory.push(aiMsg);

    const requestHistory = [userMsg];

    // 3. 发送请求
    const resultText = await AIService.requestChat(requestHistory, this.context, true);

    this.currentEnergy = this.energyManager.getEnergy();
    this.isAnalyzing = false;
    this.typewriterEffect(resultText, this.chatHistory.length - 1);
  }

  async handleSendMessage() {
    if (this.inputText.trim() === "" || this.isAnalyzing) return;
    const text = this.inputText;
    this.inputText = "";
    this.chatHistory.push({ role: 'user', content: text });
    this.listScroller.scrollEdge(Edge.Bottom);
    this.isAnalyzing = true;
    this.chatHistory.push({ role: 'assistant', content: "..." });
    const aiMsgIndex = this.chatHistory.length - 1;
    const requestHistory = this.chatHistory.slice(0, aiMsgIndex);

    const resultText = await AIService.requestChat(requestHistory, this.context, false);

    this.currentEnergy = this.energyManager.getEnergy();
    this.isAnalyzing = false;
    this.chatHistory[aiMsgIndex].content = "";
    this.typewriterEffect(resultText, aiMsgIndex);
  }

  typewriterEffect(fullText: string, msgIndex: number) {
    let index = 0;
    let intervalID = setInterval(() => {
      if (index < fullText.length) {
        const currentMsg = this.chatHistory[msgIndex];
        this.chatHistory[msgIndex] = { role: currentMsg.role, content: currentMsg.content + fullText.charAt(index) };
        index++;
        this.listScroller.scrollEdge(Edge.Bottom);
      } else {
        clearInterval(intervalID);
      }
    }, 30);
  }

  @Builder ChatSheetBuilder() {
    Column() {
      Row().width(40).height(5).backgroundColor('#E0E0E0').borderRadius(10).margin({ top: 10, bottom: 10 })

      Row() {
        Row() {
          Text("✨小阿秋").fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333333')
          if (this.isAnalyzing) {
            LoadingProgress().width(20).height(20).color('#FF69B4').margin({ left: 8 })
          }
        }

        Row() {
          Text('⚡').fontSize(14)
          Text(`${this.currentEnergy}`).fontSize(14).fontColor('#FF69B4').fontWeight(FontWeight.Bold).margin({left: 2})
        }.backgroundColor('#FFF0F5').padding({left: 8, right: 8, top: 4, bottom: 4}).borderRadius(12).margin({right: 12})

        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Text('✕').fontSize(14).fontColor('#999999')
        }.width(28).height(28).backgroundColor('#F5F5F5').onClick(() => { this.isSheetOpen = false; })
      }.width('100%').padding({ left: 20, right: 20, bottom: 10 }).justifyContent(FlexAlign.SpaceBetween)

      Divider().color('#F0F0F0')

      List({ scroller: this.listScroller }) {
        ForEach(this.chatHistory, (msg: ChatMessage, index: number) => {
          if (index > 0) {
            ListItem() {
              Row() {
                if (msg.role === 'user') {
                  Blank()
                  // 这里可以优化显示，不要把完整的 Prompt 显示出来，只显示“开始解读...”
                  Text(msg.content.startsWith('【用户当前状态】') ? '🔮 开始深度解读...' : msg.content)
                    .fontSize(15).fontColor(Color.White).backgroundColor('#FFB6C1').padding(12)
                    .borderRadius({ topLeft: 15, topRight: 5, bottomLeft: 15, bottomRight: 15 }).margin({ left: 40 })
                } else {
                  Image($rawfile('card_back.png')).width(30).height(30).borderRadius(15).margin({ right: 8 })
                  Text(msg.content).fontSize(15).fontColor('#333333').backgroundColor('#F5F5F5').padding(12)
                    .borderRadius({ topLeft: 5, topRight: 15, bottomLeft: 15, bottomRight: 15 }).margin({ right: 40 }).layoutWeight(1)
                }
              }.width('100%').padding({ top: 10, bottom: 10, left: 20, right: 20 }).alignItems(VerticalAlign.Top)
            }
          }
        })
      }.layoutWeight(1).width('100%')

      Row() {
        TextInput({ text: this.inputText, placeholder: this.currentEnergy >= 2 ? '每次提问消耗 2 心力...' : '心力不足，明日再来...' })
          .layoutWeight(1).height(40).backgroundColor('#F5F5F5')
          .borderRadius(20).padding({ left: 15 }).onChange((value) => { this.inputText = value; }).onSubmit(() => this.handleSendMessage())
          .enabled(this.currentEnergy >= 2)

        Button("发送").width(70).height(40).backgroundColor(this.currentEnergy >= 2 ? '#FF69B4' : '#CCCCCC').fontColor(Color.White).margin({ left: 10 })
          .borderRadius(20).onClick(() => this.handleSendMessage()).opacity(this.isAnalyzing ? 0.5 : 1)
          .enabled(this.currentEnergy >= 2)
      }.width('100%').padding(15).backgroundColor(Color.White).shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: -2 })
    }
    .width('100%').height('100%').backgroundColor(Color.White)
  }

  build() {
    Column() {
      Row() {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Text('❮').fontSize(18).fontColor('#FFFFFF')
        }.width(40).height(40).backgroundColor('rgba(255,255,255,0.2)').onClick(() => router.back())
        Text('时光流 · 三牌阵').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
          .layoutWeight(1).textAlign(TextAlign.Center).margin({ right: 40 })
      }.width('100%').height(50).padding({ left: 20, right: 20 }).margin({ top: 10, bottom: 20 })

      Column({ space: 20 }) {
        ForEach([0, 1, 2], (index: number) => {
          Row() {
            Stack() {
              Image($rawfile('card_back.png')).width('100%').height('100%').borderRadius(10).rotate({ x: 0, y: 1, z: 0, angle: this.cardAngles[index] }).opacity(this.cardAngles[index] < 90 ? 1 : 0)
              Image($rawfile(this.cards[index].image)).width('100%').height('100%').borderRadius(10).rotate({ x: 0, y: 1, z: 0, angle: this.cardAngles[index] - 180 }).opacity(this.cardAngles[index] >= 90 ? 1 : 0).scale({ x: 1, y: this.cardFlightScales[index] })
            }
            .width(110).aspectRatio(2/3).shadow({ radius: 15, color: 'rgba(0,0,0,0.4)', offsetY: 8 })
            .translate({ y: this.cardFloatOffsets[index] }).rotate({ z: 1, angle: this.cardFloatAngles[index] }).scale({ x: this.cardClickScales[index], y: this.cardClickScales[index] })
            .onClick(() => this.handleCardClick(index))
            .align(Alignment.Center).animation({ duration: 0 })

            if (this.cardStates[index] === 2) {
              Column() {
                Text(this.positions[index]).fontSize(13).fontColor('rgba(255,255,255,0.7)').margin({ bottom: 4 })
                Text(this.displayNames[index]).fontSize(20).fontWeight(FontWeight.Bold).fontColor('#FFFFFF').margin({ bottom: 8 })
                Text(this.displayMeanings[index]).fontSize(15).fontColor('#EEEEEE').maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis })
                  .border(this.displayMeanings[index].length < this.cards[index].meaning.length ? { width: { right: 2 }, color: '#FF69B4' } : { width: 0 })
              }
              .layoutWeight(1).padding({ left: 25, right: 10 }).alignItems(HorizontalAlign.Start)
              .opacity(this.cardTextOpacities[index])
              .transition({ type: TransitionType.Insert, opacity: 0, translate: { x: 20 } })
            }
          }.width('100%').alignItems(VerticalAlign.Center)
          .opacity(index > (this.currentReadingCardIndex === -1 ? 0 : this.currentReadingCardIndex + 1) && this.cardStates[index - 1] !== 2 ? 0.3 : 1)
        })
      }.margin({ top: 30 }).padding({ left: 20, right: 20 })

      Blank()

      if (this.cardStates[2] === 2) {
        Column() {
          // 在按钮上提示消耗
          Button(`🔮 深度分析 (消耗 ${AIService.COST_DEEP_ANALYSIS} 心力)`).backgroundColor('#FF69B4').fontColor(Color.White).width('80%').height(50).borderRadius(25)
            .shadow({ radius: 10, color: 'rgba(255, 105, 180, 0.4)', offsetY: 5 }).onClick(() => this.handleAIAnalyze())
        }
        .margin({ bottom: 40 })
        .transition({ type: TransitionType.Insert, opacity: 0, translate: { y: 20 } })
      }
    }
    .width('100%').height('100%').backgroundColor('#1A1A2E').padding({ top: 12, bottom: 12 })
    .bindSheet($$this.isSheetOpen, this.ChatSheetBuilder(), {
      height: SheetSize.LARGE, backgroundColor: Color.White, blurStyle: BlurStyle.Thin, showClose: false, dragBar: true
    })
  }
}