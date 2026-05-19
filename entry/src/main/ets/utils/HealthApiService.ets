/**
 * 后端健康数据服务
 * 仅用于拉取最近一周健康数据
 */
import http from '@ohos.net.http';
import { ApiConfig } from './Constants';

interface DailyHealthRecordPayload {
  date?: string;
  steps?: number | string;
  waterIntake?: number | string;
  sleepHours?: number | string;
  heartRate?: number | string;
  caloriesBurned?: number | string;
}

interface WeeklyHealthResponse {
  data?: DailyHealthRecordPayload[];
}

export class DailyHealthRecord {
  date: string;
  steps: number;
  waterIntake: number;
  sleepHours: number;
  heartRate: number;
  caloriesBurned: number;

  constructor(
    date: string,
    steps: number,
    waterIntake: number,
    sleepHours: number,
    heartRate: number,
    caloriesBurned: number
  ) {
    this.date = date;
    this.steps = steps;
    this.waterIntake = waterIntake;
    this.sleepHours = sleepHours;
    this.heartRate = heartRate;
    this.caloriesBurned = caloriesBurned;
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

  public async fetchWeeklyHealthData(startDate: Date, endDate: Date, userId?: string): Promise<DailyHealthRecord[]> {
    const baseUrl = ApiConfig.BASE_URL?.trim();
    if (!baseUrl) {
      return [];
    }

    const start = this.formatDate(startDate);
    const end = this.formatDate(endDate);
    const queryUser = userId ? `&userId=${encodeURIComponent(userId)}` : '';
    const url = `${baseUrl}${ApiConfig.WEEKLY_HEALTH_PATH}?startDate=${start}&endDate=${end}${queryUser}`;

    const request = http.createHttp();
    try {
      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        },
        connectTimeout: 60000,
        readTimeout: 60000,
        expectDataType: http.HttpDataType.STRING
      });

      const body = typeof response.result === 'string' ? response.result : '';
      const payload = this.parsePayload(body);
      return this.normalizeRecords(payload);
    } catch (error) {
      console.error('Failed to fetch weekly health data:', error);
      return [];
    } finally {
      request.destroy();
    }
  }

  private parsePayload(text: string): DailyHealthRecordPayload[] {
    if (!text) return [];
    try {
      const parsed = JSON.parse(text) as object;
      return this.extractRecordArray(parsed);
    } catch (error) {
      console.error('Failed to parse weekly health data:', error);
      return [];
    }
  }

  private extractRecordArray(payload: object): DailyHealthRecordPayload[] {
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
      const found = this.extractRecordArray(value);
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
        this.toNumber(item.sleepHours),
        this.toNumber(item.heartRate),
        this.toNumber(item.caloriesBurned)
      ));
    }
    return normalized;
  }

  private toNumber(value?: number | string): number {
    if (typeof value === 'number' && isFinite(value)) {
      return value;
    }
    if (typeof value === 'string') {
      const parsed = Number(value);
      return isFinite(parsed) ? parsed : 0;
    }
    return 0;
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
}
