import { router } from '@kit.ArkUI';

@Entry
@Component
struct UserAgreementPage {
  @State title: string = '用户服务协议';

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Text('<')
            .fontSize(24)
            .fontColor('#333')
            .fontWeight(FontWeight.Medium)
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back();
        })

        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 40 }) // 平衡左侧按钮宽度，使标题居中
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)
      .shadow({ radius: 2, color: 'rgba(0,0,0,0.05)', offsetY: 1 })
      .zIndex(1)

      // 内容区域
      Scroll() {
        Column() {
          Text('欢迎使用梦之书！李本世（下称“梦之书”）负责梦之书手机应用软件的运营、管理。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 12 })

          Text('本协议由您与梦之书共同缔结，本协议具有合同效力，本协议中协议双方合称协议方。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 12 })

          Text('本协议内容包括协议正文及所有梦之书已经发布的或将来可能发布的各类规则，所有规则为本协议不可分割的组成部分，与协议正文具有同等法律效力。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 12 })

          Text('本协议阐述之条款和条件适用于梦之书手机应用软件的全部学习服务。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 12 })

          Text('您应当在使用梦之书服务之前认真阅读全部协议内容(未成年人应在法定监护人陪同下阅读)。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 12 })

          Text('如对协议有任何疑问，应向梦之书咨询，咨询邮箱：')
            .fontSize(14).fontColor('#666').lineHeight(22)
          Text('alizabos@163.com')
            .fontSize(14).fontColor('#FF69B4').fontWeight(FontWeight.Bold).lineHeight(22).margin({ bottom: 12 })
            .copyOption(CopyOptions.LocalDevice)

          Text('但无论您事实上是否在使用梦之书服务之前认真阅读了本协议内容，只要使用梦之书及相关服务，则本协议即对您产生约束，届时您不应以未阅读本协议的内容或者未获得梦之书对您问询的解答等理由，主张本协议无效，或要求撤销本协议。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 12 })

          Text('您承诺接受并遵守本协议的约定。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 12 })

          Text('如果您不同意本协议的约定，应立即停止注册程序或停止使用梦之书服务。梦之书团队有权根据相关法律法规的变更或业务变化等不时地制订、修改本协议及/或各类规则，并将调整后的协议公布于梦之书APP中。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 12 })

          Text('如您不同意相关变更，应当立即停止使用梦之书服务。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 20 })

          // 1. 梦之书服务条款
          Text('1、梦之书服务条款')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 12, top: 10 })
          Text('梦之书提供的服务将完全按照服务条款严格执行。您必须完全同意所有服务条款并完成注册程序，才能成为梦之书的正式用户。考虑到梦之书所提供的网络服务的重要性，您应同意：')
            .fontSize(14).fontColor('#666').lineHeight(22)
          Text('• 提供真实、准确的个人资料。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ left: 10 })
          Text('• 如个人资料有任何变动，必须及时更新。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ left: 10, bottom: 8 })
          Text('梦之书不会公开您的姓名、地址、电子邮箱、证件等相关信息，除以下情况外：')
            .fontSize(14).fontColor('#666').lineHeight(22)
          Text('• 您授权梦之书透露这些信息。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ left: 10 })
          Text('• 相关政府主管部门或有关法律法规要求梦之书提供您的个人资料。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ left: 10, bottom: 20 })

          // 2. 服务条款的修改和服务修订
          Text('2、服务条款的修改和服务修订')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 12 })
          Text('梦之书有权在必要时修改服务条款，梦之书服务条款一旦发生变动，将会在相关页面上提示修改内容。如果不同意所改动的内容，您可以主动取消获得的网络服务。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 8 })
          Text('如果您继续享用网络服务，则视为接受服务条款的变动。梦之书保留随时修改或中断服务而不需个别知照您的权利。梦之书行使修改或中断免费服务的权利，不需对您或第三方负责。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 20 })

          // 3. 您的帐号，密码和安全性
          Text('3、您的帐号，密码和安全性')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 12 })
          Text('您通过手机号或其他关联账号注册并登录，成为梦之书的合法用户。如果您未保管好自己的登录账户而对您、梦之书或第三方造成的损害，您将负全部责任。另外，每个用户都要对其帐户中的所有活动和事件负全责。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 20 })

          // 4. 拒绝提供担保
          Text('4、拒绝提供担保')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 12 })
          Text('您个人对网络服务的使用承担风险。梦之书对此不作任何类型的担保，不论是明确的或隐含的。梦之书不担保服务一定能满足您的要求，也不担保服务不会受中断，对服务的及时性，安全性，出错发生都不作担保。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 20 })

          // 5. 有限责任
          Text('5、有限责任')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 12 })
          Text('梦之书对任何直接、间接、偶然、特殊及继起的损害不负责任，这些行为都有可能会导致梦之书的形象受损，所以梦之书事先提出这种损害的可能性。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 20 })

          // 6. 用户管理
          Text('6、用户管理')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 12 })
          Text('6.1 用户使用梦之书各项服务的权利是个人的。用户承诺不经梦之书同意，不能利用梦之书各项服务、资讯、资料、数据等进行销售或其他商业用途。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 8 })
          Text('6.2 用户单独承担发布内容的责任。用户对服务的使用或在梦之书发表的内容（包含但不限于梦之书目前各产品功能里的内容）仅表明其个人的立场和观点，并不代表梦之书的立场或观点。作为内容的发表者，需自行对所发表的内容以及其他任何形式关于梦之书的内容负责（如包含梦之书内容的邮件、短信、电话录音等），因所发表内容引发的一切纠纷，由该内容的发表者承担全部法律及连带责任。梦之书不承担任何法律及连带责任。利用梦之书的服务时必须符合中国有关法规，不得利用梦之书的服务制作、复制、发布、传播以下信息：')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 8 })
          
          Column() {
            Text('• 反对宪法所确定的基本原则的；').fontSize(14).fontColor('#666').lineHeight(22)
            Text('• 危害国家安全，泄露国家秘密，颠覆国家政权，破坏国家统一的；').fontSize(14).fontColor('#666').lineHeight(22)
            Text('• 损害国家荣誉和利益的；').fontSize(14).fontColor('#666').lineHeight(22)
            Text('• 煽动民族仇恨、民族歧视，破坏民族团结的；').fontSize(14).fontColor('#666').lineHeight(22)
            Text('• 破坏国家宗教政策，宣扬邪教和封建迷信的；').fontSize(14).fontColor('#666').lineHeight(22)
            Text('• 散布谣言，扰乱社会秩序，破坏社会稳定的；').fontSize(14).fontColor('#666').lineHeight(22)
            Text('• 散布淫秽、色情、赌博、暴力、凶杀、恐怖或者教唆犯罪的；').fontSize(14).fontColor('#666').lineHeight(22)
            Text('• 侮辱或者诽谤他人，侵害他人合法权益的；').fontSize(14).fontColor('#666').lineHeight(22)
            Text('• 含有法律、行政法规禁止的其他内容的。').fontSize(14).fontColor('#666').lineHeight(22)
          }.alignItems(HorizontalAlign.Start).padding({ left: 10 })

          Text('6.3 利用梦之书的服务时还必须符合其他有关国家和地区的法律规定以及国际法的有关规定。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ top: 8, bottom: 8 })
          
          Text('6.4 不利用梦之书的服务从事以下活动：')
            .fontSize(14).fontColor('#666').lineHeight(22)
          Column() {
            Text('• 未经允许，进入计算机信息网络或者使用计算机信息网络资源的；').fontSize(14).fontColor('#666').lineHeight(22)
            Text('• 未经允许，对计算机信息网络功能进行删除、修改或者增加的；').fontSize(14).fontColor('#666').lineHeight(22)
            Text('• 未经允许，对进入计算机信息网络中存储、处理或者传输的数据和应用程序进行删除、修改或者增加的；').fontSize(14).fontColor('#666').lineHeight(22)
            Text('• 故意制作、传播计算机病毒等破坏性程序的；').fontSize(14).fontColor('#666').lineHeight(22)
            Text('• 其他危害计算机信息网络安全的行为。').fontSize(14).fontColor('#666').lineHeight(22)
          }.alignItems(HorizontalAlign.Start).padding({ left: 10 })

          Text('6.5 不以任何方式干扰梦之书的服务。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ top: 8, bottom: 8 })
          Text('6.6 遵守梦之书的所有其他规定和程序。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 8 })
          
          Text('用户使用梦之书电子公告服务，即用户利用梦之书交互形式的栏目或功能，进行信息发布的行为，也须遵守本条的规定以及梦之书专门发布的相关电子公告服务的规则，上段中描述的法律后果和法律责任同样适用于电子公告服务的用户。若用户的行为不符合以上提到的服务条款，梦之书将作出独立判断立即取消用户服务帐号。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 20 })

          // 7. 保障
          Text('7、保障')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 12 })
          Text('用户同意保障和维护梦之书全体成员的利益，并负责支付由用户使用超出服务范围引起的律师费用，违反服务条款的损害补偿费用等。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 20 })

          // 8. 结束服务
          Text('8、结束服务')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 12 })
          Text('用户或梦之书可随时根据实际情况中断一项或多项网络服务。梦之书不需对任何个人或第三方负责而随时中断服务。用户对后来的条款修改有异议，或对梦之书的服务不满，可以行使如下权利：')
            .fontSize(14).fontColor('#666').lineHeight(22)
          Column() {
            Text('• 停止使用梦之书的网络服务。').fontSize(14).fontColor('#666').lineHeight(22)
            Text('• 通告梦之书停止对该用户的服务。').fontSize(14).fontColor('#666').lineHeight(22)
          }.alignItems(HorizontalAlign.Start).padding({ left: 10 })
          Text('结束用户服务后，用户使用网络服务的权利马上中止。从那时起，用户没有权利，梦之书也没有义务传送任何未处理的信息或未完成的服务给用户或第三方。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ top: 8, bottom: 20 })

          // 9. 通告
          Text('9、通告')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 12 })
          Text('所有发给用户的通告都可通过相关页面的公告或电子邮件或常规的信件等传送。服务条款的修改、服务变更、或其它重要事件的通告都会以此形式进行。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 20 })

          // 10. 网络服务内容的所有权
          Text('10、网络服务内容的所有权')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 12 })
          Text('梦之书定义的网络服务内容包括：文字、软件、声音、图片、录象、图表中的全部内容；电子邮件的全部内容；梦之书为用户提供的其他信息。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 8 })
          Text('所有这些内容受版权、商标、标签和其它财产所有权法律的保护。所以，用户只能在梦之书授权下才能使用这些内容，而不能擅自复制、再造这些内容、或创造与内容有关的衍生产品。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 20 })

          // 11. 法律
          Text('11、法律')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 12 })
          Text('网络服务条款要与中华人民共和国的法律解释相一致，用户和梦之书一致同意服从四川省人民法院的管辖。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 8 })
          Text('如发生梦之书服务条款与中华人民共和国法律相抵触时，则这些条款将完全按法律规定重新解释，而其它条款则依旧保持对用户产生法律效力和影响。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 40 })

        }
        .alignItems(HorizontalAlign.Start)
        .padding(20)
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .align(Alignment.TopStart)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F9F9F9')
  }
}