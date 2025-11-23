import common from '@ohos.app.ability.common';
import { promptAction, router } from '@kit.ArkUI';
import { BottomNavBar } from '../common/BottomNavBar';
import { FortuneManager } from '../common/FortuneManager';

@Entry
@Component
export struct MoodPage {
  @State moodIndex: number = -1;
  @State moodNote: string = '';
  @State goldQuote: string = '';
  @State dailyTask: string = '';

  private manager = FortuneManager.getInstance();
  private context = getContext(this) as common.UIAbilityContext;

  /**
   * 生命周期：页面出现时读取数据（函数级注释）
   */
  async aboutToAppear() {
    await this.manager.init(this.context);
    const mood = await this.manager.getTodayMood();
    this.moodIndex = mood.mood;
    this.moodNote = mood.note;
    const aff = await this.manager.getTodayAffirmations();
    this.goldQuote = aff.quote;
    this.dailyTask = aff.task;
  }

  /**
   * 保存心情并触发成就（函数级注释）
   */
  async setMood(index: number) {
    this.moodIndex = index;
    await this.manager.setTodayMood(index, this.moodNote);
    promptAction.showToast({ message: '🫶 心情已记录', duration: 1200 });
    const streak = await this.manager.getMoodStreak();
    const label = this.manager.getAchievementLabelByStreak(streak);
    if (label) {
      AlertDialog.show({ title: '🎖️ 情绪成就', message: `${label}\n继续保持这份温柔的自我照顾。` });
    }
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          // 顶部导航一致性
          Stack({ alignContent: Alignment.Start }) {
            Button({ type: ButtonType.Circle, stateEffect: true }) {
              Text('❮').fontSize(18).fontColor('#666666').fontWeight(FontWeight.Bold)
            }.width(40).height(40).backgroundColor('rgba(0,0,0,0.05)').margin({ left: 20 }).onClick(() => router.replaceUrl({ url: 'pages/Index' }))
            Stack({ alignContent: Alignment.End }) {
              Button({ type: ButtonType.Circle, stateEffect: true }) { Text('🏛️').fontSize(18) }
                .width(40).height(40).backgroundColor('rgba(0,0,0,0.05)').margin({ right: 20 })
                .onClick(() => router.replaceUrl({ url: 'pages/Index' }))
            }.width('100%')
          }.height(50).width('100%').margin({ top: 10, bottom: 5 })

          Text('心情记录').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#333333').margin({ top: 8 })
          Row({ space: 8 }) {
            ForEach([0,1,2,3,4], (i: number) => {
              Button(['😭','😕','🙂','😊','🥳'][i]).height(36).borderRadius(18)
                .backgroundColor(this.moodIndex === i ? '#333333' : '#EEEEEE')
                .fontColor(this.moodIndex === i ? Color.White : Color.Black)
                .onClick(() => this.setMood(i))
            })
          }.width('90%').justifyContent(FlexAlign.Center)
          Row() {
            TextInput({ text: this.moodNote, placeholder: '写一句今天的心情...' })
              .layoutWeight(1).height(36).backgroundColor('#F9F9F9').borderRadius(18)
              .padding({ left: 12 }).onChange((v) => { this.moodNote = v; })
            Button('记录').width(70).height(36).backgroundColor('#333333').fontColor(Color.White)
              .borderRadius(18).margin({ left: 8 }).onClick(() => this.setMood(this.moodIndex >= 0 ? this.moodIndex : 2))
          }.width('90%')
          Column() {
            Text(this.goldQuote).fontSize(14).fontColor('#666666').textAlign(TextAlign.Center)
            Text(this.dailyTask).fontSize(13).fontColor('#999999').textAlign(TextAlign.Center).margin({ top: 4 })
          }.width('90%')
        }.width('100%').alignItems(HorizontalAlign.Center).padding({ bottom: 100 })
      }.width('100%').layoutWeight(1).align(Alignment.Top)

      BottomNavBar({ current: 'mood' }).width('100%')
    }
    .width('100%').height('100%').backgroundColor('#FAFAFA').padding({ top: 12, bottom: 12 })
  }
}
