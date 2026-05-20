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
  weight?: number;
  sleepHours?: number;
  sleepGoal?: number;
  heartRate?: number;
  lastUpdated?: string;
}

interface HealthDataEntryPayload {
  date: string;
  data: HealthDataJson;
}

interface HealthDataFilePayload {
  entries: HealthDataEntryPayload[];
}

// 使用 Map 来代替索引签名，以兼容 ArkTS 规则

// 本地文件改为按日期键的 map 格式：{ "2024-01-01": { ... }, ... }
// 同时兼容旧的 { entries: [ { date, data }, ... ] } 格式

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

  public getFilesDirPath(): string {
    const context = this.getContext();
    return context.filesDir;
  }

  private async ensurePreferences(): Promise<void> {
    if (!this.preferences) {
      await this.initialize();
    }
  }

  private normalizeToStartOfDay(date: Date): Date {
    const normalized = new Date(date);
    normalized.setHours(0, 0, 0, 0);
    return normalized;
  }

  private toHealthDataJson(healthData: HealthData): HealthDataJson {
    const json: HealthDataJson = {};
    json.steps = healthData.steps;
    json.stepGoal = healthData.stepGoal;
    json.waterIntake = healthData.waterIntake;
    json.waterGoal = healthData.waterGoal;
    json.weight = healthData.weight;
    json.sleepHours = healthData.sleepHours;
    json.sleepGoal = healthData.sleepGoal;
    json.heartRate = healthData.heartRate;
    json.lastUpdated = healthData.lastUpdated;
    return json;
  }

  private async readHealthDataFile(): Promise<Map<string, HealthDataJson>> {
    const filePath = this.getHealthDataFilePath();
    try {
      const content = fs.readTextSync(filePath);
      if (!content) {
        return new Map<string, HealthDataJson>();
      }
      const parsed = JSON.parse(content) as HealthDataFilePayload | Record<string, object>;
      // 兼容旧格式 { entries: [ { date, data }, ... ] }
      const maybeEntries = (parsed as HealthDataFilePayload).entries;
      const result = new Map<string, HealthDataJson>();
      if (Array.isArray(maybeEntries)) {
        for (let i = 0; i < maybeEntries.length; i += 1) {
          const item = maybeEntries[i];
          if (item && typeof item.date === 'string' && item.data) {
            result.set(item.date, item.data as HealthDataJson);
          }
        }
        return result;
      }

      // 如果文件本身就是按日期键的对象，则直接读取键值对
      if (parsed && typeof parsed === 'object') {
        const parsedMap = parsed as Record<string, object>;
        const keys = Object.keys(parsedMap);
        for (let i = 0; i < keys.length; i += 1) {
          const key = keys[i];
          const val = parsedMap[key];
          if (val && typeof val === 'object') {
            result.set(key, val as HealthDataJson);
          }
        }
        return result;
      }
      return result;
    } catch (error) {
      return new Map<string, HealthDataJson>();
    }
  }

  private async writeHealthDataFile(fileMap: Map<string, HealthDataJson>): Promise<void> {
    const filePath = this.getHealthDataFilePath();
    const obj: Record<string, HealthDataJson> = {};
    fileMap.forEach((val: HealthDataJson, key: string) => {
      obj[key] = val;
    });
    const content = JSON.stringify(obj);
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

  // 已无需 findEntryIndex — 本地以 map 形式存储并直接按键访问

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

  async saveSelectedDateValue(date: Date): Promise<void> {
    const dateKey = this.getDateKey(this.normalizeToStartOfDay(date));
    await this.saveSelectedDate(dateKey);
  }

  async getSelectedDateValue(): Promise<Date | null> {
    const saved = await this.getSelectedDate();
    if (!saved) {
      return null;
    }

    const keyMatch = saved.match(/^\d{4}-\d{2}-\d{2}$/);
    if (keyMatch) {
      return this.parseDateFromKey(saved);
    }

    const parsed = new Date(saved);
    if (isNaN(parsed.getTime())) {
      return null;
    }
    return this.normalizeToStartOfDay(parsed);
  }

  /**
   * 保存某一天的健康数据
   */
  async saveHealthData(date: Date, healthData: HealthData): Promise<void> {
    try {
      const dateKey = this.getDateKey(date);
      const fileMap = await this.readHealthDataFile();
      fileMap.set(dateKey, this.toHealthDataJson(healthData));
      await this.writeHealthDataFile(fileMap);
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
      const fileMap = await this.readHealthDataFile();
      const raw = fileMap.get(dateKey);
      if (raw) {
        const hd = new HealthData(raw as HealthData);
        // 规范化本地存储的体重，修复错误放大（例如700 -> 70）
        if (typeof hd.weight === 'number' && hd.weight >= 300) {
          let w = hd.weight;
          while (w >= 300) {
            w = w / 10;
          }
          hd.weight = Math.round(w * 10) / 10;
        }
        return hd;
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
      const fileMap = await this.readHealthDataFile();
      return fileMap.has(dateKey);
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
      const fileMap = await this.readHealthDataFile();
      if (fileMap.has(dateKey)) {
        fileMap.delete(dateKey);
        await this.writeHealthDataFile(fileMap);
      }
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
      const fileMap = await this.readHealthDataFile();
      const keys = Array.from(fileMap.keys());
      for (let i = 0; i < keys.length; i += 1) {
        const key = keys[i];
        const date = this.parseDateFromKey(key);
        if (date) dates.push(date);
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