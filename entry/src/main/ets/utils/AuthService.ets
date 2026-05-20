/**
 * 认证服务
 * 使用Preferences存储用户凭证和登录状态
 */
import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { User } from '../model/User';

const PREFERENCES_NAME = 'harmonycare_auth';
const KEY_CURRENT_USER = 'current_user';
const KEY_USERS_PREFIX = 'user_';

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
    const userKey = KEY_USERS_PREFIX + username;
    const existingUser = await this.preferences.get(userKey, '');
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
    user.dailyStepGoal = 10000;
    user.dailyWaterGoal = 2000;
    user.dailySleepGoal = 8;
    

    // 存储用户数据
    const userData = JSON.stringify(user);
    await this.preferences.put(userKey, userData);
    await this.preferences.flush();

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

    // 更新用户存储
    const userKey = KEY_USERS_PREFIX + user.username;
    const userData = JSON.stringify(user);
    await this.preferences.put(userKey, userData);
    
    // 如果当前用户是同一用户，也更新当前登录用户
    const currentUser = await this.getCurrentUser();
    if (currentUser && currentUser.username === user.username) {
      await this.preferences.put(KEY_CURRENT_USER, userData);
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
}