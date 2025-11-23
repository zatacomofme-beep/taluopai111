import { router } from '@kit.ArkUI';

@Component
export struct BottomNavBar {
  @Prop current: string = 'index'; // index | breathing | mood

  /**
   * 构建底部导航并处理页面跳转（函数级注释）
   */
  build() {
    Row({ space: 8 }) {
      Button(this.current === 'index' ? '· 今日翻牌 ·' : '今日翻牌')
        .layoutWeight(1).height(48).borderRadius(24)
        .backgroundColor(this.current === 'index' ? '#333333' : '#EEEEEE')
        .fontColor(this.current === 'index' ? Color.White : Color.Black)
        .onClick(() => { if (this.current !== 'index') router.replaceUrl({ url: 'pages/Index' }); })

      Button(this.current === 'breathing' ? '· 呼吸引导 ·' : '呼吸引导')
        .layoutWeight(1).height(48).borderRadius(24)
        .backgroundColor(this.current === 'breathing' ? '#333333' : '#EEEEEE')
        .fontColor(this.current === 'breathing' ? Color.White : Color.Black)
        .onClick(() => { if (this.current !== 'breathing') router.replaceUrl({ url: 'pages/BreathingPage' }); })

      Button(this.current === 'mood' ? '· 心情记录 ·' : '心情记录')
        .layoutWeight(1).height(48).borderRadius(24)
        .backgroundColor(this.current === 'mood' ? '#333333' : '#EEEEEE')
        .fontColor(this.current === 'mood' ? Color.White : Color.Black)
        .onClick(() => { if (this.current !== 'mood') router.replaceUrl({ url: 'pages/MoodPage' }); })
    }
    .padding({ left: 12, right: 12, bottom: 10 })
    .width('100%').backgroundColor('#FAFAFA')
  }
}

