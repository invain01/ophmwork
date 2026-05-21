/**
 * 后端健康数据服务
 * 支持日数据与周数据读写
 */
import http from '@ohos.net.http';
import { ApiConfig } from './Constants';
import { HealthData } from '../model/HealthData';

interface DailyHealthRecordPayload {
  date?: string;
  steps?: number | string;
  stepGoal?: number | string;
  waterIntake?: number | string;
  waterGoal?: number | string;
  weight?: number | string;
  sleepHours?: number | string;
  sleepGoal?: number | string;
  heartRate?: number | string;
  lastUpdated?: string;
}

interface DailyHealthUpsertPayload extends DailyHealthRecordPayload {
  userId?: string;
}

type JsonPayload = Object | Object[];

export class DailyHealthRecord {
  date: string;
  steps: number;
  waterIntake: number;
  weight: number;
  sleepHours: number;
  heartRate: number;
  
  constructor(
    date: string,
    steps: number,
    waterIntake: number,
    weight: number,
    sleepHours: number,
    heartRate: number
  ) {
    this.date = date;
    this.steps = steps;
    this.waterIntake = waterIntake;
    this.weight = weight;
    this.sleepHours = sleepHours;
    this.heartRate = heartRate;
  }
}

export class HealthApiService {
  private static instance: HealthApiService | null = null;

  private constructor() {}

  public static getInstance(): HealthApiService {
    if (!HealthApiService.instance) {
      HealthApiService.instance = new HealthApiService();
    }
    return HealthApiService.instance;
  }

  private getBaseUrlCandidates(): string[] {
    const candidates: string[] = [];
    const configured = ApiConfig.BASE_URL?.trim();
    if (configured) {
      candidates.push(configured);
    }
    candidates.push('http://localhost:3000');
    candidates.push('http://127.0.0.1:3000');
    candidates.push('http://10.0.2.2:3000');

    const unique: string[] = [];
    for (const value of candidates) {
      if (value && unique.indexOf(value) < 0) {
        unique.push(value);
      }
    }
    return unique;
  }

  public async fetchDailyHealthData(date: Date, userId?: string): Promise<HealthData | null> {
    const dateKey = this.formatDate(date);
    const queryUser = userId ? `&userId=${encodeURIComponent(userId)}` : '';
    const query = `?date=${dateKey}${queryUser}`;

    for (const baseUrl of this.getBaseUrlCandidates()) {
      try {
        const body = await this.requestText(`${baseUrl}${ApiConfig.HEALTH_DAILY_PATH}${query}`, http.RequestMethod.GET);
        const payload = this.parseJson(body);
        const record = this.extractSingleRecord(payload);
        if (record) {
          return this.buildHealthData(record, dateKey);
        }
      } catch (error) {
        console.error('Failed to fetch daily health data:', error);
      }
    }

    return null;
  }

  public async saveDailyHealthData(date: Date, healthData: HealthData, userId?: string): Promise<boolean> {
    const dateKey = this.formatDate(date);
    const payload: DailyHealthUpsertPayload = {
      userId,
      date: dateKey,
      steps: healthData.steps,
      stepGoal: healthData.stepGoal,
      waterIntake: healthData.waterIntake,
      waterGoal: healthData.waterGoal,
      weight: healthData.weight,
      sleepHours: healthData.sleepHours,
      sleepGoal: healthData.sleepGoal,
      heartRate: healthData.heartRate,
      lastUpdated: healthData.lastUpdated
    };

    for (const baseUrl of this.getBaseUrlCandidates()) {
      try {
        await this.requestText(`${baseUrl}${ApiConfig.HEALTH_DAILY_PATH}`, http.RequestMethod.PUT, payload);
        return true;
      } catch (error) {
        console.error('Failed to save daily health data:', error);
      }
    }

    return false;
  }

  public async fetchHealthDataDates(startDate?: Date, endDate?: Date, userId?: string): Promise<string[]> {
    const params: string[] = [];
    if (startDate) {
      params.push(`startDate=${this.formatDate(startDate)}`);
    }
    if (endDate) {
      params.push(`endDate=${this.formatDate(endDate)}`);
    }
    if (userId) {
      params.push(`userId=${encodeURIComponent(userId)}`);
    }

    const query = params.length ? `?${params.join('&')}` : '';

    for (const baseUrl of this.getBaseUrlCandidates()) {
      try {
        const body = await this.requestText(`${baseUrl}${ApiConfig.HEALTH_DATES_PATH}${query}`, http.RequestMethod.GET);
        const payload = this.parseJson(body);
        const rawDates = this.extractDateArray(payload);
        const normalized: string[] = [];
        for (const value of rawDates) {
          const key = this.normalizeDateKey(value);
          if (key) {
            normalized.push(key);
          }
        }
        if (normalized.length > 0) {
          return normalized;
        }
      } catch (error) {
        console.error('Failed to fetch health data dates:', error);
      }
    }

    return [];
  }

  public async fetchWeeklyHealthData(startDate: Date, endDate: Date, userId?: string): Promise<DailyHealthRecord[]> {
    const start = this.formatDate(startDate);
    const end = this.formatDate(endDate);
    const queryUser = userId ? `&userId=${encodeURIComponent(userId)}` : '';

    for (const baseUrl of this.getBaseUrlCandidates()) {
      try {
        const body = await this.requestText(`${baseUrl}${ApiConfig.HEALTH_WEEKLY_PATH}?startDate=${start}&endDate=${end}${queryUser}`, http.RequestMethod.GET);
        const payload = this.parsePayload(body);
        const records = this.normalizeRecords(payload);
        if (records.length > 0) {
          return records;
        }
      } catch (error) {
        console.error('Failed to fetch weekly health data:', error);
      }
    }

    const fallbackDates = await this.fetchHealthDataDates(startDate, endDate, userId);
    if (fallbackDates.length === 0) {
      return [];
    }

    const fallbackRecords: DailyHealthRecord[] = [];
    for (const dateKey of fallbackDates) {
      const parsed = this.parseDateKey(dateKey);
      if (!parsed) {
        continue;
      }
      const healthData = await this.fetchDailyHealthData(parsed, userId);
      if (healthData) {
        fallbackRecords.push(new DailyHealthRecord(
          dateKey,
          healthData.steps,
          healthData.waterIntake,
          healthData.weight,
          healthData.sleepHours,
          healthData.heartRate
        ));
      }
    }

    return fallbackRecords;
  }

  private async requestText(url: string, method: http.RequestMethod, body?: object): Promise<string> {
    const request = http.createHttp();
    try {
      const response = await request.request(url, {
        method,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: body ? JSON.stringify(body) : undefined,
        connectTimeout: 60000,
        readTimeout: 60000,
        expectDataType: http.HttpDataType.STRING
      });

      return typeof response.result === 'string' ? response.result : '';
    } finally {
      request.destroy();
    }
  }

  private parseJson(text: string): JsonPayload | null {
    if (!text) return null;
    try {
      return JSON.parse(text) as JsonPayload;
    } catch (error) {
      console.error('Failed to parse health data response:', error);
      return null;
    }
  }

  private parsePayload(text: string): DailyHealthRecordPayload[] {
    const parsed = this.parseJson(text);
    return this.extractRecordArray(parsed);
  }

  private extractRecordArray(payload: JsonPayload | null): DailyHealthRecordPayload[] {
    if (Array.isArray(payload)) {
      return payload as DailyHealthRecordPayload[];
    }
    if (!payload || typeof payload !== 'object') {
      return [];
    }
    const container = payload as Record<string, Object>;
    const keys = ['data', 'records', 'list', 'items', 'result'];
    for (const key of keys) {
      const value = container[key];
      const found = this.extractRecordArray(value as JsonPayload);
      if (found.length > 0) {
        return found;
      }
    }
    return [];
  }

  private extractSingleRecord(payload: JsonPayload | null): DailyHealthRecordPayload | null {
    if (!payload) {
      return null;
    }
    if (Array.isArray(payload)) {
      return payload.length > 0 ? (payload[0] as DailyHealthRecordPayload) : null;
    }
    if (typeof payload !== 'object') {
      return null;
    }

    const container = payload as Record<string, Object>;
    if (this.looksLikeRecord(container)) {
      return container as DailyHealthRecordPayload;
    }

    const keys = ['data', 'record', 'item', 'result'];
    for (const key of keys) {
      const value = container[key];
      const found = this.extractSingleRecord(value as JsonPayload);
      if (found) {
        return found;
      }
    }
    return null;
  }

  private extractDateArray(payload: JsonPayload | null): string[] {
    if (Array.isArray(payload)) {
      return payload.map((item: Object) => String(item));
    }
    if (!payload || typeof payload !== 'object') {
      return [];
    }

    const container = payload as Record<string, Object>;
    const keys = ['data', 'dates', 'list', 'items', 'result'];
    for (const key of keys) {
      const value = container[key];
      const found = this.extractDateArray(value as JsonPayload);
      if (found.length > 0) {
        return found;
      }
    }
    return [];
  }

  private normalizeRecords(records: DailyHealthRecordPayload[]): DailyHealthRecord[] {
    if (!Array.isArray(records)) return [];
    const normalized: DailyHealthRecord[] = [];
    for (const item of records) {
      const normalizedDate = this.normalizeDateKey(item?.date);
      if (!normalizedDate) {
        continue;
      }
      normalized.push(new DailyHealthRecord(
        normalizedDate,
        this.toNumber(item.steps),
        this.toNumber(item.waterIntake),
        this.toNumber(item.weight),
        this.toNumber(item.sleepHours),
        this.toNumber(item.heartRate)
      ));
    }
    return normalized;
  }

  // 规范化后端来的体重值（修复因存储/导入导致的放大问题，例如700应为70）
  private normalizeWeight(value?: number | string, fallback: number = 0): number {
    let v = this.toNumber(value, fallback);
    // 若体重异常大，按10倍缩放回合理范围（例如700 -> 70）
    while (v >= 300) {
      v = v / 10;
    }
    // 保留一位小数
    return Math.round(v * 10) / 10;
  }

  private toNumber(value?: number | string, fallback: number = 0): number {
    if (typeof value === 'number' && isFinite(value)) {
      return value;
    }
    if (typeof value === 'string') {
      const parsed = Number(value);
      return isFinite(parsed) ? parsed : 0;
    }
    return fallback;
  }

  private normalizeDateKey(value?: string): string | null {
    if (typeof value !== 'string' || value.length === 0) {
      return null;
    }
    const match = value.match(/(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})/);
    if (match) {
      const year = match[1];
      const month = this.pad2(match[2]);
      const day = this.pad2(match[3]);
      return `${year}-${month}-${day}`;
    }
    const parsed = new Date(value);
    if (isNaN(parsed.getTime())) {
      return null;
    }
    return this.formatDate(parsed);
  }

  private pad2(value: string | number): string {
    return String(value).padStart(2, '0');
  }

  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private parseDateKey(value: string): Date | null {
    const match = value.match(/^(\d{4})-(\d{2})-(\d{2})$/);
    if (!match) {
      return null;
    }
    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);
    const parsed = new Date(year, month - 1, day);
    if (isNaN(parsed.getTime())) {
      return null;
    }
    return parsed;
  }

  private looksLikeRecord(payload: Record<string, Object>): boolean {
    return typeof payload.date === 'string' || typeof payload.steps !== 'undefined';
  }

  private buildHealthData(payload: DailyHealthRecordPayload, fallbackDate: string): HealthData {
    const data = new HealthData();
    data.steps = this.toNumber(payload.steps, data.steps);
    data.stepGoal = this.toNumber(payload.stepGoal, data.stepGoal);
    data.waterIntake = this.toNumber(payload.waterIntake, data.waterIntake);
    data.waterGoal = this.toNumber(payload.waterGoal, data.waterGoal);
    data.weight = this.normalizeWeight(payload.weight, data.weight);
    data.sleepHours = this.toNumber(payload.sleepHours, data.sleepHours);
    data.sleepGoal = this.toNumber(payload.sleepGoal, data.sleepGoal);
    data.heartRate = this.toNumber(payload.heartRate, data.heartRate);
    data.lastUpdated = payload.lastUpdated ?? payload.date ?? fallbackDate;
    return data;
  }
}
