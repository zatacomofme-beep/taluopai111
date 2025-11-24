// 路径: ets/common/AIService.ts
// V8.0 商业化修正版：集成能量消耗检查与心情上下文注入

import http from '@ohos.net.http';
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import util from '@ohos.util';
import { BusinessError } from '@kit.BasicServicesKit';
import { TarotCard } from '../model/TarotData';
import { EnergyManager } from './EnergyManager'; // 新增
import { FortuneManager } from './FortuneManager'; // 新增

export interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

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
  private static readonly API_URL = 'https://ark.cn-beijing.volces.com/api/v3/chat/completions';
  private static readonly MODEL_ID = 'deepseek-v3-1-terminus';
  private static readonly PREF_NAME = 'healing_book_pref';
  private static readonly KEY_AI_API_KEY = 'ai_api_key';

  // 定义消耗规则
  public static readonly COST_PER_CHAT = 2; // 普通对话消耗 2 点
  public static readonly COST_DEEP_ANALYSIS = 5; // 首次深度分析消耗 5 点

  static async getApiKey(context: common.UIAbilityContext): Promise<string> {
    try {
      const pref = await preferences.getPreferences(context, AIService.PREF_NAME);
      const key = await pref.get(AIService.KEY_AI_API_KEY, '') as string;
      if (key && key.length > 0) return key;
      // 尝试从文件读取 (开发调试用)
      try {
        const path = `${context.filesDir}/ai_key.txt`;
        if (fs.accessSync(path)) {
          const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
          const stat = fs.statSync(path);
          const buffer = new ArrayBuffer(stat.size);
          fs.readSync(file.fd, buffer);
          fs.closeSync(file);
          const decoder = new util.TextDecoder();
          return decoder.decode(new Uint8Array(buffer)).trim();
        }
      } catch (e) {}
      return '';
    } catch (err) {
      return '';
    }
  }

  static async setApiKey(context: common.UIAbilityContext, key: string): Promise<void> {
    try {
      const pref = await preferences.getPreferences(context, AIService.PREF_NAME);
      await pref.put(AIService.KEY_AI_API_KEY, key);
      await pref.flush();
    } catch (err) {}
  }

  static createInitialPrompt(cards: TarotCard[]): string {
    return `
      我正在进行塔罗牌“时光流”牌阵占卜。
      【过去】：${cards[0].name} (${cards[0].meaning})
      【现在】：${cards[1].name} (${cards[1].meaning})
      【未来】：${cards[2].name} (${cards[2].meaning})
      请结合这三张牌的流变关系，给我一段温暖的分析。
      要求：语气温柔治愈，字数300字左右，结尾给一句祝福。
    `;
  }

  /**
   * 获取增强的系统人设 (包含今日心情)
   */
  private static async getEnhancedSystemPrompt(): Promise<string> {
    const manager = FortuneManager.getInstance();
    const moodData = await manager.getTodayMood();

    let moodContext = "";
    if (moodData.mood !== -1) {
      const moodEmojis = ['😭 悲伤', '😕 困惑', '🙂 平静', '😊 开心', '🥳 狂喜'];
      moodContext = `\n【用户今日状态】：用户今天在日记中记录的心情是“${moodEmojis[moodData.mood]}”，备注为：“${moodData.note}”。请在回答时，微妙地结合这个情绪状态，如果用户悲伤，请给予更多抚慰；如果用户开心，请一同庆祝。`;
    }

    return `你是一位名为“治愈之书”的专业塔罗分析师。
在进行牌阵解读时，语调温暖、治愈、富有文学性。
后续对话请保持专业理性的咨询师风格，逻辑清晰，不要过度煽情。
${moodContext}`;
  }

  static async requestChat(history: ChatMessage[], context: common.UIAbilityContext, isInitialAnalysis: boolean = false): Promise<string> {
    // 1. 检查能量
    const energyMgr = EnergyManager.getInstance();
    await energyMgr.init(context);
    const cost = isInitialAnalysis ? AIService.COST_DEEP_ANALYSIS : AIService.COST_PER_CHAT;

    if (!energyMgr.hasEnough(cost)) {
      return `✨ 心力值不足 (${energyMgr.getEnergy()}/${cost})。\n\n深度的疗愈需要消耗心力，请明日再来，或去“呼吸冥想”页面休息片刻。`;
    }

    const httpRequest = http.createHttp();

    // 2. 构建增强型 Prompt
    const sysContent = await AIService.getEnhancedSystemPrompt();
    const systemPrompt: ChatMessage = { role: "system", content: sysContent };

    let messagesToSend: ChatMessage[] = [...history];
    if (messagesToSend.length === 0 || messagesToSend[0].role !== 'system') {
      messagesToSend.unshift(systemPrompt);
    }

    try {
      const apiKey = await AIService.getApiKey(context);
      if (!apiKey) return '未配置 AI Key。';

      const response = await httpRequest.request(
        AIService.API_URL,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${apiKey}` },
          extraData: {
            model: AIService.MODEL_ID,
            messages: messagesToSend,
            max_tokens: 4096,
            temperature: 0.7
          },
          readTimeout: 60000
        }
      );

      if (response.responseCode === 200) {
        // 3. 成功后扣除能量
        await energyMgr.consume(cost);

        let resultStr = typeof response.result === 'string' ? response.result : JSON.stringify(response.result);
        const result = JSON.parse(resultStr) as AIResponse;
        return result.choices?.[0]?.message?.content || "AI 陷入沉思...";
      } else if (response.responseCode === 429) {
        return "✨ 宇宙信号太拥挤啦（限流），请稍后再试。";
      } else {
        return `连接断开 (Code: ${response.responseCode})。`;
      }
    } catch (err) {
      return "网络连接不稳定，无法连接到潜意识云端。";
    } finally {
      httpRequest.destroy();
    }
  }
}