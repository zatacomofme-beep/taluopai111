import { router } from '@kit.ArkUI';

@Component
export struct BottomNavBar {
  @Prop current: string = 'index'; // index | breathing | mood

  @Builder
  NavItem(key: string, icon: string, label: string, targetUrl: string) {
    Column() {
      // 图标容器
      Stack() {
        if (this.current === key) {
          // 选中态的光晕背景
          Circle({ width: 40, height: 40 })
            .fill('rgba(255, 105, 180, 0.15)')
            .scale({ x: 1, y: 1 })
            .animation({ duration: 300, curve: Curve.EaseOut })
        }
        Text(icon)
          .fontSize(24)
          .scale(this.current === key ? { x: 1.1, y: 1.1 } : { x: 1, y: 1 })
          // 🛠️ 修复：Curve.Spring 不存在，改为 Curve.Smooth
          .animation({ duration: 300, curve: Curve.Smooth })
      }
      .width(40)
      .height(40)

      // 文字标签
      Text(label)
        .fontSize(10)
        .fontColor(this.current === key ? '#FF69B4' : '#999999')
        .margin({ top: 4 })
        .fontWeight(this.current === key ? FontWeight.Medium : FontWeight.Normal)
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (this.current !== key) {
        router.replaceUrl({ url: targetUrl });
      }
    })
  }

  build() {
    Row() {
      this.NavItem('index', '🔮', '今日指引', 'pages/Index')
      this.NavItem('breathing', '🌬️', '呼吸冥想', 'pages/BreathingPage')
      this.NavItem('mood', '📝', '心情日记', 'pages/MoodPage')
    }
    .width('90%')
    .height(70)
    .backgroundColor('rgba(255, 255, 255, 0.85)') // 半透明白
    .backdropBlur(20) // 毛玻璃模糊
    .borderRadius(35) // 胶囊圆角
    .shadow({ radius: 30, color: 'rgba(0,0,0,0.08)', offsetY: 10 }) // 柔和阴影
    .padding({ left: 10, right: 10 })
    .margin({ bottom: 20 }) // 悬浮距离底部
  }
}