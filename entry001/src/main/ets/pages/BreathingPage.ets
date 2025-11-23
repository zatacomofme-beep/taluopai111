import { router } from '@kit.ArkUI';
import { BottomNavBar } from '../common/BottomNavBar';

@Entry
@Component
export struct BreathingPage {
  @State breathingPhase: string = '准备';
  @State breathingRemaining: number = 60;
  // 呼吸动画控制变量
  @State scaleValue: number = 1;
  @State opacityValue: number = 0.6;
  @State circleColor: string = '#A8D8EA'; // 初始清透蓝

  private breathingTimerId: number | null = null;

  /**
   * 采用 4-2-6 舒缓呼吸法 (总周期 12s)
   * 吸气 4s -> 屏息 2s -> 呼气 6s
   * 这种节奏能有效激活副交感神经，帮助放松。
   */
  startBreathingGuide(seconds: number) {
    this.breathingRemaining = seconds;
    this.breathingPhase = '吸气';
    if (this.breathingTimerId) { clearInterval(this.breathingTimerId); this.breathingTimerId = null; }

    // 立即开始第一次吸气 (4s)
    this.animateBreath('in', 4000);

    const t = setInterval(() => {
      if (this.breathingRemaining <= 0) { this.stopBreathingGuide(); return; }

      // 计算当前周期内的剩余时间点
      // 倒计时逻辑：60 -> 59 -> ...
      // 周期 12s:
      // 12, 0  -> 开始吸气 (持续4s: 12,11,10,9)
      // 8      -> 开始屏息 (持续2s: 8,7)
      // 6      -> 开始呼气 (持续6s: 6,5,4,3,2,1)

      const mod = this.breathingRemaining % 12;

      if (mod === 8) {
        // 剩余 8s 时（即吸气 4s 结束），进入屏息
        if (this.breathingPhase !== '屏息') {
          this.breathingPhase = '屏息';
          this.animateBreath('hold', 2000);
        }
      } else if (mod === 6) {
        // 剩余 6s 时（即屏息 2s 结束），进入呼气
        if (this.breathingPhase !== '呼气') {
          this.breathingPhase = '呼气';
          this.animateBreath('out', 6000);
        }
      } else if (mod === 0) {
        // 剩余 0s (即 12s，呼气 6s 结束)，新循环开始吸气
        // 防止在最后 0s 重复触发
        if (this.breathingRemaining !== 0 && this.breathingPhase !== '吸气') {
          this.breathingPhase = '吸气';
          this.animateBreath('in', 4000);
        }
      }

      this.breathingRemaining -= 1;
    }, 1000);
    this.breathingTimerId = t as number;
  }

  animateBreath(type: 'in' | 'out' | 'hold', duration: number) {
    if (type === 'in') {
      // 吸气：变大，变亮，暖色
      animateTo({ duration: duration, curve: Curve.EaseInOut }, () => {
        this.scaleValue = 1.5;
        this.opacityValue = 1.0;
        this.circleColor = '#FFB6C1'; // 樱花粉
      });
    } else if (type === 'hold') {
      // 屏息：保持状态 (使用 Linear 确保平滑过渡)
      animateTo({ duration: duration, curve: Curve.Linear }, () => {
        this.scaleValue = 1.55; // 微微再大一点点，模拟充满气的感觉
        this.opacityValue = 1.0;
        this.circleColor = '#FFD700'; // 温暖金 (提示保持)
      });
    } else if (type === 'out') {
      // 呼气：回缩，变淡，冷色
      animateTo({ duration: duration, curve: Curve.EaseInOut }, () => {
        this.scaleValue = 1.0;
        this.opacityValue = 0.6;
        this.circleColor = '#A8D8EA'; // 清透蓝
      });
    }
  }

  stopBreathingGuide() {
    if (this.breathingTimerId) { clearInterval(this.breathingTimerId); this.breathingTimerId = null; }
    this.breathingPhase = '完成';
    animateTo({ duration: 1000 }, () => { this.scaleValue = 1; this.opacityValue = 0.6; this.circleColor = '#A8D8EA'; });
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 全局背景：柔和渐变
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [['#FDFBFB', 0.0], ['#EBEDEE', 1.0]]
        })

      Column() {
        // 顶部标题区
        Row() {
          Text('呼吸引导')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')

          Blank()

          Button({ type: ButtonType.Circle }) {
            Text('✕').fontSize(16).fontColor('#999999')
          }
          .width(36).height(36).backgroundColor('rgba(0,0,0,0.05)')
          // 🛠️ 修复：点击关闭按钮改为返回上一页，而不是强制跳回主页
          // 如果你需要强制回主页，保留 replaceUrl('pages/Index') 也可以，
          // 但 router.back() 通常体验更好。
          .onClick(() => router.back())
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 20 })

        // 核心动画区
        Stack() {
          // 外层光晕
          Circle({ width: 220, height: 220 })
            .fill(this.circleColor)
            .opacity(this.opacityValue * 0.3)
            .scale({ x: this.scaleValue * 1.2, y: this.scaleValue * 1.2 })
            .animation({ duration: 1000 }) // 跟随主圆稍慢

          // 主呼吸圆
          Circle({ width: 220, height: 220 })
            .fill(this.circleColor)
            .opacity(this.opacityValue)
            .scale({ x: this.scaleValue, y: this.scaleValue })
            .shadow({ radius: 30, color: this.circleColor, offsetY: 0 })

          // 文字提示
          Column() {
            Text(this.breathingPhase)
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .shadow({ radius: 5, color: 'rgba(0,0,0,0.2)' })

            if(this.breathingRemaining < 60 && this.breathingPhase !== '完成') {
              Text(`${this.breathingRemaining}s`)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('rgba(255,255,255,0.9)')
                .margin({ top: 8 })
            }
          }
        }
        .layoutWeight(1) // 占据剩余空间，居中
        .alignContent(Alignment.Center)

        // 控制区
        Column({ space: 20 }) {
          Text('吸气 4s - 屏息 2s - 呼气 6s')
            .fontSize(14)
            .fontColor('#888888')
            .textAlign(TextAlign.Center)
            .opacity(0.8)

          Text('跟随圆环的律动，让身心回归平静。')
            .fontSize(14)
            .fontColor('#666666')
            .textAlign(TextAlign.Center)

          Row({ space: 20 }) {
            Button('开始练习')
              .backgroundColor('#333333')
              .fontColor(Color.White)
              .width(140)
              .height(48)
              .borderRadius(24)
              .shadow({ radius: 10, color: 'rgba(0,0,0,0.2)', offsetY: 5 })
              .onClick(() => this.startBreathingGuide(60))

            Button('停止')
              .backgroundColor('#FFFFFF')
              .fontColor('#333333')
              .width(140)
              .height(48)
              .borderRadius(24)
              .border({ width: 1, color: '#EEEEEE' })
              .onClick(() => this.stopBreathingGuide())
          }
        }
        .margin({ bottom: 120 }) // 留出底部导航栏位置
      }
      .width('100%')
      .height('100%')

      // 悬浮导航栏
      // 这里的 current='breathing' 是正确的，确保底栏高亮正确
      BottomNavBar({ current: 'breathing' })
    }
    .width('100%')
    .height('100%')
  }
}