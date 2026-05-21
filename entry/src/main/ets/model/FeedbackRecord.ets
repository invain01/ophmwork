/**
 * 用户反馈记录
 */
export interface FeedbackRecordInit {
  id?: string;
  username?: string;
  content?: string;
  createdAt?: string;
}

export class FeedbackRecord {
  id: string = '';
  username: string = '';
  content: string = '';
  createdAt: string = '';

  constructor(data?: FeedbackRecordInit) {
    if (data) {
      if (data.id !== undefined) this.id = data.id;
      if (data.username !== undefined) this.username = data.username;
      if (data.content !== undefined) this.content = data.content;
      if (data.createdAt !== undefined) this.createdAt = data.createdAt;
    }
  }
}