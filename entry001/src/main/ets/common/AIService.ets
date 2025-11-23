// 路径: ets/common/AIService.ts
// V7.2 优化版：调整 AI 人设，后续对话回归理性与专业

import http from '@ohos.net.http';
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import util from '@ohos.util';
import { BusinessError } from '@kit.BasicServicesKit';
import { TarotCard } from '../model/TarotData';

// 导出接口供页面使用
export interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

// 拆分嵌套接口，满足 ArkTS 严格检查
interface AIMessageContent {
  content: string;
}

interface AIChoice {
  message: AIMessageContent;
}

interface AIResponse {
  choices: AIChoice[];
}

export class AIService {
  // ⚠️ DeepSeek API 配置
  private static readonly API_URL = 'https://ark.cn-beijing.volces.com/api/v3/chat/completions';
  private static readonly MODEL_ID = 'deepseek-v3-1-terminus';
  private static readonly PREF_NAME = 'healing_book_pref';
  private static readonly KEY_AI_API_KEY = 'ai_api_key';

  /**
   * 读取保存在偏好中的 API Key
   * @param context UIAbility 上下文
   */
  static async getApiKey(context: common.UIAbilityContext): Promise<string> {
    try {
      const pref = await preferences.getPreferences(context, AIService.PREF_NAME);
      const key = await pref.get(AIService.KEY_AI_API_KEY, '') as string;
      if (key && key.length > 0) {
        return key;
      }
      try {
        const path = `${context.filesDir}/ai_key.txt`;
        const stat = fs.statSync(path);
        const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
        const buffer = new ArrayBuffer(stat.size);
        fs.readSync(file.fd, buffer);
        fs.closeSync(file);
        const decoder = new util.TextDecoder();
        const txt = decoder.decode(new Uint8Array(buffer)).trim();
        return txt || '';
      } catch (e) {
        const _err = e as Error;
      }
      return '';
    } catch (err) {
      const error = err as BusinessError | Error | object;
      console.error('AIService: getApiKey failed', JSON.stringify(error));
      return '';
    }
  }

  /**
   * 保存/更新 API Key 到偏好
   * @param context UIAbility 上下文
   * @param key API Key 字符串
   */
  static async setApiKey(context: common.UIAbilityContext, key: string): Promise<void> {
    try {
      const pref = await preferences.getPreferences(context, AIService.PREF_NAME);
      await pref.put(AIService.KEY_AI_API_KEY, key);
      await pref.flush();
    } catch (err) {
      const error = err as BusinessError | Error | object;
      console.error('AIService: setApiKey failed', JSON.stringify(error));
    }
  }

  /**
   * 生成初始的塔罗牌阵分析提示词
   * (这一段保留华丽风格，作为开场白)
   */
  static createInitialPrompt(cards: TarotCard[]): string {
    return `
      我正在进行塔罗牌“时光流”牌阵占卜。

      【过去】：${cards[0].name} (${cards[0].meaning})
      【现在】：${cards[1].name} (${cards[1].meaning})
      【未来】：${cards[2].name} (${cards[2].meaning})

      请结合这三张牌的流变关系，给我一段温暖的分析。
      要求：
      1. 语气要像老朋友一样温柔，带有治愈感。
      2. 不要生硬地解释牌义，要串联成一个故事或建议。
      3. 字数控制在 300 字左右。
      4. 结尾给我一句充满力量的简短祝福。
    `;
  }

  /**
   * 发送对话请求（支持上下文）
   * @param history 对话历史
   * @param context UIAbility 上下文（用于读取 API Key）
   */
  static async requestChat(history: ChatMessage[], context: common.UIAbilityContext): Promise<string> {
    const httpRequest = http.createHttp();

    // 🛠️ 核心修改：优化系统人设，强制 AI 在后续对话中“讲人话”
    const systemPrompt: ChatMessage = {
      role: "system",
      content: `你是一位名为“治愈之书”的专业塔罗分析师。
在进行初次牌阵解读时，你的语调是温暖、治愈、富有文学性的。
但在后续的对话互动中，请保持【正常、专业、直接】的沟通风格。
回答用户后续问题时，请像一位理性的心理咨询师或分析师，逻辑清晰，语言平实，不要使用过多的华丽辞藻、排比句或过度煽情。
只在用户显露出明显悲伤情绪时，才适度给予情感抚慰。`
    };

    // 确保第一条是系统人设
    let messagesToSend: ChatMessage[] = [...history];
    if (messagesToSend.length === 0 || messagesToSend[0].role !== 'system') {
      messagesToSend.unshift(systemPrompt);
    }

    try {
      console.info('AIService: 发送对话请求...', JSON.stringify(messagesToSend.length));
      const apiKey = await AIService.getApiKey(context);
      if (!apiKey) {
        return '未配置 AI Key，请先在应用设置中完成配置。';
      }
      const response = await httpRequest.request(
        AIService.API_URL,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${apiKey}`
          },
          extraData: {
            model: AIService.MODEL_ID,
            messages: messagesToSend,
            max_tokens: 4096,
            temperature: 0.7
          },
          readTimeout: 60000,
          connectTimeout: 60000
        }
      );

      if (response.responseCode === 200) {
        let resultStr = "";
        if (typeof response.result === 'string') {
          resultStr = response.result;
        } else {
          resultStr = JSON.stringify(response.result);
        }

        const result = JSON.parse(resultStr) as AIResponse;

        if (result.choices && result.choices.length > 0 && result.choices[0].message) {
          return result.choices[0].message.content;
        }
        return "AI 似乎陷入了沉思...";

      } else if (response.responseCode === 429) {
        return "✨ 宇宙信号太拥挤啦，请稍作休息再问我吧。（限流保护）";
      } else {
        console.error('AIService Error:', JSON.stringify(response));
        return `连接断开 (Code: ${response.responseCode})，请检查网络。`;
      }

    } catch (err) {
      const error = err as BusinessError | Error | object;
      console.error('AIService Network Error:', JSON.stringify(error));
      return "网络连接不稳定，无法连接到潜意识云端。";
    } finally {
      httpRequest.destroy();
    }
  }
}