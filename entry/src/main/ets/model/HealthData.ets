/**
 * 健康数据模型
 */
export class HealthData {
  // 步数相关
  steps: number = 0;
  stepGoal: number = 10000;
  
  // 饮水相关
  waterIntake: number = 0; // 毫升
  waterGoal: number = 2000; // 毫升

  // 体重相关
  weight: number = 0; // 千克
  
  // 睡眠相关
  sleepHours: number = 0;
  sleepGoal: number = 8;
  
  // 心率
  heartRate: number = 0;
  
  
  // 更新时间
  lastUpdated: string = new Date().toLocaleDateString();
  
  constructor(data?: Partial<HealthData>) {
    if (data) {
      if (data.steps !== undefined) this.steps = data.steps;
      if (data.stepGoal !== undefined) this.stepGoal = data.stepGoal;
      if (data.waterIntake !== undefined) this.waterIntake = data.waterIntake;
      if (data.waterGoal !== undefined) this.waterGoal = data.waterGoal;
      if (data.weight !== undefined) this.weight = data.weight;
      if (data.sleepHours !== undefined) this.sleepHours = data.sleepHours;
      if (data.sleepGoal !== undefined) this.sleepGoal = data.sleepGoal;
      if (data.heartRate !== undefined) this.heartRate = data.heartRate;
      
      if (data.lastUpdated !== undefined) this.lastUpdated = data.lastUpdated;
    }
  }
  
  // 计算步数完成百分比
  get stepsPercentage(): number {
    return this.calculatePercentage(this.steps, this.stepGoal);
  }
  
  // 计算饮水完成百分比
  get waterPercentage(): number {
    return this.calculatePercentage(this.waterIntake, this.waterGoal);
  }
  
  // 计算睡眠完成百分比
  get sleepPercentage(): number {
    return this.calculatePercentage(this.sleepHours, this.sleepGoal);
  }
  
  // 计算卡路里完成百分比
  // 卡路里相关已移除
  
  // 增加步数
  addSteps(steps: number): void {
    this.steps += steps;
  }
  
  // 增加饮水量
  addWater(ml: number): void {
    this.waterIntake += ml;
  }

  private calculatePercentage(current: number, goal: number): number {
    if (!goal || goal <= 0 || typeof goal !== 'number') return 0;
    if (typeof current !== 'number' || isNaN(current)) return 0;
    const percentage = (current / goal) * 100;
    if (isNaN(percentage) || !isFinite(percentage)) return 0;
    return percentage > 100 ? 100 : percentage;
  }

  // 更新体重
  updateWeight(weight: number): void {
    this.weight = weight;
  }
  
  // 更新睡眠时长
  updateSleep(hours: number): void {
    this.sleepHours = hours;
  }
  
  // 更新心率
  updateHeartRate(rate: number): void {
    this.heartRate = rate;
  }
  
  // 更新卡路里
  // 卡路里方法已移除
}