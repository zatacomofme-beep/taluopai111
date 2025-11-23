// 路径: ets/common/FortuneManager.ets
// V37.3 修复版：修复 Set 展开语法报错，解决 Index.ets 无法识别方法的问题

import { TarotCard, TAROT_DECK } from '../model/TarotData';
import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';

const PREF_NAME = 'healing_book_pref';
const KEY_LAST_DATE = 'last_draw_date';
const KEY_TODAY_CARD_ID = 'today_card_id';
const KEY_IS_VIP = 'is_vip_user';

const KEY_HISTORY = 'user_history_v1';
const KEY_FAVORITES = 'user_favorites_v1';

const KEY_MOOD_TODAY = 'mood_today_v1';
const KEY_MOOD_NOTE = 'mood_note_v1';
const KEY_GOLD_QUOTE_TODAY = 'gold_quote_today_v1';
const KEY_DAILY_TASK_TODAY = 'daily_task_today_v1';
const KEY_PRIVACY_MODE = 'privacy_mode_v1';
const KEY_MOOD_STREAK = 'mood_streak_v1';
const KEY_LAST_MOOD_DATE = 'last_mood_date_v1';

// 定义记录结构
export interface CardRecord {
  timestamp: number; // 时间戳
  cardId: number;    // 卡牌ID
  rarityColor: string; // 记录当时的欧气颜色
  moodIndex?: number; // 可选：记录当时心情
  moodNote?: string;  // 可选：记录心情备注
}

export interface MoodToday {
  mood: number;
  note: string;
}

export interface AffirmationsToday {
  quote: string;
  task: string;
}

export class FortuneManager {
  private static instance: FortuneManager;
  private pref: preferences.Preferences | null = null;

  private constructor() {}

  public static getInstance(): FortuneManager {
    if (!FortuneManager.instance) {
      FortuneManager.instance = new FortuneManager();
    }
    return FortuneManager.instance;
  }

  /**
   * 初始化偏好存储，并进行数据压缩与校验
   */
  public async init(context: common.UIAbilityContext): Promise<void> {
    try {
      this.pref = await preferences.getPreferences(context, PREF_NAME);
      await this.compactData();
    } catch (err) {
      console.error('HealingBook: Failed to init preferences', err);
    }
  }

  // --- 基础抽牌逻辑 ---
  public async checkTodayCard(): Promise<TarotCard | null> {
    if (!this.pref) return null;
    const todayStr = new Date().toDateString();
    const savedDate = await this.pref.get(KEY_LAST_DATE, '');

    if (savedDate === todayStr) {
      const cardId = await this.pref.get(KEY_TODAY_CARD_ID, -1) as number;
      if (cardId >= 0 && cardId < TAROT_DECK.length) {
        return TAROT_DECK[cardId];
      }
    }
    return null;
  }

  public async drawDailyCard(): Promise<TarotCard> {
    const randomIndex = Math.floor(Math.random() * TAROT_DECK.length);
    const card = TAROT_DECK[randomIndex];

    if (this.pref) {
      const todayStr = new Date().toDateString();
      await this.pref.put(KEY_LAST_DATE, todayStr);
      await this.pref.put(KEY_TODAY_CARD_ID, card.id);
      await this.pref.flush();
    }
    return card;
  }

  public drawThreeSpread(): TarotCard[] {
    const shuffled = [...TAROT_DECK].sort(() => 0.5 - Math.random());
    return shuffled.slice(0, 3);
  }

  // --- 📜 历史记录管理 ---

  /**
   * 新增历史记录（最多保留50条，最新在前）
   */
  public async addHistory(card: TarotCard, rarityColor: string) {
    if (!this.pref) return;
    const history = await this.safeGetRecords(KEY_HISTORY);

    // 新记录插到最前面
    history.unshift({
      timestamp: new Date().getTime(),
      cardId: card.id,
      rarityColor: rarityColor
    });

    // 只保留最近 50 条
    if (history.length > 50) history.pop();

    await this.pref.put(KEY_HISTORY, JSON.stringify(history));
    await this.pref.flush();
  }

  /**
   * 获取历史记录（包含容错）
   */
  public async getHistory(): Promise<CardRecord[]> {
    if (!this.pref) return [];
    return await this.safeGetRecords(KEY_HISTORY);
  }

  // --- ❤️ 收藏夹管理 ---

  /**
   * 切换收藏（存在则移除，不存在则添加）
   */
  public async toggleFavorite(card: TarotCard, rarityColor: string): Promise<boolean> {
    if (!this.pref) return false;
    let favs = await this.safeGetRecords(KEY_FAVORITES);

    const index = favs.findIndex(item => item.cardId === card.id);
    let isAdded = false;

    if (index >= 0) {
      // 已存在，取消收藏
      favs.splice(index, 1);
      isAdded = false;
    } else {
      // 不存在，添加收藏
      favs.unshift({
        timestamp: new Date().getTime(),
        cardId: card.id,
        rarityColor: rarityColor
      });
      isAdded = true;
    }

    await this.pref.put(KEY_FAVORITES, JSON.stringify(favs));
    await this.pref.flush();
    return isAdded;
  }

  /**
   * 判断是否已收藏
   */
  public async isFavorite(cardId: number): Promise<boolean> {
    if (!this.pref) return false;
    const favs = await this.safeGetRecords(KEY_FAVORITES);
    return favs.some(item => item.cardId === cardId);
  }

  /**
   * 获取收藏列表（包含容错）
   */
  public async getFavorites(): Promise<CardRecord[]> {
    if (!this.pref) return [];
    return await this.safeGetRecords(KEY_FAVORITES);
  }

  /**
   * 获取已收集卡片ID集合（去重）
   */
  public async getCollectedCardIds(): Promise<number[]> {
    const history = await this.getHistory();
    const ids = history.map(item => item.cardId);
    const uniqueIds = ids.filter((element, index, self) => self.indexOf(element) === index);
    return uniqueIds;
  }

  /**
   * 保存抽牌结果到展览厅（历史）
   */
  public async saveDrawResult(card: TarotCard, rarityColor: string): Promise<void> {
    await this.addHistory(card, rarityColor);
  }

  /**
   * 生成展览厅数据：按历史中最近一次出现的卡片去重
   */
  public async getGallery(): Promise<CardRecord[]> {
    const history = await this.getHistory();
    const seen: number[] = [];
    const gallery: CardRecord[] = [];
    for (const h of history) {
      if (seen.indexOf(h.cardId) === -1) {
        seen.push(h.cardId);
        gallery.push(h);
      }
    }
    return gallery;
  }

  // --- VIP ---
  /**
   * 获取VIP状态
   */
  public async isVip(): Promise<boolean> {
    if (!this.pref) return false;
    return await this.pref.get(KEY_IS_VIP, false) as boolean;
  }

  /**
   * 设置VIP状态
   */
  public async setVipStatus(isVip: boolean): Promise<void> {
    if (this.pref) {
      await this.pref.put(KEY_IS_VIP, isVip);
      await this.pref.flush();
    }
  }

  /**
   * 保存今日心情（0-4）与备注
   */
  public async setTodayMood(mood: number, note: string): Promise<void> {
    if (!this.pref) return;
    await this.pref.put(KEY_MOOD_TODAY, mood);
    await this.pref.put(KEY_MOOD_NOTE, note || '');
    const todayStr = new Date().toDateString();
    const last = await this.pref.get(KEY_LAST_MOOD_DATE, '') as string;
    let streak = await this.pref.get(KEY_MOOD_STREAK, 0) as number;
    if (last === todayStr) {
      // 已记录今日，保持 streak
    } else {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const yStr = yesterday.toDateString();
      if (last === yStr) { streak = streak + 1; } else { streak = 1; }
      await this.pref.put(KEY_LAST_MOOD_DATE, todayStr);
      await this.pref.put(KEY_MOOD_STREAK, streak);
    }
    const history = await this.safeGetRecords(KEY_HISTORY);
    if (history.length > 0) {
      history[0].moodIndex = mood;
      history[0].moodNote = note || '';
      await this.pref.put(KEY_HISTORY, JSON.stringify(history));
    }
    await this.pref.flush();
  }

  /**
   * 读取今日心情与备注
   */
  public async getTodayMood(): Promise<MoodToday> {
    if (!this.pref) return { mood: -1, note: '' };
    const mood = await this.pref.get(KEY_MOOD_TODAY, -1) as number;
    const note = await this.pref.get(KEY_MOOD_NOTE, '') as string;
    return { mood, note };
  }

  /**
   * 读取心情连续签到天数（函数级注释）
   */
  public async getMoodStreak(): Promise<number> {
    if (!this.pref) return 0;
    return await this.pref.get(KEY_MOOD_STREAK, 0) as number;
  }

  /**
   * 保存今日治愈金句与小任务
   */
  public async setTodayAffirmations(quote: string, task: string): Promise<void> {
    if (!this.pref) return;
    await this.pref.put(KEY_GOLD_QUOTE_TODAY, quote || '');
    await this.pref.put(KEY_DAILY_TASK_TODAY, task || '');
    await this.pref.flush();
  }

  /**
   * 读取今日治愈金句与小任务
   */
  public async getTodayAffirmations(): Promise<AffirmationsToday> {
    if (!this.pref) return { quote: '', task: '' };
    const quote = await this.pref.get(KEY_GOLD_QUOTE_TODAY, '') as string;
    const task = await this.pref.get(KEY_DAILY_TASK_TODAY, '') as string;
    return { quote, task };
  }

  /**
   * 生成治愈金句（基于卡牌含义，纯本地）
   */
  public createGoldQuote(card: TarotCard): string {
    const seeds = [
      `${card.name}在对你轻声说：${card.meaning}，请温柔地拥抱当下。`,
      `把今天活成一朵花吧。${card.name}提示：${card.meaning}。`,
      `当你愿意相信，世界会为你让路。${card.name}：${card.meaning}。`,
      `慢慢来，宇宙都在等你。${card.name}：${card.meaning}。`
    ];
    return seeds[card.id % seeds.length];
  }

  /**
   * 生成今日小任务（不依赖后端）
   */
  public createDailyTask(card: TarotCard): string {
    const acts = [
      '写下今天最让你微笑的三件小事',
      '给自己泡一杯热饮，慢慢喝完',
      '整理一个角落，让它变得舒适',
      '给重要的人发一句感谢',
      '在夜里抬头看一次星空或灯光'
    ];
    const hint = card.meaning.split('·')[0];
    return `围绕「${hint}」完成：${acts[(card.id + TAROT_DECK.length) % acts.length]}`;
  }

  /**
   * 计算成就徽章文案（函数级注释）
   */
  public getAchievementLabelByStreak(streak: number): string | null {
    if (streak >= 30) return '星河同伴 · 连续30天';
    if (streak >= 7) return '温柔坚持 · 连续7天';
    if (streak >= 3) return '小火花 · 连续3天';
    return null;
  }

  /**
   * 设置私密模式开关
   */
  public async setPrivacyMode(enabled: boolean): Promise<void> {
    if (!this.pref) return;
    await this.pref.put(KEY_PRIVACY_MODE, enabled);
    await this.pref.flush();
  }

  /**
   * 读取私密模式状态
   */
  public async isPrivacyMode(): Promise<boolean> {
    if (!this.pref) return false;
    return await this.pref.get(KEY_PRIVACY_MODE, false) as boolean;
  }

  /**
   * 读取并解析记录（带容错与过滤）
   */
  private async safeGetRecords(key: string): Promise<CardRecord[]> {
    if (!this.pref) return [];
    try {
      const str = await this.pref.get(key, '[]') as string;
      const parsed = JSON.parse(str) as CardRecord[];
      return this.sanitizeRecords(parsed);
    } catch (_) {
      return [];
    }
  }

  /**
   * 清理无效数据、按时间降序并限制长度
   */
  private sanitizeRecords(records: CardRecord[]): CardRecord[] {
    const valid = records.filter(r => this.isValidCardId(r.cardId) && typeof r.timestamp === 'number');
    valid.sort((a, b) => b.timestamp - a.timestamp);
    return valid;
  }

  /**
   * 有效卡ID判断
   */
  private isValidCardId(id: number): boolean { return id >= 0 && id < TAROT_DECK.length; }

  /**
   * 启动时压缩数据，保证模拟器重启后数据仍然稳定
   */
  private async compactData(): Promise<void> {
    if (!this.pref) return;
    const history = await this.safeGetRecords(KEY_HISTORY);
    const favorites = await this.safeGetRecords(KEY_FAVORITES);

    // 去重：保留同卡片的最新记录
    const uniqById = (list: CardRecord[]) => {
      const seen = new Set<number>();
      const result: CardRecord[] = [];
      for (const r of list) {
        if (!seen.has(r.cardId)) { seen.add(r.cardId); result.push(r); }
      }
      return result;
    };

    const compactHistory = uniqById(history).slice(0, 50);
    const compactFavorites = uniqById(favorites);

    await this.pref.put(KEY_HISTORY, JSON.stringify(compactHistory));
    await this.pref.put(KEY_FAVORITES, JSON.stringify(compactFavorites));
    await this.pref.flush();
  }

  /**
   * 读取当前已安装的桌面卡片 formId 列表（函数级注释）
   */
  public async getFormIds(): Promise<string[]> {
    if (!this.pref) return [];
    try {
      const raw = await this.pref.get('form_ids', '[]') as string;
      const ids = JSON.parse(raw) as string[];
      return Array.isArray(ids) ? ids : [];
    } catch (_) {
      return [];
    }
  }
}
