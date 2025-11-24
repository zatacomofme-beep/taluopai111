import { systemShare } from '@kit.ShareKit';
import { common } from '@kit.AbilityKit';
import { componentSnapshot } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { fileIo as fs, fileUri } from '@kit.CoreFileKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

export class ShareHelper {
  static async snapshotAndShare(context: common.UIAbilityContext, componentId: string) {
    try {
      promptAction.showToast({ message: '正在生成分享卡片...', duration: 1000 });

      const pixelMap = await componentSnapshot.get(componentId);
      const fileName = `tarot_share_${new Date().getTime()}.jpg`;
      const filePath = `${context.cacheDir}/${fileName}`;

      const imagePacker = image.createImagePacker();
      const packOpts: image.PackingOption = { format: 'image/jpeg', quality: 90 };
      const data = await imagePacker.packing(pixelMap, packOpts);

      const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, data);
      fs.closeSync(file);

      const uri = fileUri.getUriFromPath(filePath);
      const utdTypeId = utd.getUniformDataTypeByFilenameExtension('.jpg', utd.UniformDataType.IMAGE);

      const shareData = new systemShare.SharedData({
        utd: utdTypeId,
        uri: uri,
        title: '治愈之书 · 今日指引',
        description: '快来看看我的塔罗牌运势吧！',
        thumbnail: new Uint8Array(data)
      });

      shareData.addRecord({ utd: utdTypeId, uri: uri });

      const controller = new systemShare.ShareController(shareData);
      await controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DEFAULT
      });

    } catch (err) {
      const error = err as BusinessError;
      console.error(`ShareHelper Error: ${error.code} - ${error.message}`);
      promptAction.showToast({ message: '分享调起失败，请重试', duration: 2000 });
    }
  }
}