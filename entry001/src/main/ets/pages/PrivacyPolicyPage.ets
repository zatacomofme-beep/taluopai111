import { router } from '@kit.ArkUI';

@Entry
@Component
struct PrivacyPolicyPage {
  @State title: string = '隐私政策';

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Image($r('app.media.startIcon')) // 使用 startIcon 作为返回图标
            .width(24).height(24)
            .rotate({ angle: 180 })
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
          .margin({ right: 40 })
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
          Text('更新日期：2025年1月1日')
            .fontSize(12).fontColor('#999').margin({ bottom: 20 }).alignSelf(ItemAlign.End)

          Text('欢迎您使用梦之书！李本世（以下简称“我们”）非常重视您的隐私保护。本隐私政策旨在向您说明我们如何收集、使用、存储和保护您的个人信息。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 20 })

          // 1. 我们如何保护您的个人信息
          Text('1、我们如何保护您的个人信息')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 12 })
          Text('我们采取业界标准的安全措施来保护您的个人信息，防止数据遭到未经授权的访问、公开披露、使用、修改、损坏或丢失。我们会采取一切合理可行的措施，保护您的个人信息。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 8 })
          Text('• 我们会使用加密技术确保数据的保密性。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ left: 10 })
          Text('• 我们会使用受信赖的保护机制防止数据遭到恶意攻击。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ left: 10 })
          Text('• 我们会部署访问控制机制，确保只有授权人员才可访问个人信息。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ left: 10, bottom: 20 })

          // 2. 第三方SDK调用说明
          Text('2、第三方SDK调用说明')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 12 })
          Text('为保障梦之书APP的稳定运行或实现相关功能，我们可能会接入由第三方提供的软件开发包（SDK）。我们会对合作方获取信息的软件工具开发包（SDK）进行严格的安全监测，以保护数据安全。目前我们接入的第三方SDK主要包括：')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 8 })
          
          Column() {
            Text('• 华为账号 SDK').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333').margin({ top: 4 })
            Text('  使用目的：帮助用户通过华为账号登录').fontSize(12).fontColor('#888').margin({ top: 2 })
            Text('  收集数据类型：设备标识符、网络信息').fontSize(12).fontColor('#888').margin({ top: 2 })

            Text('• 云空间服务 SDK').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333').margin({ top: 12 })
            Text('  使用目的：为您提供数据云端备份与恢复服务').fontSize(12).fontColor('#888').margin({ top: 2 })
            Text('  收集数据类型：应用数据、设备信息').fontSize(12).fontColor('#888').margin({ top: 2 })
          }.alignItems(HorizontalAlign.Start).padding({ left: 10, bottom: 20 }).width('100%')

          // 3. 您的权利
          Text('3、您的权利')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 12 })
          Text('按照中国相关的法律、法规、标准，我们保障您对自己的个人信息行使以下权利：')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 8 })
          Column() {
            Text('• 访问您的个人信息：您有权访问您的头像、昵称等基本信息。').fontSize(14).fontColor('#666').lineHeight(22)
            Text('• 更正您的个人信息：当您发现我们处理的关于您的个人信息有错误时，您有权要求我们做出更正。').fontSize(14).fontColor('#666').lineHeight(22).margin({ top: 4 })
            Text('• 删除您的个人信息：您可以随时联系我们要求删除您的账户及相关数据。').fontSize(14).fontColor('#666').lineHeight(22).margin({ top: 4 })
            Text('• 撤回同意：您可以随时在设置中关闭隐私模式或退出登录来撤回相关授权。').fontSize(14).fontColor('#666').lineHeight(22).margin({ top: 4 })
          }.alignItems(HorizontalAlign.Start).padding({ left: 10, bottom: 20 })

          // 4. 本政策如何更新
          Text('4、本政策如何更新')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 12 })
          Text('我们的隐私政策可能变更。未经您明确同意，我们不会削减您按照本隐私政策所应享有的权利。我们会在本页面上发布对本政策所做的任何变更。对于重大变更，我们还会提供更为显著的通知（包括对于某些服务，我们会通过弹窗发送通知，说明隐私政策的具体变更内容）。')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 20 })

          // 5. 如何联系我们
          Text('5、如何联系我们')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333').margin({ bottom: 12 })
          Text('如果您对本隐私政策有任何疑问、意见或建议，通过以下方式与我们联系：')
            .fontSize(14).fontColor('#666').lineHeight(22).margin({ bottom: 8 })
          
          Row() {
            Text('电子邮件：').fontSize(14).fontColor('#666')
            Text('alizabos@163.com')
              .fontSize(14).fontColor('#FF69B4').fontWeight(FontWeight.Bold)
              .copyOption(CopyOptions.LocalDevice)
          }.margin({ bottom: 8 })
          
          Text('一般情况下，我们将在15个工作日内回复。')
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