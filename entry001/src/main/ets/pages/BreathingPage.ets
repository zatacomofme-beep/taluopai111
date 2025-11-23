import { router } from '@kit.ArkUI';
import { BottomNavBar } from '../common/BottomNavBar';

@Entry
@Component
export struct BreathingPage {
  @State breathingPhase: string = '准备';
  @State breathingRemaining: number = 60;
  private breathingTimerId: number | null = null;

  /**
   * 开始呼吸引导（函数级注释）
   */
  startBreathingGuide(seconds: number) {
    this.breathingRemaining = seconds;
    this.breathingPhase = '吸气';
    if (this.breathingTimerId) { clearInterval(this.breathingTimerId); this.breathingTimerId = null; }
    const t = setInterval(() => {
      if (this.breathingRemaining <= 0) { this.stopBreathingGuide(); return; }
      const mod = this.breathingRemaining % 6;
      if (mod >= 4) { this.breathingPhase = '吸气'; }
      else if (mod >= 2) { this.breathingPhase = '停留'; }
      else { this.breathingPhase = '呼气'; }
      this.breathingRemaining -= 1;
    }, 1000);
    this.breathingTimerId = t as number;
  }

  /**
   * 停止呼吸引导（函数级注释）
   */
  stopBreathingGuide() {
    if (this.breathingTimerId) { clearInterval(this.breathingTimerId); this.breathingTimerId = null; }
    this.breathingPhase = '完成';
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

          Text('呼吸引导').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#333333').margin({ top: 8 })
          Text(`阶段：${this.breathingPhase}`).fontSize(14).fontColor('#666666')
          Progress({ value: 60 - this.breathingRemaining, total: 60, type: ProgressType.Linear }).width('90%')
          Row({ space: 12 }) {
            Button('开始 60s').height(42).borderRadius(21).backgroundColor('#E6F2FF').fontColor('#1A73E8').onClick(() => this.startBreathingGuide(60))
            Button('结束').height(42).borderRadius(21).backgroundColor('#F0F0F0').fontColor('#333333').onClick(() => this.stopBreathingGuide())
          }.justifyContent(FlexAlign.Center).width('100%')
          Column({ space: 8 }) {
            Text('提示').fontSize(16).fontWeight(FontWeight.Medium)
            Text('跟随节奏：吸气-停留-呼气；注意放松肩颈与下颌。').fontSize(14).fontColor('#666666')
          }.width('90%')
        }.width('100%').alignItems(HorizontalAlign.Center).padding({ bottom: 100 })
      }.width('100%').layoutWeight(1).align(Alignment.Top)

      BottomNavBar({ current: 'breathing' }).width('100%')
    }
    .width('100%').height('100%').backgroundColor('#FAFAFA').padding({ top: 12, bottom: 12 })
  }
}
