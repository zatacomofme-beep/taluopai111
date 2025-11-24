import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';

const PREF_NAME = 'energy_pref';
const KEY_ENERGY = 'user_energy_balance';
const KEY_LAST_RECOVER_DATE = 'last_recover_date';
const KEY_TOTAL_CONSUMED = 'total_consumed_energy';

export class EnergyManager {
  private static instance: EnergyManager;
  private pref: preferences.Preferences | null = null;

  // 配置参数
  private readonly DAILY_FREE_ENERGY = 20;
  private currentEnergy: number = 20;

  private constructor() {}

  public static getInstance(): EnergyManager {
    if (!EnergyManager.instance) {
      EnergyManager.instance = new EnergyManager();
    }
    return EnergyManager.instance;
  }

  public async init(context: common.UIAbilityContext): Promise<void> {
    try {
      this.pref = await preferences.getPreferences(context, PREF_NAME);
      await this.checkDailyRecover();
    } catch (err) {
      console.error('EnergyManager: Init failed', err);
    }
  }

  private async checkDailyRecover() {
    if (!this.pref) return;
    const todayStr = new Date().toDateString();
    const lastDate = await this.pref.get(KEY_LAST_RECOVER_DATE, '') as string;

    this.currentEnergy = await this.pref.get(KEY_ENERGY, this.DAILY_FREE_ENERGY) as number;

    if (lastDate !== todayStr) {
      if (this.currentEnergy < this.DAILY_FREE_ENERGY) {
        this.currentEnergy = this.DAILY_FREE_ENERGY;
      }
      await this.pref.put(KEY_LAST_RECOVER_DATE, todayStr);
      await this.saveEnergy();
    }
  }

  public getEnergy(): number { return this.currentEnergy; }

  public hasEnough(cost: number): boolean { return this.currentEnergy >= cost; }

  public async consume(cost: number): Promise<boolean> {
    if (this.currentEnergy < cost) return false;
    this.currentEnergy -= cost;
    await this.saveEnergy();
    return true;
  }

  // 🛑 确保这个方法存在！
  public async recharge(amount: number): Promise<void> {
    this.currentEnergy += amount;
    await this.saveEnergy();
  }

  private async saveEnergy() {
    if (this.pref) {
      await this.pref.put(KEY_ENERGY, this.currentEnergy);
      await this.pref.flush();
    }
  }
}