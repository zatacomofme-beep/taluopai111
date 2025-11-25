// 路径: ets/dailycard/pages/DailyCardCard.ets
@Entry
@Component
struct DailyCardCard {
  @LocalStorageProp('cardImage') cardImage: string = 'card_back.png';
  @LocalStorageProp('cardName') cardName: string = '今日指引';
  @LocalStorageProp('cardDesc') cardDesc: string = '点击抽取你的专属治愈';
  @LocalStorageProp('goldQuote') goldQuote: string = '';
  @LocalStorageProp('dailyTask') dailyTask: string = '';
  @LocalStorageProp('moodNote') moodNote: string = '';
  @LocalStorageProp('privacyMode') privacyMode: boolean = false;

  build() {
    Stack() {
      // 🟢 修复：智能加载图片
      // 如果是 http 链接，直接加载；如果是文件名，加载 rawfile
      Image(this.cardImage.startsWith('http') ? this.cardImage : $rawfile(this.cardImage))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .borderRadius(12)
        .alt($rawfile('card_back.png')) // 加载失败显示背面

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.3)')
        .borderRadius(12)

      Column() {
        Blank()

        Text(this.cardName)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ bottom: 2 })

        Text(this.cardDesc)
          .fontSize(10)
          .fontColor('rgba(255,255,255,0.8)')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (!this.privacyMode && (this.moodNote || this.goldQuote || this.dailyTask)) {
          Text(this.moodNote || this.goldQuote || this.dailyTask)
            .fontSize(10)
            .fontColor('rgba(255,255,255,0.8)')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 2 })
        }
      }
      .width('100%')
      .height('100%')
      .padding(10)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .onClick(() => {
      postCardAction(this, {
        "action": "router",
        "abilityName": "Entry001Ability",
        "params": {
          "targetPage": "index"
        }
      });
    })
  }
}