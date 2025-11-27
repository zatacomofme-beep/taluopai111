import { router } from '@kit.ArkUI';

@Component
export struct BottomNavBar {
  @Prop current: string = 'index'; // index | breathing | mood | profile

  @Builder
  NavItem(key: string, icon: string, label: string, targetUrl: string) {
    Column() {
      // 图标容器
      Stack() {
        if (this.current === key) {
          // 选中态的光晕背景
          Circle({ width: 40, height: 40 })
            .fill('rgba(251, 114, 153, 0.1)')
            .scale({ x: 1, y: 1 })
            .animation({ duration: 300, curve: Curve.EaseOut })
        }
        Text(icon)
          .fontSize(24)
          .scale(this.current === key ? { x: 1.1, y: 1.1 } : { x: 1, y: 1 })
          .animation({ duration: 300, curve: Curve.Smooth })
      }
      .width(40)
      .height(40)

      // 文字标签
      Text(label)
        .fontSize(10)
        .fontColor(this.current === key ? '#FB7299' : '#B0B0B0')
        .margin({ top: 4 })
        .fontWeight(this.current === key ? FontWeight.Medium : FontWeight.Normal)
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .stateStyles({
      pressed: {
        .scale({ x: 0.9, y: 0.9 })
      },
      normal: {
        .scale({ x: 1, y: 1 })
      }
    })
    .onClick(() => {
      if (this.current !== key) {
        router.replaceUrl({ url: targetUrl });
      }
    })
  }

  build() {
    Row() {
      this.NavItem('index', '🔮', '指引', 'pages/Index')
      this.NavItem('breathing', '🌬️', '呼吸', 'pages/BreathingPage')
      this.NavItem('mood', '📝', '日记', 'pages/MoodPage')
      // 新增：个人中心入口
      this.NavItem('profile', '👤', '我的', 'pages/ProfilePage')
    }
    .width('90%')
    .height(70)
    .backgroundColor('rgba(255, 255, 255, 0.9)') // 略微增加不透明度
    .backdropBlur(20)
    .borderRadius(35)
    .shadow({ radius: 25, color: 'rgba(0,0,0,0.05)', offsetY: 8 })
    .padding({ left: 10, right: 10 })
    .margin({ bottom: 20 })
  }
}