// 路径: ets/widget/pages/DailyCardCard.ets
// 桌面卡片 UI：展示今日抽到的牌

@Entry
@Component
struct DailyCardCard {
  /*
   *LocalStorage 是卡片和 App 通信的桥梁。
   * App 里把数据存进 LocalStorage，卡片就能读到。
   */
  @LocalStorageProp('cardImage') cardImage: string = 'card_back.png';
  @LocalStorageProp('cardName') cardName: string = '今日指引';
  @LocalStorageProp('cardDesc') cardDesc: string = '点击抽取你的专属治愈';
  @LocalStorageProp('goldQuote') goldQuote: string = '';
  @LocalStorageProp('dailyTask') dailyTask: string = '';
  @LocalStorageProp('moodNote') moodNote: string = '';
  @LocalStorageProp('privacyMode') privacyMode: boolean = false;

  build() {
    Stack() {
      // 1. 背景图 (铺满)
      Image($rawfile(this.cardImage))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .borderRadius(12)

      // 2. 黑色半透明遮罩 (为了让文字更清晰)
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.3)')
        .borderRadius(12)

      // 3. 文字内容
      Column() {
        Blank() // 把文字推到底部

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
      // 点击卡片，唤起主 App
      postCardAction(this, {
        "action": "router",
        "abilityName": "EntryAbility",
        "params": {
          "targetPage": "index"
        }
      });
    })
  }
}
