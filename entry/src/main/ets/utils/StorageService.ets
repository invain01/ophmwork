/**
 * 数据持久化存储服务
 * 使用 HarmonyOS Preferences 进行本地数据存储
 */
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { StorageKeys } from './Constants';
import { HealthData } from '../model/HealthData';

// 定义健康数据接口，用于JSON解析
interface HealthDataJson {
  steps?: number;
  stepGoal?: number;
  waterIntake?: number;
  waterGoal?: number;
  sleepHours?: number;
  sleepGoal?: number;
  heartRate?: number;
  caloriesBurned?: number;
  calorieGoal?: number;
  lastUpdated?: string;
}

export class StorageService {
  private static instance: StorageService;
  private preferences: preferences.Preferences | null = null;
  private readonly PREFERENCES_NAME: string = 'harmonycare_storage';
  private readonly SELECTED_DATE_KEY: string = StorageKeys.SELECTED_DATE;
  private readonly HEALTH_DATA_PREFIX: string = 'health_data_';

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): StorageService {
    if (!StorageService.instance) {
      StorageService.instance = new StorageService();
    }
    return StorageService.instance;
  }

  /**
   * 初始化存储服务
   */
  async initialize(): Promise<void> {
    try {
      this.preferences = await preferences.getPreferences(this.getContext(), this.PREFERENCES_NAME);
      console.log('StorageService initialized successfully');
    } catch (error) {
      console.error('Failed to initialize StorageService:', error);
    }
  }

  /**
   * 获取上下文
   */
  private getContext(): common.UIAbilityContext {
    // 在 HarmonyOS 中，可以通过 @ohos.app.ability.common 获取上下文
    // 这里我们使用全局上下文
    const context = getContext() as common.UIAbilityContext;
    return context;
  }

  /**
   * 保存选中的日期
   */
  async saveSelectedDate(dateString: string): Promise<void> {
    try {
      if (!this.preferences) {
        await this.initialize();
      }
      
      if (this.preferences) {
        await this.preferences.put(this.SELECTED_DATE_KEY, dateString);
        await this.preferences.flush();
        console.log('Selected date saved:', dateString);
      }
    } catch (error) {
      console.error('Failed to save selected date:', error);
    }
  }

  /**
   * 获取选中的日期
   */
  async getSelectedDate(): Promise<string | null> {
    try {
      if (!this.preferences) {
        await this.initialize();
      }
      
      if (this.preferences) {
        const dateString = await this.preferences.get(this.SELECTED_DATE_KEY, '') as string;
        return dateString !== '' ? dateString : null;
      }
    } catch (error) {
      console.error('Failed to get selected date:', error);
    }
    return null;
  }

  /**
   * 保存某一天的健康数据
   */
  async saveHealthData(date: Date, healthData: HealthData): Promise<void> {
    try {
      if (!this.preferences) {
        await this.initialize();
      }
      
      const dateKey = this.getDateKey(date);
      if (this.preferences) {
        const dataString = JSON.stringify(healthData);
        await this.preferences.put(dateKey, dataString);
        await this.preferences.flush();
        console.log('Health data saved for date:', dateKey);
      }
    } catch (error) {
      console.error('Failed to save health data:', error);
    }
  }

  /**
   * 获取某一天的健康数据
   */
  async getHealthData(date: Date): Promise<HealthData | null> {
    try {
      if (!this.preferences) {
        await this.initialize();
      }
      
      const dateKey = this.getDateKey(date);
      if (this.preferences) {
        const dataString = await this.preferences.get(dateKey, '') as string;
        if (dataString !== '') {
          const parsed: HealthDataJson = JSON.parse(dataString) as HealthDataJson;
          return new HealthData(parsed);
        }
      }
    } catch (error) {
      console.error('Failed to get health data:', error);
    }
    return null;
  }

  /**
   * 检查某一天是否有健康数据
   */
  async hasHealthData(date: Date): Promise<boolean> {
    try {
      if (!this.preferences) {
        await this.initialize();
      }
      
      const dateKey = this.getDateKey(date);
      if (this.preferences) {
        const dataString = await this.preferences.get(dateKey, '') as string;
        return dataString !== '';
      }
    } catch (error) {
      console.error('Failed to check health data:', error);
    }
    return false;
  }

  /**
   * 删除某一天的健康数据
   */
  async deleteHealthData(date: Date): Promise<void> {
    try {
      if (!this.preferences) {
        await this.initialize();
      }
      
      const dateKey = this.getDateKey(date);
      if (this.preferences) {
        await this.preferences.delete(dateKey);
        await this.preferences.flush();
        console.log('Health data deleted for date:', dateKey);
      }
    } catch (error) {
      console.error('Failed to delete health data:', error);
    }
  }

  /**
   * 获取所有有健康数据的日期
   */
  async getAllHealthDataDates(): Promise<Date[]> {
    try {
      if (!this.preferences) {
        await this.initialize();
      }
      
      if (this.preferences) {
        const allData = await this.preferences.getAll();
        const allKeys: string[] = Object.keys(allData);
        const dateKeys = allKeys.filter((key: string): boolean => key.startsWith(this.HEALTH_DATA_PREFIX));
        
        const dates: Date[] = [];
        for (const key of dateKeys) {
          const dateString = key.replace(this.HEALTH_DATA_PREFIX, '');
          const date = new Date(dateString);
          if (!isNaN(date.getTime())) {
            dates.push(date);
          }
        }
        
        return dates.sort((a: Date, b: Date): number => a.getTime() - b.getTime());
      }
    } catch (error) {
      console.error('Failed to get all health data dates:', error);
    }
    return [];
  }

  /**
   * 清除所有存储的数据
   */
  async clearAllData(): Promise<void> {
    try {
      if (!this.preferences) {
        await this.initialize();
      }
      
      if (this.preferences) {
        await this.preferences.clear();
        await this.preferences.flush();
        console.log('All data cleared');
      }
    } catch (error) {
      console.error('Failed to clear all data:', error);
    }
  }

  /**
   * 根据日期生成存储键
   */
  private getDateKey(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${this.HEALTH_DATA_PREFIX}${year}-${month}-${day}`;
  }

  /**
   * 从存储键解析日期
   */
  private parseDateFromKey(key: string): Date | null {
    try {
      const dateString = key.replace(this.HEALTH_DATA_PREFIX, '');
      const date = new Date(dateString);
      if (!isNaN(date.getTime())) {
        return date;
      }
    } catch (error) {
      console.error('Failed to parse date from key:', error);
    }
    return null;
  }
}