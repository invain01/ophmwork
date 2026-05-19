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
  sleepHours: number = 0;
  sleepGoal: number = 8;
  
  // 心率
  heartRate: number = 0;
  
  // 卡路里
  caloriesBurned: number = 0;
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
    // 防护：确保stepGoal不为0或undefined
    if (!this.stepGoal || this.stepGoal <= 0) return 0;
    // 防护：确保steps是有效数字
    if (typeof this.steps !== 'number' || isNaN(this.steps)) return 0;
    const percentage = (this.steps / this.stepGoal) * 100;
    // 防护：确保计算结果是有效数字
    if (isNaN(percentage) || !isFinite(percentage)) return 0;
    return percentage > 100 ? 100 : percentage;
  }
  
  // 计算饮水完成百分比
  get waterPercentage(): number {
    // 防护：确保waterGoal不为0或undefined
    if (!this.waterGoal || this.waterGoal <= 0) return 0;
    // 防护：确保waterIntake是有效数字
    if (typeof this.waterIntake !== 'number' || isNaN(this.waterIntake)) return 0;
    const percentage = (this.waterIntake / this.waterGoal) * 100;
    // 防护：确保计算结果是有效数字
    if (isNaN(percentage) || !isFinite(percentage)) return 0;
    return percentage > 100 ? 100 : percentage;
  }
  
  // 计算睡眠完成百分比
  get sleepPercentage(): number {
    // 防护：确保sleepGoal不为0或undefined
    if (!this.sleepGoal || this.sleepGoal <= 0) return 0;
    // 防护：确保sleepHours是有效数字
    if (typeof this.sleepHours !== 'number' || isNaN(this.sleepHours)) return 0;
    const percentage = (this.sleepHours / this.sleepGoal) * 100;
    // 防护：确保计算结果是有效数字
    if (isNaN(percentage) || !isFinite(percentage)) return 0;
    return percentage > 100 ? 100 : percentage;
  }
  
  // 计算卡路里完成百分比
  get caloriesPercentage(): number {
    // 防护：确保calorieGoal不为0或undefined
    if (!this.calorieGoal || this.calorieGoal <= 0) return 0;
    // 防护：确保caloriesBurned是有效数字
    if (typeof this.caloriesBurned !== 'number' || isNaN(this.caloriesBurned)) return 0;
    const percentage = (this.caloriesBurned / this.calorieGoal) * 100;
    // 防护：确保计算结果是有效数字
    if (isNaN(percentage) || !isFinite(percentage)) return 0;
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