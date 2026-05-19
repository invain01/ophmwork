/**
 * 数据持久化存储服务
 * 使用 HarmonyOS Preferences 进行本地数据存储
 */
import preferences from '@ohos.data.preferences';
import fs from '@ohos.file.fs';
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

interface HealthDataEntryPayload {
  date: string;
  data: HealthDataJson;
}

interface HealthDataFilePayload {
  entries: HealthDataEntryPayload[];
}

class HealthDataEntry {
  date: string;
  data: HealthDataJson;

  constructor(date: string, data: HealthDataJson) {
    this.date = date;
    this.data = data;
  }
}

class HealthDataFile {
  entries: HealthDataEntry[] = [];

  constructor(entries?: HealthDataEntry[]) {
    if (entries) {
      this.entries = entries;
    }
  }
}

export class StorageService {
  private static instance: StorageService;
  private preferences: preferences.Preferences | null = null;
  private readonly PREFERENCES_NAME: string = 'harmonycare_storage';
  private readonly SELECTED_DATE_KEY: string = StorageKeys.SELECTED_DATE;
  private readonly HEALTH_DATA_FILE_NAME: string = 'health_data.json';

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

  private getHealthDataFilePath(): string {
    const context = this.getContext();
    return `${context.filesDir}/${this.HEALTH_DATA_FILE_NAME}`;
  }

  private async ensurePreferences(): Promise<void> {
    if (!this.preferences) {
      await this.initialize();
    }
  }

  private toHealthDataJson(healthData: HealthData): HealthDataJson {
    const json: HealthDataJson = {};
    json.steps = healthData.steps;
    json.stepGoal = healthData.stepGoal;
    json.waterIntake = healthData.waterIntake;
    json.waterGoal = healthData.waterGoal;
    json.sleepHours = healthData.sleepHours;
    json.sleepGoal = healthData.sleepGoal;
    json.heartRate = healthData.heartRate;
    json.caloriesBurned = healthData.caloriesBurned;
    json.calorieGoal = healthData.calorieGoal;
    json.lastUpdated = healthData.lastUpdated;
    return json;
  }

  private async readHealthDataFile(): Promise<HealthDataFile> {
    const filePath = this.getHealthDataFilePath();
    try {
      const content = fs.readTextSync(filePath);
      if (!content) {
        return new HealthDataFile();
      }
      const parsed = JSON.parse(content) as HealthDataFilePayload;
      if (!parsed || !Array.isArray(parsed.entries)) {
        return new HealthDataFile();
      }
      const entries: HealthDataEntry[] = [];
      for (const item of parsed.entries) {
        if (item && typeof item.date === 'string' && item.data) {
          entries.push(new HealthDataEntry(item.date, item.data));
        }
      }
      return new HealthDataFile(entries);
    } catch (error) {
      return new HealthDataFile();
    }
  }

  private async writeHealthDataFile(file: HealthDataFile): Promise<void> {
    const filePath = this.getHealthDataFilePath();
    const payload: HealthDataFilePayload = {
      entries: file.entries
    };
    const content = JSON.stringify(payload);
    const fileHandle = fs.openSync(
      filePath,
      fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC
    );
    try {
      fs.writeSync(fileHandle.fd, content);
    } finally {
      fs.closeSync(fileHandle);
    }
  }

  private findEntryIndex(entries: HealthDataEntry[], dateKey: string): number {
    for (let i = 0; i < entries.length; i += 1) {
      if (entries[i].date === dateKey) {
        return i;
      }
    }
    return -1;
  }

  /**
   * 保存选中的日期
   */
  async saveSelectedDate(dateString: string): Promise<void> {
    try {
      await this.ensurePreferences();
      
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
      await this.ensurePreferences();
      
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
      const dateKey = this.getDateKey(date);
      const file = await this.readHealthDataFile();
      const index = this.findEntryIndex(file.entries, dateKey);
      const entry = new HealthDataEntry(dateKey, this.toHealthDataJson(healthData));
      if (index >= 0) {
        file.entries[index] = entry;
      } else {
        file.entries.push(entry);
      }
      await this.writeHealthDataFile(file);
      console.log('Health data saved for date:', dateKey);
    } catch (error) {
      console.error('Failed to save health data:', error);
    }
  }

  /**
   * 获取某一天的健康数据
   */
  async getHealthData(date: Date): Promise<HealthData | null> {
    try {
      const dateKey = this.getDateKey(date);
      const file = await this.readHealthDataFile();
      const index = this.findEntryIndex(file.entries, dateKey);
      if (index >= 0) {
        const data = file.entries[index].data;
        return new HealthData(data);
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
      const dateKey = this.getDateKey(date);
      const file = await this.readHealthDataFile();
      return this.findEntryIndex(file.entries, dateKey) >= 0;
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
      const dateKey = this.getDateKey(date);
      const file = await this.readHealthDataFile();
      const nextEntries: HealthDataEntry[] = [];
      for (const entry of file.entries) {
        if (entry.date !== dateKey) {
          nextEntries.push(entry);
        }
      }
      file.entries = nextEntries;
      await this.writeHealthDataFile(file);
      console.log('Health data deleted for date:', dateKey);
    } catch (error) {
      console.error('Failed to delete health data:', error);
    }
  }

  /**
   * 获取所有有健康数据的日期
   */
  async getAllHealthDataDates(): Promise<Date[]> {
    try {
      const dates: Date[] = [];
      const file = await this.readHealthDataFile();
      for (const entry of file.entries) {
        const date = this.parseDateFromKey(entry.date);
        if (date) {
          dates.push(date);
        }
      }

      return dates.sort((a: Date, b: Date): number => a.getTime() - b.getTime());
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
      await this.ensurePreferences();
      
      if (this.preferences) {
        await this.preferences.clear();
        await this.preferences.flush();
        console.log('All data cleared');
      }

      const filePath = this.getHealthDataFilePath();
      try {
        fs.unlinkSync(filePath);
      } catch (error) {
        // ignore missing file
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
    return `${year}-${month}-${day}`;
  }

  /**
   * 从存储键解析日期
   */
  private parseDateFromKey(key: string): Date | null {
    try {
      const match = key.match(/^(\d{4})-(\d{2})-(\d{2})$/);
      if (!match) {
        return null;
      }
      const year = Number(match[1]);
      const month = Number(match[2]);
      const day = Number(match[3]);
      const date = new Date(year, month - 1, day);
      if (!isNaN(date.getTime())) {
        return date;
      }
    } catch (error) {
      console.error('Failed to parse date from key:', error);
    }
    return null;
  }
}