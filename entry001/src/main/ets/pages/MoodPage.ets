import common from '@ohos.app.ability.common';
import { promptAction, router } from '@kit.ArkUI';
import { BottomNavBar } from '../common/BottomNavBar';
import { FortuneManager, CardRecord } from '../common/FortuneManager';
import { TAROT_DECK } from '../model/TarotData';
import { CloudService } from '../common/CloudService'; // 🟢 引入云服务用于自动同步

@Entry
@Component
export struct MoodPage {
  @State moodIndex: number = -1;
  @State moodNote: string = '';
  @State goldQuote: string = '';
  @State dailyTask: string = '';
  @State isHistoryOpen: boolean = false;
  @State historyList: CardRecord[] = [];

  private manager = FortuneManager.getInstance();
  private context = getContext(this) as common.UIAbilityContext;

  // 🟢 核心：智能处理图片链接（网络或本地）
  getCardImageSource(url: string): ResourceStr {
    if (url.startsWith('http')) {
      return url;
    }
    return $rawfile(url);
  }

  async aboutToAppear() {
    await this.manager.init(this.context);
    await this.loadData();
  }

  async loadData() {
    const mood = await this.manager.getTodayMood();
    if (mood.mood === -1) {
      this.moodIndex = -1;
      this.moodNote = '';
    } else {
      this.moodIndex = mood.mood;
      this.moodNote = mood.note || '';
    }

    const aff = await this.manager.getTodayAffirmations();
    this.goldQuote = aff.quote;
    this.dailyTask = aff.task;

    this.historyList = await this.manager.getHistory();
  }

  selectMood(index: number) {
    this.moodIndex = index;
  }

  async handleSave() {
    if (this.moodIndex === -1) {
      promptAction.showToast({ message: '请先选择一个代表今天心情的图标', duration: 2000 });
      return;
    }
    if (!this.moodNote || this.moodNote.trim().length === 0) {
      promptAction.showToast({ message: '请写下此刻的想法或记录', duration: 2000 });
      return;
    }

    await this.manager.setTodayMood(this.moodIndex, this.moodNote);
    promptAction.showToast({ message: '✨ 心情已记录', duration: 1200 });

    // 🟢 自动同步：保存后立即在后台尝试同步到云端
    CloudService.autoSave();

    this.historyList = await this.manager.getHistory();

    const streak = await this.manager.getMoodStreak();
    const label = this.manager.getAchievementLabelByStreak(streak);
    if (label) {
      AlertDialog.show({ title: '🎖️ 情绪成就', message: `${label}\n继续保持这份温柔的自我照顾。` });
    }
  }

  formatDateShort(timestamp: number): string {
    const date = new Date(timestamp);
    return `${date.getMonth() + 1}.${date.getDate()}`;
  }

  getCardImage(id: number): string {
    return TAROT_DECK[id]?.image || 'card_back.png';
  }

  getMoodEmoji(index: number | undefined): string {
    const emojis = ['😭', '😕', '🙂', '😊', '🥳'];
    if (index === undefined || index < 0 || index >= emojis.length) return '🤔';
    return emojis[index];
  }

  getFilteredHistory(): CardRecord[] {
    return this.historyList.filter(r => r.moodIndex !== undefined && r.moodIndex !== -1);
  }

  // 历史记录画廊 Sheet
  @Builder HistorySheetBuilder() {
    Column() {
      // 顶部把手
      Row().width(40).height(5).backgroundColor('#E0E0E0').borderRadius(5).margin({ top: 10, bottom: 15 })

      Row() {
        Column() {
          Text("心情画廊").fontSize(22).fontWeight(FontWeight.Bold).fontColor('#333')
          Text("每一张牌都记录着当下的你").fontSize(12).fontColor('#999').margin({top: 4})
        }.alignItems(HorizontalAlign.Start)

        Blank()

        Text(`${this.getFilteredHistory().length} 篇回忆`).fontSize(12).fontColor('#BBB')
      }.width('100%').padding({ left: 24, right: 24, bottom: 15 })

      // 画廊网格
      Grid() {
        ForEach(this.getFilteredHistory(), (record: CardRecord) => {
          GridItem() {
            Column() {
              // 卡片主体
              Stack({ alignContent: Alignment.BottomEnd }) {
                // 🟢 修复：调用 getCardImageSource 加载网络图
                Image(this.getCardImageSource(this.getCardImage(record.cardId)))
                  .width('100%')
                  .aspectRatio(3/4)
                  .objectFit(ImageFit.Cover)
                  .borderRadius({ topLeft: 12, topRight: 12 })
                  .alt($rawfile('card_back.png')) // 加载占位图

                // 渐变遮罩
                Row()
                  .width('100%')
                  .height('40%')
                  .linearGradient({
                    direction: GradientDirection.Bottom,
                    colors: [['rgba(0,0,0,0)', 0.0], ['rgba(0,0,0,0.4)', 1.0]]
                  })
                  .borderRadius({ bottomLeft: 0, bottomRight: 0 })

                // 心情印章
                Text(this.getMoodEmoji(record.moodIndex))
                  .fontSize(28)
                  .margin({ right: 8, bottom: 8 })
                  .shadow({ radius: 10, color: 'rgba(0,0,0,0.2)', offsetY: 2 })
              }
              .width('100%')
              .clip(true) // 裁剪溢出部分
              .borderRadius({ topLeft: 12, topRight: 12 })

              // 底部文字区域
              Column() {
                Row() {
                  Text(this.formatDateShort(record.timestamp))
                    .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#333')
                  Blank()
                  Circle({ width: 4, height: 4 }).fill('#EEE')
                }.width('100%').margin({ bottom: 6 })

                Text(record.moodNote || '...')
                  .fontSize(13)
                  .fontColor('#666')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .lineHeight(18)
              }
              .width('100%')
              .padding(12)
              .backgroundColor(Color.White)
              .borderRadius({ bottomLeft: 12, bottomRight: 12 })
            }
            .shadow({ radius: 15, color: 'rgba(0,0,0,0.05)', offsetY: 5 })
            .margin(5)
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(10)
      .rowsGap(15)
      .padding({ left: 15, right: 15, bottom: 20 })
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // 空状态
      if (this.getFilteredHistory().length === 0) {
        Column() {
          Text('🖼️').fontSize(48).opacity(0.5)
          Text('画廊空空如也').fontSize(14).fontColor('#999').margin({ top: 12 })
          Text('去记录第一份心情吧').fontSize(12).fontColor('#CCC').margin({ top: 4 })
        }.width('100%').height('50%').justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('85%')
    .backgroundColor('#F7F8FA')
    .borderRadius({ topLeft: 24, topRight: 24 })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#F7F8FA')

      Scroll() {
        Column({ space: 20 }) {
          // 顶部标题栏
          Row() {
            Column({ space: 4 }) {
              Text('心情日记')
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
              Text('记录当下的真实感受')
                .fontSize(14)
                .fontColor('#999999')
            }
            .alignItems(HorizontalAlign.Start)

            Blank()

            // 右上角：历史记录入口
            Button({ type: ButtonType.Circle }) {
              Text('📅').fontSize(20)
            }
            .width(44).height(44)
            .backgroundColor(Color.White)
            .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
            .onClick(() => { this.isHistoryOpen = true })
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 20 })

          // 1. 心情选择卡片
          Column({ space: 16 }) {
            Text('今天感觉如何？')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .width('100%')

            Row() {
              ForEach(['😭', '😕', '🙂', '😊', '🥳'], (emoji: string, index: number) => {
                Column() {
                  Text(emoji).fontSize(32)
                }
                .width(56)
                .height(56)
                .justifyContent(FlexAlign.Center)
                .borderRadius(16)
                .backgroundColor(this.moodIndex === index ? '#FFF0F5' : 'transparent')
                .border(this.moodIndex === index ? { width: 2, color: '#FF69B4' } : { width: 0 })
                .animation({ duration: 200 })
                .onClick(() => this.selectMood(index))
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .padding(20)
          .backgroundColor(Color.White)
          .borderRadius(20)
          .shadow({ radius: 20, color: 'rgba(0,0,0,0.03)', offsetY: 5 })
          .margin({ left: 16, right: 16 })

          // 2. 输入框卡片
          Column({ space: 12 }) {
            TextArea({ text: this.moodNote, placeholder: '写下此刻的想法...' })
              .height(120)
              .backgroundColor('#F9F9F9')
              .borderRadius(12)
              .fontSize(15)
              .placeholderColor('#CCCCCC')
              .onChange((v) => { this.moodNote = v; })

            Row() {
              Blank()
              Button('保存记录')
                .backgroundColor('#333333')
                .fontColor(Color.White)
                .height(36)
                .fontSize(13)
                .borderRadius(18)
                .onClick(() => this.handleSave())
            }
          }
          .padding(20)
          .backgroundColor(Color.White)
          .borderRadius(20)
          .shadow({ radius: 20, color: 'rgba(0,0,0,0.03)', offsetY: 5 })
          .margin({ left: 16, right: 16 })

          // 3. 每日指引卡片 (如有)
          if (this.goldQuote || this.dailyTask) {
            Column() {
              Row() {
                Text('✨').fontSize(18).margin({ right: 8 })
                Text('今日能量指引').fontSize(16).fontWeight(FontWeight.Bold)
              }.width('100%').margin({ bottom: 12 })

              if (this.goldQuote) {
                Text('“ ' + this.goldQuote + ' ”')
                  .fontSize(15)
                  .fontColor('#555555')
                  .fontStyle(FontStyle.Italic)
                  .lineHeight(24)
                  .margin({ bottom: 12 })
              }

              if (this.dailyTask) {
                Row() {
                  Checkbox({ name: 'task', group: 'task' }).select(false).width(16).height(16)
                  Text(this.dailyTask).fontSize(14).fontColor('#666666').margin({ left: 8 })
                }
                .backgroundColor('#F5F7FA')
                .padding(12)
                .borderRadius(8)
                .width('100%')
              }
            }
            .padding(20)
            .backgroundColor(Color.White)
            .borderRadius(20)
            .shadow({ radius: 20, color: 'rgba(0,0,0,0.03)', offsetY: 5 })
            .margin({ left: 16, right: 16 })
          }

          Blank().height(100) // 底部垫高
        }
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)

      // 悬浮导航栏
      BottomNavBar({ current: 'mood' })
    }
    .bindSheet($$this.isHistoryOpen, this.HistorySheetBuilder(), {
      height: SheetSize.LARGE,
      backgroundColor: Color.Transparent,
      blurStyle: BlurStyle.Thin,
      showClose: true
    })
  }
}