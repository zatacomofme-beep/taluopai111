import http from '@ohos.net.http';
import common from '@ohos.app.ability.common';
import { TarotCard } from '../model/TarotData';
import { EnergyManager } from './EnergyManager';
import { FortuneManager, MoodToday } from './FortuneManager';

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
  // 🔴 核心修改：换成你的华为云服务器公网 IP
  private static readonly MY_SERVER_URL = 'http://1.94.149.144:3000/api/ai/chat';

  public static readonly COST_PER_CHAT = 2;
  public static readonly COST_DEEP_ANALYSIS = 5;

  static createInitialPrompt(cards: TarotCard[], lastMood?: MoodToday): string {
    let moodInstruction = "";
    let openingInstruction = "";

    // 场景 1：有心情记录
    if (lastMood && lastMood.mood !== -1) {
      const emojis = ['😭 悲伤', '😕 困惑', '🙂 平静', '😊 开心', '🥳 狂喜'];
      const moodText = emojis[lastMood.mood] || '未知';
      const noteText = lastMood.note ? `备注：“${lastMood.note}”` : '';

      moodInstruction = `【用户当前状态】：${moodText}。${noteText}。`;

      openingInstruction = `
      1. **开场白（情感共鸣 + 牌面切入）**：
         - 第一句必须先回应用户的心情。
         - 紧接着引出对第一张牌的冷读。
      `;
    } else {
      // 场景 2：没有心情记录 -> 直接冷读
      openingInstruction = `
      1. **开场白（直击重点）**：
         - 请务必直接以“从‘${cards[0].name}’这张代表过去的牌面来看...”开头。
      `;
    }

    return `
      ${moodInstruction}
      你是一位经验丰富、直觉敏锐且充满人文关怀的塔罗咨询师。

      牌阵信息：
      1. 【过去】：${cards[0].name} (${cards[0].meaning})
      2. 【现在】：${cards[1].name} (${cards[1].meaning})
      3. 【未来】：${cards[2].name} (${cards[2].meaning})

      解读要求：
      ${openingInstruction}
      2. **深度剖析**：结合“${cards[1].name}”揭示当下的核心矛盾。
      3. **具体建议**：基于“${cards[2].name}”，给出1-2条可执行的行动建议。
      4. **语调**：温暖而坚定。

      字数控制在300字左右。
    `;
  }

  static async requestChat(history: ChatMessage[], context: common.UIAbilityContext, isInitialAnalysis: boolean = false): Promise<string> {
    const energyMgr = EnergyManager.getInstance();
    const cost = isInitialAnalysis ? AIService.COST_DEEP_ANALYSIS : AIService.COST_PER_CHAT;

    if (!energyMgr.hasEnough(cost)) {
      return `✨ 心力值不足 (${energyMgr.getEnergy()}/${cost})。\n\n请去首页点击闪电图标补充心力。`;
    }

    const httpRequest = http.createHttp();

    const systemPrompt: ChatMessage = {
      role: "system",
      content: "你是一位名为“治愈之书”的专业塔罗分析师，擅长将心理学与塔罗结合，风格温暖、犀利且务实。"
    };
    let messagesToSend: ChatMessage[] = [...history];
    if (messagesToSend.length === 0 || messagesToSend[0].role !== 'system') {
      messagesToSend.unshift(systemPrompt);
    }

    try {
      const mockUserId = "user_001";
      const mockToken = "token_test";

      const response = await httpRequest.request(
        AIService.MY_SERVER_URL,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: {
            userId: mockUserId,
            token: mockToken,
            messages: messagesToSend
          },
          readTimeout: 60000,
          connectTimeout: 10000
        }
      );

      if (response.responseCode === 200) {
        await energyMgr.consume(cost);
        let resultStr = typeof response.result === 'string' ? response.result : JSON.stringify(response.result);
        const result = JSON.parse(resultStr) as AIResponse;
        return result.choices?.[0]?.message?.content || "AI 陷入沉思...";
      } else {
        return `服务器开小差了 (Code: ${response.responseCode})。`;
      }
    } catch (err) {
      return "网络连接不稳定，无法连接到治愈云端。";
    } finally {
      httpRequest.destroy();
    }
  }
}