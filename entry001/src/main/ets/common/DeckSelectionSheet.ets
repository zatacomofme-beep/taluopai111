import { DECK_LIST, DeckTheme, OBS_ROOT_URL } from '../model/TarotData';
import { promptAction } from '@kit.ArkUI';

/**
 * 牌组选择/购买组件
 * 功能：展示可用牌组列表，支持预览、购买解锁（模拟）和切换当前使用的牌组
 */
@Component
export struct DeckSelectionSheet {
  // 🔗 与 AppStorage 双向绑定，自动同步当前选中的牌组文件夹
  @StorageLink('CurrentDeckFolder') currentDeckFolder: string = DECK_LIST[0].folder;
  
  // 🔗 控制弹窗显示的绑定变量
  @Link isOpen: boolean;
  
  // 💾 已拥有的牌组 ID 列表 (注意：实际项目中应使用 Preferences 持久化存储)
  @State ownedDecks: string[] = ['default']; 

  build() {
    Column() {
      // 1. 顶部把手条 (视觉提示可拖动)
      Row()
        .width(40)
        .height(4)
        .backgroundColor('#E0E0E0')
        .borderRadius(2)
        .margin({ top: 12, bottom: 20 })

      // 2. 标题
      Text('🔮 牌组工坊')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      // 3. 牌组列表
      List({ space: 16 }) {
        ForEach(DECK_LIST, (deck: DeckTheme) => {
          ListItem() {
            Row() {
              // 🖼️ 牌组预览图 (直接拼接该牌组的路径)
              Image(`${OBS_ROOT_URL}${deck.folder}${deck.preview}`)
                .width(60)
                .height(100)
                .borderRadius(8)
                .objectFit(ImageFit.Cover)
                .backgroundColor('#f0f0f0')

              // 📝 牌组信息
              Column({ space: 8 }) {
                Text(deck.name)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                
                Text(deck.desc)
                  .fontSize(12)
                  .fontColor('#999')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                // 🔘 操作按钮区域
                Row() {
                  if (this.currentDeckFolder === deck.folder) {
                    // 状态：使用中
                    Text('使用中')
                      .fontSize(12)
                      .fontColor('#4CAF50')
                      .backgroundColor('#E8F5E9')
                      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                      .borderRadius(12)
                  } else {
                     // 逻辑：判断是否拥有 (免费或已购买)
                     if (deck.price === 0 || this.ownedDecks.includes(deck.id)) {
                        Button('使用')
                          .fontSize(12)
                          .height(28)
                          .backgroundColor('#2196F3')
                          .onClick(() => {
                            this.currentDeckFolder = deck.folder; // 切换全局牌组
                            promptAction.showToast({ message: `已切换至: ${deck.name}` });
                          })
                     } else {
                        Button(`解锁: ${deck.price} ⚡`)
                          .fontSize(12)
                          .height(28)
                          .backgroundColor('#FF9800')
                          .onClick(() => {
                            // 模拟购买流程
                            this.ownedDecks.push(deck.id);
                            this.currentDeckFolder = deck.folder; // 购买后自动切换
                            promptAction.showToast({ message: '购买成功！' });
                          })
                     }
                  }
                }
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 16 })
            }
            .padding(16)
            .backgroundColor('#FAFAFA')
            .borderRadius(16)
            .width('100%')
          }
        })
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 16, right: 16 })

      // 4. 关闭按钮
      Button('关闭')
        .width('90%')
        .height(48)
        .margin({ bottom: 16, top: 16 })
        .backgroundColor('#F5F5F5')
        .fontColor('#666')
        .onClick(() => {
          this.isOpen = false;
        })
    }
    .height('65%')
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 24, topRight: 24 })
  }
}