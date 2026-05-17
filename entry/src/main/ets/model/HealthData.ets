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
  
  // 睡眠相关
  sleepHours: number = 7.5;
  sleepGoal: number = 8;
  
  // 心率
  heartRate: number = 72;
  
  // 卡路里
  caloriesBurned: number = 450;
  calorieGoal: number = 500;
  
  // 更新时间
  lastUpdated: string = new Date().toLocaleDateString();
  
  constructor(data?: Partial<HealthData>) {
    if (data) {
      if (data.steps !== undefined) this.steps = data.steps;
      if (data.stepGoal !== undefined) this.stepGoal = data.stepGoal;
      if (data.waterIntake !== undefined) this.waterIntake = data.waterIntake;
      if (data.waterGoal !== undefined) this.waterGoal = data.waterGoal;
      if (data.sleepHours !== undefined) this.sleepHours = data.sleepHours;
      if (data.sleepGoal !== undefined) this.sleepGoal = data.sleepGoal;
      if (data.heartRate !== undefined) this.heartRate = data.heartRate;
      if (data.caloriesBurned !== undefined) this.caloriesBurned = data.caloriesBurned;
      if (data.calorieGoal !== undefined) this.calorieGoal = data.calorieGoal;
      if (data.lastUpdated !== undefined) this.lastUpdated = data.lastUpdated;
    }
  }
  
  // 计算步数完成百分比
  get stepsPercentage(): number {
    const percentage = (this.steps / this.stepGoal) * 100;
    return percentage > 100 ? 100 : percentage;
  }
  
  // 计算饮水完成百分比
  get waterPercentage(): number {
    const percentage = (this.waterIntake / this.waterGoal) * 100;
    return percentage > 100 ? 100 : percentage;
  }
  
  // 计算睡眠完成百分比
  get sleepPercentage(): number {
    const percentage = (this.sleepHours / this.sleepGoal) * 100;
    return percentage > 100 ? 100 : percentage;
  }
  
  // 计算卡路里完成百分比
  get caloriesPercentage(): number {
    const percentage = (this.caloriesBurned / this.calorieGoal) * 100;
    return percentage > 100 ? 100 : percentage;
  }
  
  // 增加步数
  addSteps(steps: number): void {
    this.steps += steps;
  }
  
  // 增加饮水量
  addWater(ml: number): void {
    this.waterIntake += ml;
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
  updateCalories(calories: number): void {
    this.caloriesBurned = calories;
  }
}