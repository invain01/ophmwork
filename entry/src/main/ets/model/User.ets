/**
 * 用户模型
 */
export class User {
  id: string = 'user_001';
  name: string = '张三';
  avatar: string = '';
  age: number = 28;
  height: number = 175; // 厘米
  weight: number = 70; // 千克
  gender: 'male' | 'female' = 'male';
  
  // 健康目标
  dailyStepGoal: number = 10000;
  dailyWaterGoal: number = 2000; // 毫升
  dailySleepGoal: number = 8; // 小时
  dailyCalorieGoal: number = 500; // 千卡
  
  // 设置
  darkMode: boolean = false;
  notifications: boolean = true;
  healthReminders: boolean = true;
  
  constructor(data?: Partial<User>) {
    if (data) {
      if (data.id !== undefined) this.id = data.id;
      if (data.name !== undefined) this.name = data.name;
      if (data.avatar !== undefined) this.avatar = data.avatar;
      if (data.age !== undefined) this.age = data.age;
      if (data.height !== undefined) this.height = data.height;
      if (data.weight !== undefined) this.weight = data.weight;
      if (data.gender !== undefined) this.gender = data.gender;
      if (data.dailyStepGoal !== undefined) this.dailyStepGoal = data.dailyStepGoal;
      if (data.dailyWaterGoal !== undefined) this.dailyWaterGoal = data.dailyWaterGoal;
      if (data.dailySleepGoal !== undefined) this.dailySleepGoal = data.dailySleepGoal;
      if (data.dailyCalorieGoal !== undefined) this.dailyCalorieGoal = data.dailyCalorieGoal;
      if (data.darkMode !== undefined) this.darkMode = data.darkMode;
      if (data.notifications !== undefined) this.notifications = data.notifications;
      if (data.healthReminders !== undefined) this.healthReminders = data.healthReminders;
    }
  }
  
  // 计算BMI
  get bmi(): number {
    const heightInMeters = this.height / 100;
    const bmiValue = this.weight / (heightInMeters * heightInMeters);
    // 简单实现，避免使用toFixed
    return Math.floor(bmiValue * 10) / 10;
  }
  
  // 获取BMI分类
  get bmiCategory(): string {
    const bmi = this.bmi;
    if (bmi < 18.5) return '偏瘦';
    if (bmi < 24) return '正常';
    if (bmi < 28) return '超重';
    return '肥胖';
  }
  
  // 获取BMI颜色
  get bmiColor(): string {
    const bmi = this.bmi;
    if (bmi < 18.5) return '#FF9800'; // 橙色
    if (bmi < 24) return '#4CAF50'; // 绿色
    if (bmi < 28) return '#FFC107'; // 黄色
    return '#F44336'; // 红色
  }
  
  // 切换深色模式
  toggleDarkMode(): void {
    this.darkMode = !this.darkMode;
  }
  
  // 更新个人信息
  updateProfile(name: string, age: number, height: number, weight: number): void {
    this.name = name;
    this.age = age;
    this.height = height;
    this.weight = weight;
  }
  
  // 更新健康目标
  updateGoals(stepGoal: number, waterGoal: number, sleepGoal: number, calorieGoal: number): void {
    this.dailyStepGoal = stepGoal;
    this.dailyWaterGoal = waterGoal;
    this.dailySleepGoal = sleepGoal;
    this.dailyCalorieGoal = calorieGoal;
  }
}