// 路径: ets/common/ShareHelper.ts
// V3.2 修复版：适配 HarmonyOS NEXT Kit 导入规范，解决模块找不到的问题

// 🛠️ 核心修改：使用 @kit.xxx 替代 @ohos.xxx
import { systemShare } from '@kit.ShareKit';
import { common } from '@kit.AbilityKit';
import { componentSnapshot } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit'; // 用于错误类型断言

export class ShareHelper {
  /**
   * 截取组件并调用系统分享
   * @param context 上下文
   * @param componentId 组件ID
   */
  static async snapshotAndShare(context: common.UIAbilityContext, componentId: string) {
    try {
      promptAction.showToast({ message: '正在生成分享卡片...', duration: 1000 });

      // 1. 组件截图
      const pixelMap = await componentSnapshot.get(componentId);

      // 2. 保存到沙箱 (Cache 目录)
      const fileName = `tarot_share_${new Date().getTime()}.jpg`;
      const filePath = `${context.cacheDir}/${fileName}`;

      const imagePacker = image.createImagePacker();
      const packOpts: image.PackingOption = { format: 'image/jpeg', quality: 90 };
      const data = await imagePacker.packing(pixelMap, packOpts);

      const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, data);
      fs.closeSync(file);

      // 3. 获取 URI
      // 使用 Kit 导入后的 fileUri
      const uri = fileUri.getUriFromPath(filePath);

      // 4. 构建分享数据
      const utdTypeId = utd.getUniformDataTypeByFilenameExtension('.jpg', utd.UniformDataType.IMAGE);

      const shareData = new systemShare.SharedData({
        utd: utdTypeId,
        uri: uri,
        title: '治愈之书 · 今日指引',
        description: '快来看看我的塔罗牌运势吧！',
        thumbnail: new Uint8Array(data)
      });

      // 添加记录
      shareData.addRecord({
        utd: utdTypeId,
        uri: uri
      });

      // 5. 启动系统分享面板
      const controller = new systemShare.ShareController(shareData);
      await controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DEFAULT
      });

    } catch (err) {
      // 🛠️ 修复：显式断言错误类型，解决 Strict Mode 报错
      const error = err as BusinessError;
      console.error(`ShareHelper Error: ${error.code} - ${error.message}`);
      promptAction.showToast({ message: '分享调起失败，请重试', duration: 2000 });
    }
  }
}