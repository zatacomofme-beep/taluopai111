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

  static createInitialPrompt(cards: TarotCard[], lastMood?: MoodToday, spreadType: string = 'time_flow'): string {
    let moodInstruction = "";
    
    // 场景 1：有心情记录
    if (lastMood && lastMood.mood !== -1) {
      const emojis = ['😭 悲伤', '😕 困惑', '🙂 平静', '😊 开心', '🥳 狂喜'];
      const moodText = emojis[lastMood.mood] || '未知';
      const noteText = lastMood.note ? `备注：“${lastMood.note}”` : '';
      moodInstruction = `【用户当前状态】：${moodText}。${noteText}。请在解读中予以回应。`;
    }

    let spreadInfo = "";
    let formatInstruction = "";
    
    if (spreadType === 'time_flow') {
        spreadInfo = `
        牌阵：时光流（Past-Present-Future）
        1. 【过去】：${cards[0]?.name} (${cards[0]?.meaning})
        2. 【现在】：${cards[1]?.name} (${cards[1]?.meaning})
        3. 【未来】：${cards[2]?.name} (${cards[2]?.meaning})
        `;
        formatInstruction = `
        请严格按照以下格式输出（不要修改标签）：
        <<<SECTION_0>>>
        (针对过去的解读，结合开场白)
        <<<SECTION_1>>>
        (针对现在的深度剖析)
        <<<SECTION_2>>>
        (针对未来的预测)
        <<<SECTION_3>>>
        (综合建议)
        `;
    } else if (spreadType === 'celtic_cross') {
        // 简化版凯尔特十字 (这里只取前10张，假设 cards 长度足够)
        const positions = [
            '核心现状', '阻碍/挑战', '潜意识/基础', '过去的影响', 
            '意识目标/最高愿景', '即将发生的未来', '自我态度', '环境影响', '希望与恐惧', '最终结果'
        ];
        spreadInfo = "牌阵：凯尔特十字\n";
        cards.forEach((c, i) => {
            if (i < 10) spreadInfo += `${i+1}. 【${positions[i]}】：${c.name} (${c.meaning})\n`;
        });
        formatInstruction = `
        请严格按照以下格式输出 10 个段落 + 1 个总结：
        <<<SECTION_0>>>
        (核心现状解读)
        <<<SECTION_1>>>
        (阻碍与挑战解读)
        ...以此类推直到 <<<SECTION_9>>> (最终结果)
        <<<SECTION_10>>>
        (综合总结与建议)
        `;
    } else {
        // 通用处理
        spreadInfo = "牌阵：自由牌阵\n";
        cards.forEach((c, i) => {
            spreadInfo += `${i+1}. ${c.name} (${c.meaning})\n`;
        });
        formatInstruction = `
        请为每一张牌提供解读段落，格式为：
        <<<SECTION_0>>>
        (第1张牌解读)
        <<<SECTION_1>>>
        (第2张牌解读)
        ...
        <<<SECTION_${cards.length}>>>
        (总结建议)
        `;
    }

    return `
      ${moodInstruction}
      你是一位经验丰富、直觉敏锐且充满人文关怀的塔罗咨询师。
      
      ${spreadInfo}

      解读要求：
      1. 语言温暖而坚定，富有治愈感。
      2. 结合牌面含义和位置含义进行深度链接。
      3. 最后必须给出具体可行的建议。
      
      ${formatInstruction}
    `;
  }

  static async requestChat(history: ChatMessage[], context: common.UIAbilityContext, isInitialAnalysis: boolean = false, isFree: boolean = false): Promise<string> {
    const energyMgr = EnergyManager.getInstance();
    const fortuneMgr = FortuneManager.getInstance(); // 获取实例用于标记免费次数
    const cost = isInitialAnalysis ? AIService.COST_DEEP_ANALYSIS : AIService.COST_PER_CHAT;

    // 如果不是免费且心力不足
    if (!isFree && !energyMgr.hasEnough(cost)) {
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
        if (!isFree) {
          await energyMgr.consume(cost);
        } else if (isInitialAnalysis) {
           // 如果是免费且是深度分析，标记今日已用
           await fortuneMgr.markDailyDeepAnalysisUsed();
        }
        
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