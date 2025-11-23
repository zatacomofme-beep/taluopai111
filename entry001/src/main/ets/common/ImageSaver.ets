// 路径: ets/common/ImageSaver.ts
// V5.0 全版本兼容版：兼容鸿蒙 3.0/4.0/NEXT
// 核心思路：使用最底层的 FileSystem (fs) 写入公共目录，避开 API 版本差异

import { fileIo as fs } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

export class ImageSaver {
  /**
   * 保存图片到系统相册 (兼容 API 9 - 12)
   */
  /**
   * 保存图片到系统相册
   */
  static async saveToAlbum(context: common.UIAbilityContext, pixelMap: image.PixelMap) {
    try {
      // 1. 获取相册管理助手
      const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);

      // 2. 创建图片创建请求 (API 9+ 通用写法)
      // 使用 createAsset (旧版) 或 createImageAssetRequest (新版) 的兼容逻辑
      // 这里我们使用更底层的 createAsset 方式，它在 API 9 就存在了
      const assetUri = await phAccessHelper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg');

      // 3. 打开文件流 (READ_WRITE)
      // 这一步是通用的：只要拿到了 URI，就可以像操作普通文件一样写入数据
      const file = await fs.open(assetUri, fs.OpenMode.READ_WRITE);

      // 4. 将 PixelMap 打包成 JPG 数据
      const imagePacker = image.createImagePacker();
      const packOpts: image.PackingOption = { format: 'image/jpeg', quality: 92 };
      const imageBuffer = await imagePacker.packing(pixelMap, packOpts);

      // 5. 写入数据
      await fs.write(file.fd, imageBuffer);

      // 6. 关闭文件流
      await fs.close(file);

      promptAction.showToast({ message: '✅ 已保存到相册', duration: 2000 });

    } catch (err) {
      const error = err as BusinessError | Error | object;
      console.error('ImageSaver Error:', JSON.stringify(error));

      let msg = '保存失败，请重试';
      const errStr = JSON.stringify(error);

      // 权限错误判断
      if (errStr.includes('201') || errStr.includes('Permission')) {
        msg = '保存失败：请检查相册权限';
      }

      promptAction.showToast({ message: `❌ ${msg}`, duration: 2000 });
    }
  }
}
