import { router } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';
import { AIService, ChatMessage } from '../common/AIService';
import { BottomNavBar } from '../common/BottomNavBar';
import { EnergyManager } from '../common/EnergyManager';

@Entry
@Component
struct AIChatPage {
  @State messageList: ChatMessage[] = [
    {
      role: 'assistant',
      content: '你好，我是你的情绪树洞。此刻的你，有什么想说的吗？不论是开心的事，还是烦恼的思绪，我都愿意倾听。'
    }
  ];
  @State inputText: string = '';
  @State isSending: boolean = false;
  @State currentEnergy: number = 0;

  private listScroller: Scroller = new Scroller();
  private context = getContext(this) as common.UIAbilityContext;
  private energyManager = EnergyManager.getInstance();

  async aboutToAppear() {
    await this.energyManager.init(this.context);
    this.currentEnergy = this.energyManager.getEnergy();
  }

  async sendMessage() {
    if (this.inputText.trim().length === 0 || this.isSending) return;

    const userMsg = this.inputText;
    this.inputText = '';
    this.messageList.push({ role: 'user', content: userMsg });
    this.scrollToBottom();

    this.isSending = true;

    // 构造请求历史，仅保留最近的几轮对话以节省 token 或保持上下文相关性
    // 这里简单地把整个列表传进去，AIService 会自动处理 system prompt
    try {
      const reply = await AIService.requestChat(this.messageList, this.context, false);
      this.messageList.push({ role: 'assistant', content: reply });
      
      // 更新心力显示
      this.currentEnergy = this.energyManager.getEnergy();
    } catch (error) {
      this.messageList.push({ role: 'assistant', content: '抱歉，我现在有点累（网络连接失败），请稍后再试。' });
    } finally {
      this.isSending = false;
      this.scrollToBottom();
    }
  }

  scrollToBottom() {
    setTimeout(() => {
      this.listScroller.scrollEdge(Edge.Bottom);
    }, 100);
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('情绪对话')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        
        Blank()

        Row() {
          Text('⚡').fontSize(14)
          Text(`${this.currentEnergy}`).fontSize(14).fontColor('#FB7299').fontWeight(FontWeight.Bold).margin({ left: 2 })
        }
        .backgroundColor('rgba(255,255,255,0.6)')
        .backdropBlur(20)
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .borderRadius(16)
        .shadow({ radius: 5, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })
      .backgroundColor('rgba(255,255,255,0.8)')
      .backdropBlur(10)
      .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
      .zIndex(1)

      // 聊天列表
      List({ scroller: this.listScroller }) {
        ListItem().height(16) // 顶部留白

        ForEach(this.messageList, (msg: ChatMessage, index: number) => {
          ListItem() {
            if (msg.role === 'assistant') {
              // AI 消息 (左侧)
              Row() {
                // 头像
                Image($r('app.media.startIcon')) // 建议替换为专门的 AI 头像
                  .width(40).height(40).borderRadius(20)
                  .margin({ right: 12 })
                  .backgroundColor('#F0F0F0')
                  .border({ width: 1, color: '#FFF' })
                  .shadow({ radius: 4, color: 'rgba(0,0,0,0.1)', offsetY: 2 })

                // 气泡
                Text(msg.content)
                  .fontSize(16)
                  .fontColor('#333')
                  .lineHeight(24)
                  .backgroundColor(Color.White)
                  .padding(14)
                  .borderRadius({ topLeft: 4, topRight: 16, bottomLeft: 16, bottomRight: 16 })
                  .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
                  .layoutWeight(1)
              }
              .alignItems(VerticalAlign.Top)
              .width('100%')
              .padding({ left: 16, right: 60, top: 8, bottom: 8 })
            } else {
              // 用户消息 (右侧)
              Row() {
                // 气泡
                Text(msg.content.startsWith('【用户当前状态】') ? '🔮 开始深度解读...' : msg.content)
                  .fontSize(16)
                  .fontColor(Color.White)
                  .lineHeight(24)
                  .backgroundColor('#FB7299') // 少女粉
                  .padding(14)
                  .borderRadius({ topLeft: 16, topRight: 4, bottomLeft: 16, bottomRight: 16 })
                  .shadow({ radius: 8, color: 'rgba(251, 114, 153, 0.4)', offsetY: 4 })
                  .margin({ right: 12 })

                // 头像
                Image($r('app.media.startIcon')) // 用户头像，后续可绑定用户信息
                  .width(40).height(40).borderRadius(20)
                  .backgroundColor('#EEE')
                  .border({ width: 1, color: '#FFF' })
                  .shadow({ radius: 4, color: 'rgba(0,0,0,0.1)', offsetY: 2 })
              }
              .alignItems(VerticalAlign.Top)
              .width('100%')
              .justifyContent(FlexAlign.End) // 内容右对齐
              .padding({ left: 60, right: 16, top: 8, bottom: 8 })
            }
          }
        })
        ListItem().height(20) // 底部留白
      }
      .layoutWeight(1)
      .width('100%')
      .alignListItem(ListItemAlign.Start)

      // 底部输入框区域
      Row() {
        TextInput({ placeholder: '与我分享你的故事...', text: this.inputText })
          .layoutWeight(1)
          .height(48)
          .backgroundColor(Color.White)
          .borderRadius(24)
          .padding({ left: 20, right: 20 })
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: 1 })
          .onChange((value) => { this.inputText = value; })
          .onSubmit(() => this.sendMessage())

        Button(this.isSending ? '...' : '发送')
          .height(48)
          .width(80)
          .margin({ left: 12 })
          .backgroundColor(this.inputText.trim().length > 0 ? '#FB7299' : '#E0E0E0')
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .borderRadius(24)
          .shadow({ radius: this.inputText.trim().length > 0 ? 8 : 0, color: 'rgba(251, 114, 153, 0.4)', offsetY: 3 })
          .enabled(this.inputText.trim().length > 0 && !this.isSending)
          .onClick(() => this.sendMessage())
          .animation({ duration: 200 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('rgba(249, 249, 249, 0.9)')
      .backdropBlur(20)

      // 底部导航栏
      BottomNavBar({ current: 'chat' })
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [['#FDFBFB', 0.0], ['#FFF0F5', 1.0]] // 浅粉色渐变背景
    })
  }
}
