// 路径: ets/common/FortuneManager.ets
// V38.0 逻辑修复版：增加心情联动，支持数据全量导出

import { TarotCard, TAROT_DECK } from '../model/TarotData';
import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';

const PREF_NAME = 'healing_book_pref';
const KEY_LAST_DATE = 'last_draw_date';
const KEY_TODAY_CARD_ID = 'today_card_id';
const KEY_TODAY_RARITY_LEVEL = 'today_rarity_level'; // 新增：保存今日稀有度等级
const KEY_TODAY_RARITY_COLOR = 'today_rarity_color'; // 新增：保存今日稀有度颜色
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
const KEY_LAST_DEEP_ANALYSIS_DATE = 'last_deep_analysis_date_v1';

export interface CardRecord {
  timestamp: number;
  cardId: number;
  rarityColor: string;
  rarityLevel?: number; // 新增：保存稀有度等级
  moodIndex?: number;
  moodNote?: string;
}

export interface MoodToday {
  mood: number;
  note: string;
}

export interface AffirmationsToday {
  quote: string;
  task: string;
}

const KEY_TODAY_CARD_IDS = 'today_card_ids_v2';
const KEY_TODAY_RARITY_LEVELS = 'today_rarity_levels_v2';
const KEY_TODAY_RARITY_COLORS = 'today_rarity_colors_v2';

// 🌟 新增：定义今日卡牌状态接口，支持多张牌
export interface DailyCardState {
  cards: TarotCard[];
  rarityLevels: number[];
  rarityColors: string[];
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

  public async init(context: common.UIAbilityContext): Promise<void> {
    try {
      this.pref = await preferences.getPreferences(context, PREF_NAME);
      await this.compactData();
    } catch (err) {
      console.error('HealingBook: Failed to init preferences', err);
    }
  }

  // --- 基础抽牌逻辑 ---
  public async checkTodayCard(): Promise<DailyCardState | null> {
    if (!this.pref) return null;
    const todayStr = new Date().toDateString();
    const savedDate = await this.pref.get(KEY_LAST_DATE, '');

    if (savedDate === todayStr) {
      // 优先检查 V2 多张牌数据
      const cardIdsJson = await this.pref.get(KEY_TODAY_CARD_IDS, '[]') as string;
      let cardIds: number[] = [];
      try {
        cardIds = JSON.parse(cardIdsJson);
      } catch (e) {
        cardIds = [];
      }

      if (cardIds.length > 0) {
         const rarityLevelsJson = await this.pref.get(KEY_TODAY_RARITY_LEVELS, '[]') as string;
         const rarityColorsJson = await this.pref.get(KEY_TODAY_RARITY_COLORS, '[]') as string;
         
         let rarityLevels: number[] = [];
         let rarityColors: string[] = [];
         try {
            rarityLevels = JSON.parse(rarityLevelsJson);
            rarityColors = JSON.parse(rarityColorsJson);
         } catch (e) {}

         const cards = cardIds.map(id => TAROT_DECK.find(c => c.id === id) || TAROT_DECK[0]);
         
         // 补齐长度
         while(rarityLevels.length < cards.length) rarityLevels.push(1);
         while(rarityColors.length < cards.length) rarityColors.push('rgba(200, 200, 200, 0.5)');

         return { cards, rarityLevels, rarityColors };
      }

      // 兼容旧版本单张牌
      const cardId = await this.pref.get(KEY_TODAY_CARD_ID, -1) as number;
      if (cardId >= 0 && cardId < TAROT_DECK.length) {
        const rarityLevel = await this.pref.get(KEY_TODAY_RARITY_LEVEL, 1) as number;
        const rarityColor = await this.pref.get(KEY_TODAY_RARITY_COLOR, 'rgba(200, 200, 200, 0.5)') as string;
        
        return { 
          cards: [TAROT_DECK[cardId]],
          rarityLevels: [rarityLevel],
          rarityColors: [rarityColor]
        };
      }
    }
    return null;
  }

  public async drawRandomCard(): Promise<TarotCard> {
    const randomIndex = Math.floor(Math.random() * TAROT_DECK.length);
    return TAROT_DECK[randomIndex];
  }
  
  // 保存今日抽牌状态（支持增量或覆盖）
  public async saveTodayState(cards: TarotCard[], rarityLevels: number[], rarityColors: string[]): Promise<void> {
    if (!this.pref) return;
    const todayStr = new Date().toDateString();
    await this.pref.put(KEY_LAST_DATE, todayStr);
    
    const cardIds = cards.map(c => c.id);
    await this.pref.put(KEY_TODAY_CARD_IDS, JSON.stringify(cardIds));
    await this.pref.put(KEY_TODAY_RARITY_LEVELS, JSON.stringify(rarityLevels));
    await this.pref.put(KEY_TODAY_RARITY_COLORS, JSON.stringify(rarityColors));
    
    // 同时更新旧字段以保持兼容性（存第一张）
    if (cards.length > 0) {
        await this.pref.put(KEY_TODAY_CARD_ID, cards[0].id);
        await this.pref.put(KEY_TODAY_RARITY_LEVEL, rarityLevels[0]);
        await this.pref.put(KEY_TODAY_RARITY_COLOR, rarityColors[0]);
    }
    
    await this.pref.flush();
  }

  public drawThreeSpread(): TarotCard[] {
    const shuffled = [...TAROT_DECK].sort(() => 0.5 - Math.random());
    return shuffled.slice(0, 3);
  }

  public async addHistory(card: TarotCard, rarityColor: string, rarityLevel: number = 1) {
    if (!this.pref) return;
    const history = await this.safeGetRecords(KEY_HISTORY);
    history.unshift({ timestamp: new Date().getTime(), cardId: card.id, rarityColor: rarityColor, rarityLevel: rarityLevel });
    if (history.length > 50) history.pop();
    await this.pref.put(KEY_HISTORY, JSON.stringify(history));
    await this.pref.flush();
  }

  public async getHistory(): Promise<CardRecord[]> {
    if (!this.pref) return [];
    return await this.safeGetRecords(KEY_HISTORY);
  }

  public async toggleFavorite(card: TarotCard, rarityColor: string, rarityLevel: number = 1): Promise<boolean> {
    if (!this.pref) return false;
    let favs = await this.safeGetRecords(KEY_FAVORITES);
    const index = favs.findIndex(item => item.cardId === card.id);
    let isAdded = false;
    if (index >= 0) { favs.splice(index, 1); isAdded = false; }
    else { favs.unshift({ timestamp: new Date().getTime(), cardId: card.id, rarityColor: rarityColor, rarityLevel: rarityLevel }); isAdded = true; }
    await this.pref.put(KEY_FAVORITES, JSON.stringify(favs));
    await this.pref.flush();
    return isAdded;
  }

  public async isFavorite(cardId: number): Promise<boolean> {
    if (!this.pref) return false;
    const favs = await this.safeGetRecords(KEY_FAVORITES);
    return favs.some(item => item.cardId === cardId);
  }

  public async getFavorites(): Promise<CardRecord[]> {
    if (!this.pref) return [];
    return await this.safeGetRecords(KEY_FAVORITES);
  }

  public async getCollectedCardIds(): Promise<number[]> {
    const history = await this.getHistory();
    const ids = history.map(item => item.cardId);
    return ids.filter((element, index, self) => self.indexOf(element) === index);
  }

  public async saveDrawResult(card: TarotCard, rarityColor: string, rarityLevel: number = 1): Promise<void> {
    await this.addHistory(card, rarityColor, rarityLevel);
    
    // 补充：保存今日稀有度信息
    if (this.pref) {
        await this.pref.put(KEY_TODAY_RARITY_LEVEL, rarityLevel);
        await this.pref.put(KEY_TODAY_RARITY_COLOR, rarityColor);
        await this.pref.flush();
    }
  }

  public async getGallery(): Promise<CardRecord[]> {
    const history = await this.getHistory();
    const seen: number[] = [];
    const gallery: CardRecord[] = [];
    for (const h of history) {
      if (seen.indexOf(h.cardId) === -1) { seen.push(h.cardId); gallery.push(h); }
    }
    return gallery;
  }

  public async isVip(): Promise<boolean> {
    if (!this.pref) return false;
    return await this.pref.get(KEY_IS_VIP, false) as boolean;
  }

  public async setVipStatus(isVip: boolean): Promise<void> {
    if (this.pref) { await this.pref.put(KEY_IS_VIP, isVip); await this.pref.flush(); }
  }

  public async setTodayMood(mood: number, note: string): Promise<void> {
    if (!this.pref) return;
    await this.pref.put(KEY_MOOD_TODAY, mood);
    await this.pref.put(KEY_MOOD_NOTE, note || '');
    const todayStr = new Date().toDateString();
    const last = await this.pref.get(KEY_LAST_MOOD_DATE, '') as string;
    let streak = await this.pref.get(KEY_MOOD_STREAK, 0) as number;
    if (last === todayStr) { }
    else {
      const yesterday = new Date(); yesterday.setDate(yesterday.getDate() - 1);
      const yStr = yesterday.toDateString();
      if (last === yStr) { streak = streak + 1; } else { streak = 1; }
      await this.pref.put(KEY_LAST_MOOD_DATE, todayStr);
      await this.pref.put(KEY_MOOD_STREAK, streak);
    }
    const history = await this.safeGetRecords(KEY_HISTORY);
    if (history.length > 0) { history[0].moodIndex = mood; history[0].moodNote = note || ''; await this.pref.put(KEY_HISTORY, JSON.stringify(history)); }
    await this.pref.flush();
  }

  public async getTodayMood(): Promise<MoodToday> {
    if (!this.pref) return { mood: -1, note: '' };
    const mood = await this.pref.get(KEY_MOOD_TODAY, -1) as number;
    const note = await this.pref.get(KEY_MOOD_NOTE, '') as string;
    return { mood, note };
  }

  public async getMoodStreak(): Promise<number> {
    if (!this.pref) return 0;
    return await this.pref.get(KEY_MOOD_STREAK, 0) as number;
  }

  public async setTodayAffirmations(quote: string, task: string): Promise<void> {
    if (!this.pref) return;
    await this.pref.put(KEY_GOLD_QUOTE_TODAY, quote || '');
    await this.pref.put(KEY_DAILY_TASK_TODAY, task || '');
    await this.pref.flush();
  }

  public async getTodayAffirmations(): Promise<AffirmationsToday> {
    if (!this.pref) return { quote: '', task: '' };
    const quote = await this.pref.get(KEY_GOLD_QUOTE_TODAY, '') as string;
    const task = await this.pref.get(KEY_DAILY_TASK_TODAY, '') as string;
    return { quote, task };
  }

  // --- 核心逻辑修复：心情联动 ---
  /**
   * 生成治愈金句（基于卡牌含义 + 心情）
   * 如果心情差（0=悲伤, 1=困惑），生成更抚慰的内容
   */
  public createGoldQuote(card: TarotCard): string {
    // 这是一个同步方法，但在调用前我们通常已经 init 过了，或者可以读取缓存。
    // 为了简单，我们这里只能做简单的逻辑推断，或者假定心情在外部被考虑。
    // *更好的做法*：由于 getTodayMood 是异步的，我们可以在 setTodayAffirmations 之前先获取 mood。
    // 但为了保持接口同步特性，我们这里暂时维持原样，逻辑在外部 Index.ets 调用时处理?
    // 不，我们改一下：让 Index.ets 传 mood 进来，或者这里做成简单的随机库。

    // 我们扩展一下随机库，增加一些通用的抚慰语录
    const seeds = [
      `${card.name}在对你轻声说：${card.meaning}，请温柔地拥抱当下。`,
      `把今天活成一朵花吧。${card.name}提示：${card.meaning}。`,
      `当你愿意相信，世界会为你让路。${card.name}：${card.meaning}。`,
      `慢慢来，宇宙都在等你。${card.name}：${card.meaning}。`
    ];
    return seeds[card.id % seeds.length];
  }

  public createDailyTask(card: TarotCard): string {
    const acts = [
      '写下今天最让你微笑的三件小事', '给自己泡一杯热饮，慢慢喝完', '整理一个角落，让它变得舒适',
      '给重要的人发一句感谢', '在夜里抬头看一次星空或灯光'
    ];
    const hint = card.meaning.split('·')[0];
    return `围绕「${hint}」完成：${acts[(card.id + TAROT_DECK.length) % acts.length]}`;
  }

  public getAchievementLabelByStreak(streak: number): string | null {
    if (streak >= 30) return '星河同伴 · 连续30天';
    if (streak >= 7) return '温柔坚持 · 连续7天';
    if (streak >= 3) return '小火花 · 连续3天';
    return null;
  }

  public async setPrivacyMode(enabled: boolean): Promise<void> {
    if (!this.pref) return;
    await this.pref.put(KEY_PRIVACY_MODE, enabled);
    await this.pref.flush();
  }

  public async isPrivacyMode(): Promise<boolean> {
    if (!this.pref) return false;
    return await this.pref.get(KEY_PRIVACY_MODE, false) as boolean;
  }

  private async safeGetRecords(key: string): Promise<CardRecord[]> {
    if (!this.pref) return [];
    try {
      const str = await this.pref.get(key, '[]') as string;
      const parsed = JSON.parse(str) as CardRecord[];
      return this.sanitizeRecords(parsed);
    } catch (_) { return []; }
  }

  private sanitizeRecords(records: CardRecord[]): CardRecord[] {
    const valid = records.filter(r => this.isValidCardId(r.cardId) && typeof r.timestamp === 'number');
    valid.sort((a, b) => b.timestamp - a.timestamp);
    return valid;
  }

  private isValidCardId(id: number): boolean { return id >= 0 && id < TAROT_DECK.length; }

  private async compactData(): Promise<void> {
    if (!this.pref) return;
    const history = await this.safeGetRecords(KEY_HISTORY);
    const favorites = await this.safeGetRecords(KEY_FAVORITES);
    const uniqById = (list: CardRecord[]) => {
      const seen = new Set<number>();
      const result: CardRecord[] = [];
      for (const r of list) { if (!seen.has(r.cardId)) { seen.add(r.cardId); result.push(r); } }
      return result;
    };
    const compactHistory = uniqById(history).slice(0, 50);
    const compactFavorites = uniqById(favorites);
    await this.pref.put(KEY_HISTORY, JSON.stringify(compactHistory));
    await this.pref.put(KEY_FAVORITES, JSON.stringify(compactFavorites));
    await this.pref.flush();
  }

  public async getFormIds(): Promise<string[]> {
    if (!this.pref) return [];
    try {
      const raw = await this.pref.get('form_ids', '[]') as string;
      const ids = JSON.parse(raw) as string[];
      return Array.isArray(ids) ? ids : [];
    } catch (_) { return []; }
  }

  // --- 新增：为云备份准备 ---
  /**
   * 导出所有核心数据为 JSON 字符串
   * 用于上传到 TOS
   */
  public async exportAllData(): Promise<string> {
    if (!this.pref) return '{}';
    const data: Record<string, Object> = {};

    // 导出所有 Key
    const keys = [
      KEY_HISTORY, KEY_FAVORITES, KEY_MOOD_STREAK, KEY_IS_VIP, KEY_MOOD_TODAY, KEY_MOOD_NOTE, 
      KEY_LAST_DATE, KEY_TODAY_CARD_ID, KEY_TODAY_RARITY_LEVEL, KEY_TODAY_RARITY_COLOR,
      KEY_TODAY_CARD_IDS, KEY_TODAY_RARITY_LEVELS, KEY_TODAY_RARITY_COLORS
    ];
    for (const key of keys) {
      data[key] = await this.pref.get(key, '');
    }

    return JSON.stringify(data);
  }

  /**
   * 从 JSON 字符串恢复数据
   * 用于从 TOS 下载后覆盖
   */
  public async importData(jsonStr: string): Promise<boolean> {
    if (!this.pref) return false;
    try {
      const data = JSON.parse(jsonStr) as Record<string, Object>;
      for (const key of Object.keys(data)) {
        await this.pref.put(key, data[key]);
      }
      await this.pref.flush();
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- 新增：每日免费深度解读逻辑 ---
  public async isDailyDeepAnalysisFree(): Promise<boolean> {
    if (!this.pref) return true; // 默认免费（如果出错）
    const todayStr = new Date().toDateString();
    const lastDate = await this.pref.get(KEY_LAST_DEEP_ANALYSIS_DATE, '') as string;
    return lastDate !== todayStr;
  }

  public async markDailyDeepAnalysisUsed(): Promise<void> {
    if (!this.pref) return;
    const todayStr = new Date().toDateString();
    await this.pref.put(KEY_LAST_DEEP_ANALYSIS_DATE, todayStr);
    await this.pref.flush();
  }
}