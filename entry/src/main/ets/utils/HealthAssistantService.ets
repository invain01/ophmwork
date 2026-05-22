/**
 * 健康助手服务
 * 通过后端代理调用 GPT API 获取回复
 */
import http from '@ohos.net.http';
import { ApiConfig } from './Constants';

export interface HealthAssistantHistoryItem {
  role: string;
  content: string;
}

interface HealthAssistantRequestPayload {
  message: string;
  history: HealthAssistantHistoryItem[];
}

interface HealthAssistantResponseData {
  reply?: string;
  message?: string;
  content?: string;
}

interface HealthAssistantResponsePayload {
  reply?: string;
  message?: string;
  source?: string;
  reason?: string;
  error?: string;
  data?: HealthAssistantResponseData;
}

export class HealthAssistantService {
  private static instance: HealthAssistantService | null = null;

  private constructor() {}

  public static getInstance(): HealthAssistantService {
    if (!HealthAssistantService.instance) {
      HealthAssistantService.instance = new HealthAssistantService();
    }
    return HealthAssistantService.instance;
  }

  public async sendMessage(message: string, history: HealthAssistantHistoryItem[] = []): Promise<string> {
    const trimmed = message.trim();
    if (!trimmed) {
      throw new Error('消息不能为空');
    }

    const payload: HealthAssistantRequestPayload = {
      message: trimmed,
      history
    };

    for (const baseUrl of this.getBaseUrlCandidates()) {
      try {
        const responseText = await this.requestText(`${baseUrl}${ApiConfig.HEALTH_ASSISTANT_CHAT_PATH}`, http.RequestMethod.POST, payload);
        const parsed = this.parseJson(responseText);
        const reply = this.extractReply(parsed);
        if (reply) {
          return reply;
        }
      } catch (error) {
        console.error('Failed to send health assistant message:', error);
      }
    }

    throw new Error('健康助手暂时不可用，请稍后重试');
  }

  private getBaseUrlCandidates(): string[] {
    const configured = ApiConfig.BASE_URL?.trim();
    const candidates: string[] = [];
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

  private parseJson(text: string): Object | null {
    if (!text) {
      return null;
    }
    try {
      return JSON.parse(text) as Object;
    } catch (error) {
      console.error('Failed to parse health assistant response:', error);
      return null;
    }
  }

  private extractReply(payload: Object | null): string {
    if (!payload || typeof payload !== 'object') {
      return '';
    }

    const data = payload as HealthAssistantResponsePayload;
    const candidates = [
      data.reply,
      data.message,
      data.data?.reply,
      data.data?.message,
      data.data?.content
    ];

    for (const candidate of candidates) {
      if (typeof candidate === 'string' && candidate.trim()) {
        return candidate.trim();
      }
    }

    if (typeof data.error === 'string' && data.error.trim()) {
      return data.error.trim();
    }

    return '';
  }
}