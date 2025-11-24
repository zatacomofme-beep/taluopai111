import http from '@ohos.net.http';
import { promptAction } from '@kit.ArkUI';

export class CloudService {
  // 🔴 你的服务器地址 (确保端口是 3000)
  private static readonly BASE_URL = 'http://115.190.137.87:3000/api';
  private static readonly SERVER_ROOT = 'http://115.190.137.87:3000';

  /**
   * 💓 检查服务器健康状态
   * @returns true 表示连接正常
   */
  static async checkConnection(): Promise<boolean> {
    const httpRequest = http.createHttp();
    try {
      // 请求根路径，看是否返回 "正式版服务器运行正常"
      const response = await httpRequest.request(
        `${CloudService.SERVER_ROOT}/`,
        {
          method: http.RequestMethod.GET,
          readTimeout: 3000,
          connectTimeout: 3000
        }
      );
      return response.responseCode === 200;
    } catch (err) {
      console.error('CloudService: 连接检查失败', JSON.stringify(err));
      return false;
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 📤 上传备份数据
   */
  static async backupData(userId: string, token: string, allData: string): Promise<boolean> {
    const httpRequest = http.createHttp();
    try {
      console.info('CloudService: 开始上传备份...');
      const response = await httpRequest.request(
        `${CloudService.BASE_URL}/sync/upload`,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: {
            userId: userId,
            token: token,
            data: JSON.parse(allData)
          },
          expectDataType: http.HttpDataType.OBJECT,
          readTimeout: 10000,
          connectTimeout: 10000
        }
      );

      if (response.responseCode === 200) {
        const res = response.result as Record<string, Object>;
        return res['code'] === 200;
      }
      return false;
    } catch (err) {
      console.error('CloudService: 上传失败', JSON.stringify(err));
      promptAction.showToast({ message: '网络连接失败，请检查网络' });
      return false;
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 📥 从云端下载恢复数据
   */
  static async restoreData(userId: string, token: string): Promise<string | null> {
    const httpRequest = http.createHttp();
    try {
      console.info('CloudService: 开始下载备份...');
      const response = await httpRequest.request(
        `${CloudService.BASE_URL}/sync/download`,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: {
            userId: userId,
            token: token
          },
          expectDataType: http.HttpDataType.OBJECT,
          readTimeout: 10000,
          connectTimeout: 10000
        }
      );

      if (response.responseCode === 200) {
        const res = response.result as Record<string, Object>;
        if (res['code'] === 200 && res['data']) {
          return JSON.stringify(res['data']);
        }
      }
      return null;
    } catch (err) {
      console.error('CloudService: 下载失败', JSON.stringify(err));
      promptAction.showToast({ message: '网络连接失败，请检查网络' });
      return null;
    } finally {
      httpRequest.destroy();
    }
  }
}