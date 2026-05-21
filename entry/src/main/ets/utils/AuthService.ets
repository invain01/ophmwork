/**
 * 认证服务
 * 使用Preferences存储用户凭证、登录状态、登录统计和反馈信息
 */
import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { FeedbackRecord, FeedbackRecordInit } from '../model/FeedbackRecord';
import { User } from '../model/User';

const PREFERENCES_NAME = 'harmonycare_auth';
const KEY_CURRENT_USER = 'current_user';
const KEY_USERS_PREFIX = 'user_';
const KEY_USER_INDEX = 'user_index';
const KEY_FEEDBACK_LIST = 'feedback_list';
const KEY_SYSTEM_STATS = 'system_stats';
const MAX_FEEDBACK_RECORDS = 100;

interface SystemStats {
  totalUsers: number;
  totalLogins: number;
  totalFeedbacks: number;
}

interface DashboardSnapshot {
  users: User[];
  feedbacks: FeedbackRecord[];
  totalUsers: number;
  totalLoginCount: number;
  totalFeedbackCount: number;
}

export class AuthService {
  private static instance: AuthService | null = null;
  private preferences: preferences.Preferences | null = null;

  private constructor() {}

  public static getInstance(): AuthService {
    if (!AuthService.instance) {
      AuthService.instance = new AuthService();
    }
    return AuthService.instance;
  }

  /**
   * 初始化Preferences
   */
  private async initPreferences(): Promise<void> {
    if (this.preferences) {
      return;
    }
    try {
      this.preferences = await preferences.getPreferences(this.getContext(), PREFERENCES_NAME);
    } catch (error) {
      console.error('Failed to get preferences:', error);
      throw new Error(`Failed to get preferences: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 获取上下文
   */
  private getContext(): Context {
    // 在Ability中可以通过globalThis.abilityContext获取
    // 这里简化处理，实际使用时需要传入context
    return globalThis.abilityContext as Context;
  }

  private async readUserIndex(): Promise<string[]> {
    await this.initPreferences();
    if (!this.preferences) {
      throw new Error('Preferences not initialized');
    }

    const raw = await this.preferences.get(KEY_USER_INDEX, '');
    if (raw === '') {
      return [];
    }

    try {
      const parsed = JSON.parse(raw as string) as string[];
      if (!Array.isArray(parsed)) {
        return [];
      }

      const index: string[] = [];
      for (let i = 0; i < parsed.length; i += 1) {
        const username = parsed[i];
        if (typeof username === 'string' && username.trim()) {
          index.push(username);
        }
      }
      return index;
    } catch (error) {
      console.error('Failed to parse user index:', error as Error);
      return [];
    }
  }

  private async saveUserIndex(usernames: string[]): Promise<void> {
    await this.initPreferences();
    if (!this.preferences) {
      throw new Error('Preferences not initialized');
    }

    await this.preferences.put(KEY_USER_INDEX, JSON.stringify(usernames));
    await this.preferences.flush();
  }

  private async ensureUserInIndex(username: string): Promise<void> {
    const trimmedUsername = username.trim();
    if (!trimmedUsername) {
      return;
    }

    const index = await this.readUserIndex();
    if (index.indexOf(trimmedUsername) >= 0) {
      return;
    }

    index.push(trimmedUsername);
    await this.saveUserIndex(index);
  }

  private async saveUserRecord(user: User): Promise<void> {
    await this.initPreferences();
    if (!this.preferences) {
      throw new Error('Preferences not initialized');
    }

    const userKey = KEY_USERS_PREFIX + user.username;
    const userData = JSON.stringify(user);
    await this.preferences.put(userKey, userData);
    await this.ensureUserInIndex(user.username);
  }

  private async readFeedbackRecords(): Promise<FeedbackRecord[]> {
    await this.initPreferences();
    if (!this.preferences) {
      throw new Error('Preferences not initialized');
    }

    const raw = await this.preferences.get(KEY_FEEDBACK_LIST, '');
    if (raw === '') {
      return [];
    }

    try {
      const parsed = JSON.parse(raw as string) as FeedbackRecord[];
      if (!Array.isArray(parsed)) {
        return [];
      }

      const records: FeedbackRecord[] = [];
      for (let i = 0; i < parsed.length; i += 1) {
        const item = parsed[i];
        if (item && typeof item === 'object') {
          records.push(new FeedbackRecord(item as Partial<FeedbackRecord>));
        }
      }
      return records;
    } catch (error) {
      console.error('Failed to parse feedback records:', error as Error);
      return [];
    }
  }

  private async saveFeedbackRecords(records: FeedbackRecord[]): Promise<void> {
    await this.initPreferences();
    if (!this.preferences) {
      throw new Error('Preferences not initialized');
    }

    await this.preferences.put(KEY_FEEDBACK_LIST, JSON.stringify(records));
    await this.preferences.flush();
  }

  private async readSystemStats(): Promise<SystemStats> {
    await this.initPreferences();
    if (!this.preferences) {
      throw new Error('Preferences not initialized');
    }

    const raw = await this.preferences.get(KEY_SYSTEM_STATS, '');
    if (raw === '') {
      return {
        totalUsers: 0,
        totalLogins: 0,
        totalFeedbacks: 0
      };
    }

    try {
      const parsed = JSON.parse(raw as string) as SystemStats;
      return {
        totalUsers: typeof parsed.totalUsers === 'number' ? parsed.totalUsers : 0,
        totalLogins: typeof parsed.totalLogins === 'number' ? parsed.totalLogins : 0,
        totalFeedbacks: typeof parsed.totalFeedbacks === 'number' ? parsed.totalFeedbacks : 0
      };
    } catch (error) {
      console.error('Failed to parse system stats:', error as Error);
      return {
        totalUsers: 0,
        totalLogins: 0,
        totalFeedbacks: 0
      };
    }
  }

  private async saveSystemStats(stats: SystemStats): Promise<void> {
    await this.initPreferences();
    if (!this.preferences) {
      throw new Error('Preferences not initialized');
    }

    await this.preferences.put(KEY_SYSTEM_STATS, JSON.stringify(stats));
    await this.preferences.flush();
  }

  private async incrementSystemStats(deltaUsers: number, deltaLogins: number, deltaFeedbacks: number): Promise<void> {
    const stats = await this.readSystemStats();
    stats.totalUsers += deltaUsers;
    stats.totalLogins += deltaLogins;
    stats.totalFeedbacks += deltaFeedbacks;
    await this.saveSystemStats(stats);
  }

  /**
   * 注册新用户
   * @param username 用户名
   * @param password 密码
   * @param email 邮箱（可选）
   * @returns 注册成功返回true，用户已存在返回false
   */
  public async register(username: string, password: string, email: string = ''): Promise<boolean> {
    await this.initPreferences();
    if (!this.preferences) {
      throw new Error('Preferences not initialized');
    }

    // 检查用户是否已存在
    const existingUser = await this.preferences.get(KEY_USERS_PREFIX + username, '');
    if (existingUser !== '') {
      return false; // 用户已存在
    }

    // 创建新用户
    const user = new User();
    user.id = 'user_' + Date.now();
    user.username = username;
    user.password = password;
    user.email = email;
    user.name = username; // 默认使用用户名作为显示名称
    user.age = 0;
    user.height = 0;
    user.weight = 0;
    user.gender = 'male';
    user.loginCount = 0;
    user.dailyStepGoal = 10000;
    user.dailyWaterGoal = 2000;
    user.dailySleepGoal = 8;

    await this.saveUserRecord(user);
    await this.incrementSystemStats(1, 0, 0);

    return true;
  }

  /**
   * 用户登录
   * @param username 用户名
   * @param password 密码
   * @returns 登录成功返回User对象，失败返回null
   */
  public async login(username: string, password: string): Promise<User | null> {
    await this.initPreferences();
    if (!this.preferences) {
      throw new Error('Preferences not initialized');
    }

    const userKey = KEY_USERS_PREFIX + username;
    const userData = await this.preferences.get(userKey, '');
    if (userData === '') {
      return null; // 用户不存在
    }

    try {
      const userObj: Record<string, Object> = JSON.parse(userData as string) as Record<string, Object>;
      const user = new User(userObj as Partial<User>);
      
      // 验证密码
      if (user.password === password) {
        user.loginCount = typeof user.loginCount === 'number' ? user.loginCount + 1 : 1;
        await this.saveUserRecord(user);
        await this.incrementSystemStats(0, 1, 0);
        // 保存当前登录用户
        await this.preferences.put(KEY_CURRENT_USER, JSON.stringify(user));
        await this.preferences.flush();
        return user;
      }
    } catch (error) {
      console.error('Failed to parse user data:', error as Error);
    }

    return null;
  }

  /**
   * 获取当前登录用户
   * @returns 当前登录的User对象，未登录返回null
   */
  public async getCurrentUser(): Promise<User | null> {
    await this.initPreferences();
    if (!this.preferences) {
      throw new Error('Preferences not initialized');
    }

    const userData = await this.preferences.get(KEY_CURRENT_USER, '');
    if (userData === '') {
      return null;
    }

    try {
      const userObj: Record<string, Object> = JSON.parse(userData as string) as Record<string, Object>;
      return new User(userObj as Partial<User>);
    } catch (error) {
      console.error('Failed to parse current user data:', error as Error);
      return null;
    }
  }

  /**
   * 用户登出
   */
  public async logout(): Promise<void> {
    await this.initPreferences();
    if (!this.preferences) {
      return;
    }

    await this.preferences.delete(KEY_CURRENT_USER);
    await this.preferences.flush();
  }

  /**
   * 检查用户是否已登录
   * @returns 已登录返回true，否则返回false
   */
  public async isLoggedIn(): Promise<boolean> {
    const user = await this.getCurrentUser();
    return user !== null;
  }

  /**
   * 更新用户信息
   * @param user 用户对象
   */
  public async updateUser(user: User): Promise<void> {
    await this.initPreferences();
    if (!this.preferences) {
      throw new Error('Preferences not initialized');
    }

    await this.saveUserRecord(user);
    
    // 如果当前用户是同一用户，也更新当前登录用户
    const currentUser = await this.getCurrentUser();
    if (currentUser && currentUser.username === user.username) {
      await this.preferences.put(KEY_CURRENT_USER, JSON.stringify(user));
    }
    
    await this.preferences.flush();
  }

  /**
   * 删除用户（仅用于测试或管理）
   * @param username 用户名
   */
  public async deleteUser(username: string): Promise<void> {
    await this.initPreferences();
    if (!this.preferences) {
      throw new Error('Preferences not initialized');
    }

    const userKey = KEY_USERS_PREFIX + username;
    await this.preferences.delete(userKey);
    await this.preferences.flush();
  }

  /**
   * 清除所有用户数据（仅用于测试）
   */
  public async clearAll(): Promise<void> {
    await this.initPreferences();
    if (!this.preferences) {
      return;
    }

    await this.preferences.clear();
    await this.preferences.flush();
  }

  public async getAllUsers(): Promise<User[]> {
    await this.initPreferences();
    if (!this.preferences) {
      throw new Error('Preferences not initialized');
    }

    const usernames = await this.readUserIndex();
    const currentUser = await this.getCurrentUser();
    if (currentUser && usernames.indexOf(currentUser.username) < 0) {
      usernames.push(currentUser.username);
    }

    const users: User[] = [];
    for (let i = 0; i < usernames.length; i += 1) {
      const username = usernames[i];
      const stored = await this.preferences.get(KEY_USERS_PREFIX + username, '');
      if (stored === '') {
        continue;
      }

      try {
        const userObj: Record<string, Object> = JSON.parse(stored as string) as Record<string, Object>;
        users.push(new User(userObj as Partial<User>));
      } catch (error) {
        console.error('Failed to parse user record:', error as Error);
      }
    }

    return users;
  }

  public async getFeedbackList(): Promise<FeedbackRecord[]> {
    const records = await this.readFeedbackRecords();
    return records.sort((left: FeedbackRecord, right: FeedbackRecord) => {
      return right.createdAt.localeCompare(left.createdAt);
    });
  }

  public async saveFeedback(content: string): Promise<void> {
    const trimmedContent = content.trim();
    if (!trimmedContent) {
      return;
    }

    const currentUser = await this.getCurrentUser();
    const records = await this.readFeedbackRecords();
    const nextRecordInit: FeedbackRecordInit = {
      id: 'feedback_' + Date.now(),
      username: currentUser ? currentUser.username : '匿名用户',
      content: trimmedContent,
      createdAt: new Date().toISOString()
    };
    const nextRecord = new FeedbackRecord(nextRecordInit);

    records.unshift(nextRecord);
    if (records.length > MAX_FEEDBACK_RECORDS) {
      records.length = MAX_FEEDBACK_RECORDS;
    }

    await this.saveFeedbackRecords(records);
    await this.incrementSystemStats(0, 0, 1);
  }

  public async getDashboardSnapshot(): Promise<DashboardSnapshot> {
    const users = await this.getAllUsers();
    const feedbacks = await this.getFeedbackList();
    let totalLoginCount = 0;

    for (let i = 0; i < users.length; i += 1) {
      const loginCount = typeof users[i].loginCount === 'number' ? users[i].loginCount : 0;
      totalLoginCount += loginCount;
    }

    return {
      users,
      feedbacks,
      totalUsers: users.length,
      totalLoginCount,
      totalFeedbackCount: feedbacks.length
    };
  }
}