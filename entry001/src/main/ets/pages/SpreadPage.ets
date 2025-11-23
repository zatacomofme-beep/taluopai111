// 路径: ets/pages/SpreadPage.ets
// V10.0 终极交互版：三牌阵加入“呼吸悬浮”与“Q弹点击”

import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { FortuneManager } from '../common/FortuneManager';
import { TarotCard } from '../model/TarotData';
import curves from '@ohos.curves';
import promptAction from '@ohos.promptAction';
import { BusinessError } from '@kit.BasicServicesKit';
import { AIService, ChatMessage } from '../common/AIService';

@Entry
@Component
struct SpreadPage {
  @State cards: TarotCard[] = [];
  @State cardStates: number[] = [0, 0, 0];
  @State cardImages: Resource[] = [$rawfile('card_back.png'), $rawfile('card_back.png'), $rawfile('card_back.png')];

  // 🎬 翻转动画变量
  @State cardAngles: number[] = [0, 0, 0];
  @State cardFlightScales: number[] = [1, 1, 1];

  // ✨✨✨ 新增：呼吸与交互动画变量 (数组对应3张牌) ✨✨✨
  @State cardFloatOffsets: number[] = [0, 0, 0]; // 呼吸：上下浮动
  @State cardFloatAngles: number[] = [0, 0, 0];  // 呼吸：左右微摆
  @State cardClickScales: number[] = [1, 1, 1];  // 交互：点击缩放

  // 文字与AI
  @State displayNames: string[] = ['', '', ''];
  @State displayMeanings: string[] = ['', '', ''];
  @State cardTextOpacities: number[] = [0, 0, 0];
  @State currentReadingCardIndex: number = -1;

  // AI 弹窗
  @State isSheetOpen: boolean = false;
  @State isAnalyzing: boolean = false;
  @State chatHistory: ChatMessage[] = [];
  @State inputText: string = "";

  // 修复 Scroller 状态报错：移除 @State
  private listScroller: Scroller = new Scroller();

  private manager = FortuneManager.getInstance();
  private positions = ['过去 · The Past', '现在 · The Present', '未来 · The Future'];
  private context = getContext(this) as common.UIAbilityContext;

  aboutToAppear() {
    this.cards = this.manager.drawThreeSpread();
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

  // ✨ 启动呼吸动画 (带随机延迟，让三张牌呼吸不同步，更自然) ✨
  startBreathing(index: number) {
    const delay = index * 150; // 每张牌错开一点时间

    // 1. 上下浮动
    animateTo({
      duration: 2000,
      curve: Curve.EaseInOut,
      iterations: -1,
      playMode: PlayMode.Alternate,
      delay: delay
    }, () => {
      this.cardFloatOffsets[index] = -8; // 向上浮动 8px
    });

    // 2. 左右微摆
    animateTo({
      duration: 3000,
      curve: Curve.Smooth,
      iterations: -1,
      playMode: PlayMode.Alternate,
      delay: delay + 500
    }, () => {
      this.cardFloatAngles[index] = 1; // 向右微摆 1度
    });
  }

  // ✨ 点击 Q 弹反馈 ✨
  playClickFeedback(index: number) {
    // 瞬间缩小
    animateTo({ duration: 100, curve: Curve.EaseOut }, () => {
      this.cardClickScales[index] = 0.95;
    });

    // 弹簧回弹
    setTimeout(() => {
      animateTo({
        duration: 400,
        curve: curves.springMotion(0.5, 0.6)
      }, () => {
        this.cardClickScales[index] = 1.0;
      });
    }, 100);
  }

  handleCardClick(index: number) {
    // 顺序控制
    if (index > 0 && this.cardStates[index - 1] !== 2) {
      try {
        promptAction.showToast({ message: `请先翻开「${this.positions[index - 1].split('·')[0].trim()}」的牌`, duration: 2000 });
      } catch (e) {
        const _err = e as BusinessError | Error | object;
      }
      return;
    }

    // 🌟 情况 1: 已经翻开了 -> 触发 Q 弹反馈
    if (this.cardStates[index] === 2) {
      this.playClickFeedback(index);
      return;
    }

    // 🌟 情况 2: 正在翻转中 -> 忽略
    if (this.cardStates[index] !== 0) return;

    // 🌟 情况 3: 未翻开 -> 执行翻转逻辑
    this.cardStates[index] = 1;

    // 🎬 动画第一阶段：起飞 + 旋转90度
    animateTo({
      duration: 400,
      curve: curves.springMotion(0.6, 0.8)
    }, () => {
      this.cardAngles[index] = 90;
      this.cardFlightScales[index] = 1.15; // 翻转时放大
    });

    // 🎬 中场切换
    setTimeout(() => {
      this.cardImages[index] = $rawfile(this.cards[index].image);

      // 🎬 动画第二阶段：降落 + 旋转180度
      animateTo({
        duration: 500,
        curve: curves.springMotion(0.5, 0.7)
      }, () => {
        this.cardAngles[index] = 180;
        this.cardFlightScales[index] = 1.0; // 恢复原大小
      });

      // 🎬 收尾：启动呼吸 + 打字机
      setTimeout(() => {
        this.cardStates[index] = 2;
        this.currentReadingCardIndex = index;

        // 启动呼吸动画
        this.startBreathing(index);

        animateTo({ duration: 400 }, () => {
          this.cardTextOpacities[index] = 1;
        });
        this.startTypewriter(index);
      }, 300);

    }, 400);
  }

  /**
   * 触发 AI 深度分析弹窗，并请求首条分析
   */
  async handleAIAnalyze() {
    this.isSheetOpen = true;
    if (this.chatHistory.length > 0) return;
    this.isAnalyzing = true;

    const initialPrompt = AIService.createInitialPrompt(this.cards);
    const userMsg: ChatMessage = { role: 'user', content: initialPrompt };
    this.chatHistory.push(userMsg);
    const aiMsg: ChatMessage = { role: 'assistant', content: '' };
    this.chatHistory.push(aiMsg);

    const requestHistory = [userMsg];
    const resultText = await AIService.requestChat(requestHistory, this.context);

    this.isAnalyzing = false;
    this.typewriterEffect(resultText, this.chatHistory.length - 1);
  }

  /**
   * 发送后续对话消息，保持上下文
   */
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
    const resultText = await AIService.requestChat(requestHistory, this.context);
    this.isAnalyzing = false;
    this.chatHistory[aiMsgIndex].content = "";
    this.typewriterEffect(resultText, aiMsgIndex);
  }

  typewriterEffect(fullText: string, msgIndex: number) {
    let index = 0;
    let intervalID = setInterval(() => {
      if (index < fullText.length) {
        const currentMsg = this.chatHistory[msgIndex];
        this.chatHistory[msgIndex] = {
          role: currentMsg.role,
          content: currentMsg.content + fullText.charAt(index)
        };
        index++;
        this.listScroller.scrollEdge(Edge.Bottom);
      } else {
        clearInterval(intervalID);
      }
    }, 30);
  }

  @Builder
  ChatSheetBuilder() {
    Column() {
      Row().width(40).height(5).backgroundColor('#E0E0E0').borderRadius(10).margin({ top: 10, bottom: 10 })

      Row() {
        Row() {
          Text("✨小阿秋").fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333333')
          if (this.isAnalyzing) {
            LoadingProgress().width(20).height(20).color('#FF69B4').margin({ left: 8 })
          }
        }
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
                  Text(msg.content).fontSize(15).fontColor(Color.White).backgroundColor('#FFB6C1').padding(12)
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
        TextInput({ text: this.inputText, placeholder: '想问什么...?' }).layoutWeight(1).height(40).backgroundColor('#F5F5F5')
          .borderRadius(20).padding({ left: 15 }).onChange((value) => { this.inputText = value; }).onSubmit(() => this.handleSendMessage())
        Button("发送").width(70).height(40).backgroundColor('#FF69B4').fontColor(Color.White).margin({ left: 10 })
          .borderRadius(20).onClick(() => this.handleSendMessage()).opacity(this.isAnalyzing ? 0.5 : 1)
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
            // --- 3D 卡牌容器 ---
            Stack() {
              // 1. 背面 (0 -> 180度，翻过去后消失)
              Image($rawfile('card_back.png'))
                .width('100%').height('100%')
                .borderRadius(10)
                .rotate({ x: 0, y: 1, z: 0, angle: this.cardAngles[index] })
                .opacity(this.cardAngles[index] < 90 ? 1 : 0)

              // 2. 正面 (初始 -180度，翻过来变0度显示)
              Image($rawfile(this.cards[index].image))
                .width('100%').height('100%')
                .borderRadius(10)
                .rotate({ x: 0, y: 1, z: 0, angle: this.cardAngles[index] - 180 })
                .opacity(this.cardAngles[index] >= 90 ? 1 : 0)
                // 💡 绑定翻转时的悬浮缩放 (ScaleY)
                .scale({ x: 1, y: this.cardFlightScales[index] })
            }
            .width(110).aspectRatio(2/3)
            .shadow({ radius: 15, color: 'rgba(0,0,0,0.4)', offsetY: 8 })

            // ✨✨✨ 外层 Stack 绑定呼吸和点击动画 ✨✨✨
            .translate({ y: this.cardFloatOffsets[index] })    // 绑定呼吸浮动
            .rotate({ z: 1, angle: this.cardFloatAngles[index] }) // 绑定呼吸摆动 (注意z:1)
            .scale({ x: this.cardClickScales[index], y: this.cardClickScales[index] }) // 绑定点击缩放

            .onClick(() => this.handleCardClick(index))
            .align(Alignment.Center)
            .animation({ duration: 0 }) // 禁用 Stack 自身隐式动画，防止干扰

            // 右侧文字
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
          // Text("✨ 牌阵已成，是否需要深入解读？").fontSize(14).fontColor('rgba(255,255,255,0.6)').margin({ bottom: 15 })
          Button("🔮深度分析").backgroundColor('#FF69B4').fontColor(Color.White).width('80%').height(50).borderRadius(25)
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