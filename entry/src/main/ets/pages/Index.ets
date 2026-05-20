/**
 * HarmonyCare 首页
 * 展示用户信息与健康数据概览
 */
import { HealthCard, IconCard, MediumStepRing, ProgressCard, ProgressCardComponent, WaterProgressBar } from '../components/index';
import { HealthData } from '../model/HealthData';
import { User } from '../model/User';
import { AppColors, AppSizes, DefaultValues } from '../utils/Constants';
import { AuthService } from '../utils/AuthService';
import { HealthApiService } from '../utils/HealthApiService';
import { StorageService } from '../utils/StorageService';
import router from '@ohos.router';


@Entry
@Component
struct Index {
  // 用户数据
  @State user: User = new User();
  
  // 健康数据
  @State healthData: HealthData = new HealthData();

  // 当前选中的数据日期
  @State selectedDate: Date = new Date();

  // 体重输入与昨日对比
  @State weightText: string = '';
  @State previousWeight: number = 0;
  @State hasPreviousWeight: boolean = false;
  @State weightCompareTextFromJson: string = '较昨日 --';
  @State weightCompareColorFromJson: string = AppColors.GRAY_600;
  
  async aboutToAppear() {
    // 检查登录状态
    const isLoggedIn = await AuthService.getInstance().isLoggedIn();
    if (!isLoggedIn) {
      router.replaceUrl({ url: 'pages/Login' });
      return;
    }

    await this.loadUser();
    await this.loadSelectedDateAndData();
    
    // 模拟加载数据
    setTimeout(() => {
      this.showWelcome = false;
    }, 1000);
  }

  async onPageShow() {
    await this.loadUser();
    await this.loadSelectedDateAndData();
  }
  
  // 页面滚动位置
  @State scrollOffset: number = 0;
  
  // 是否显示欢迎动画
  @State showWelcome: boolean = true;
  
  // 睡眠数据 - 前六天的模拟数据 + 今天的实际数据
  private historicalSleepData: number[] = [6.5, 7.2, 7.8, 8.1, 6.9, 7.5]; // 周一到周六
  private days: string[] = ['一', '二', '三', '四', '五', '六', '日'];
  
  // 计算完整的睡眠数据（包含今天）
  private get sleepData(): number[] {
    // 前六天的历史数据 + 今天的实际数据
    return [...this.historicalSleepData, this.healthData.sleepHours];
  }
  
  // 计算最大睡眠时长
  private get maxSleep(): number {
    const max = Math.max(...this.sleepData);
    return max > 0 ? max : 8; // 防止除零
  }

  private get waterPercent(): number {
    // 防护：确保healthData存在
    if (!this.healthData) return 0;
    // 防护：确保waterGoal不为0、undefined或NaN
    if (!this.healthData.waterGoal || this.healthData.waterGoal <= 0 || 
        typeof this.healthData.waterGoal !== 'number' || isNaN(this.healthData.waterGoal)) {
      return 0;
    }
    // 防护：确保waterIntake是有效数字
    if (typeof this.healthData.waterIntake !== 'number' || isNaN(this.healthData.waterIntake)) {
      return 0;
    }
    const percentage = this.healthData.waterIntake / this.healthData.waterGoal;
    // 防护：确保计算结果是有效数字
    if (isNaN(percentage) || !isFinite(percentage)) return 0;
    return Math.min(percentage, 1);
  }
  
  // 格式化饮水百分比显示（防止NaN）
  private get waterPercentText(): string {
    const percent = Math.round(this.waterPercent * 100);
    // 确保percent是有效数字
    if (isNaN(percent) || !isFinite(percent)) return '0%';
    return `${percent}%`;
  }

  private goToGoalSetting() {
    router.pushUrl({ url: 'pages/GoalSetting' });
  }

  private goToUserInfoSetting() {
    router.pushUrl({ url: 'pages/StatusSetting' });
  }

  private goToSettings() {
    router.pushUrl({ url: 'pages/Settings' });
  }

  private goToCalendar() {
    router.pushUrl({ url: 'pages/Calendar' });
  }

  private goToWeeklyOverview() {
    router.pushUrl({ url: 'pages/WeeklyOverview' });
  }

  private async loadUser() {
    const currentUser = await AuthService.getInstance().getCurrentUser();
    const nextUser = currentUser ?? new User();
    // 防止历史异常数据导致体重放大（如 700、7100）
    if (nextUser.weight > 0) {
      nextUser.weight = this.normalizeWeightValue(nextUser.weight);
    }
    this.user = nextUser;
  }

  private async loadSelectedDateAndData() {
    const savedDate = await StorageService.getInstance().getSelectedDateValue();
    this.selectedDate = savedDate ?? new Date();
    this.selectedDate.setHours(0, 0, 0, 0);
    if (!savedDate) {
      await StorageService.getInstance().saveSelectedDateValue(this.selectedDate);
    }
    // 先加载前一天体重，以便作为缺省值使用
    await this.loadPreviousWeightForDate(this.selectedDate);
    await this.loadHealthDataForDate(this.selectedDate);
    await this.loadWeightCompareFromJson(this.selectedDate);
    this.syncWeightText();
  }

  private async loadHealthDataForDate(date: Date) {
    const remote = await HealthApiService.getInstance().fetchDailyHealthData(date, this.user?.id);
    if (remote) {
      const local = await StorageService.getInstance().getHealthData(date);
      const next = new HealthData(remote);
      // 优先使用已有值；若缺失则按顺序使用：本地 -> 前一天 -> 用户配置 -> 每月第一天默认70kg
      if ((!next.weight || next.weight <= 0) && local && local.weight > 0) {
        next.weight = local.weight;
      }
      if ((!next.weight || next.weight <= 0) && this.previousWeight > 0) {
        next.weight = this.previousWeight;
      }
      if ((!next.weight || next.weight <= 0) && this.user.weight > 0) {
        next.weight = this.user.weight;
      }
      if ((!next.weight || next.weight <= 0) && date.getDate() === 1) {
        next.weight = 70;
      }
      this.healthData = next;
      if (next.weight !== remote.weight) {
        this.persistHealthData();
      }
      return;
    }

    const initData = this.buildDefaultHealthData();
    this.healthData = initData;
    await HealthApiService.getInstance().saveDailyHealthData(date, initData, this.user?.id);
  }

  private buildDefaultHealthData(): HealthData {
    const initData = new HealthData();
    initData.steps = DefaultValues.DEFAULT_STEPS;
    initData.stepGoal = DefaultValues.DEFAULT_STEP_GOAL;
    initData.waterIntake = DefaultValues.DEFAULT_WATER;
    initData.waterGoal = DefaultValues.DEFAULT_WATER_GOAL;
    // 若有前一天体重则使用前一天；若为当月第一天则默认70kg，否则使用用户配置
    if (this.previousWeight > 0) {
      initData.weight = this.previousWeight;
    } else if (this.selectedDate && this.selectedDate.getDate && this.selectedDate.getDate() === 1) {
      initData.weight = 70;
    } else {
      initData.weight = this.user.weight > 0 ? this.user.weight : 0;
    }
    initData.sleepHours = DefaultValues.DEFAULT_SLEEP;
    initData.sleepGoal = DefaultValues.DEFAULT_SLEEP_GOAL;
    initData.heartRate = this.randomInt(65, 120);
    // 卡路里已移除
    return initData;
  }

  private syncWeightText() {
    this.weightText = this.weightToInputText(this.healthData.weight);
  }

  private normalizeWeightValue(weight: number): number {
    if (typeof weight !== 'number' || !isFinite(weight) || weight <= 0) {
      return 0;
    }
    let normalized = weight;
    while (normalized >= 300) {
      normalized = normalized / 10;
    }
    return Math.round(normalized * 10) / 10;
  }

  private weightToInputText(weight: number): string {
    const normalized = this.normalizeWeightValue(weight);
    if (normalized <= 0) {
      return '';
    }
    const intValue = Math.round(normalized);
    if (Math.abs(normalized - intValue) < 0.05) {
      return String(intValue);
    }
    return String(normalized);
  }

  private async loadPreviousWeightForDate(date: Date) {
    const previousDate = new Date(date);
    previousDate.setDate(previousDate.getDate() - 1);
    previousDate.setHours(0, 0, 0, 0);

    const remote = await HealthApiService.getInstance().fetchDailyHealthData(previousDate, this.user?.id);
    const local = await StorageService.getInstance().getHealthData(previousDate);
    let weight = 0;
    if (remote && remote.weight > 0) {
      weight = remote.weight;
    } else if (local && local.weight > 0) {
      weight = local.weight;
    }

    this.previousWeight = weight > 0 ? this.normalizeWeightValue(weight) : 0;
    this.hasPreviousWeight = this.previousWeight > 0;
  }

  private async loadWeightCompareFromJson(date: Date) {
    const previousDate = new Date(date);
    previousDate.setDate(previousDate.getDate() - 1);
    previousDate.setHours(0, 0, 0, 0);

    const weights = await Promise.all([
      HealthApiService.getInstance().fetchDailyHealthData(date, this.user?.id),
      HealthApiService.getInstance().fetchDailyHealthData(previousDate, this.user?.id)
    ]);

    const current = weights[0];
    const previous = weights[1];

    const currentWeight = current ? this.normalizeWeightValue(current.weight) : 0;
    const previousWeight = previous ? this.normalizeWeightValue(previous.weight) : 0;

    if (currentWeight <= 0 || previousWeight <= 0) {
      this.weightCompareTextFromJson = '较昨日 --';
      this.weightCompareColorFromJson = AppColors.GRAY_600;
      return;
    }

    const diff = Math.round((currentWeight - previousWeight) * 10) / 10;
    if (!isFinite(diff)) {
      this.weightCompareTextFromJson = '较昨日 --';
      this.weightCompareColorFromJson = AppColors.GRAY_600;
      return;
    }

    if (Math.abs(diff) < 0.05) {
      this.weightCompareTextFromJson = '较昨日 0kg';
      this.weightCompareColorFromJson = AppColors.GRAY_600;
      return;
    }

    const prefix = diff > 0 ? '+' : '';
    this.weightCompareTextFromJson = `较昨日 ${prefix}${diff.toFixed(1)}kg`;
    this.weightCompareColorFromJson = diff > 0 ? AppColors.ERROR : AppColors.SUCCESS;
  }

  private formatWeight(value: number): string {
    if (typeof value !== 'number' || isNaN(value) || value <= 0) {
      return '--';
    }
    return `${value.toFixed(1)}kg`;
  }

  // 精确差值（基于规范化后的当前与前一天体重），无昨日数据返回 null
  private get weightDiff(): number | null {
    const currentWeight = this.normalizeWeightValue(this.healthData.weight);
    if (currentWeight <= 0) return null;
    if (!this.hasPreviousWeight || this.previousWeight <= 0) return null;
    const baseWeight = this.normalizeWeightValue(this.previousWeight);
    const diff = Math.round((currentWeight - baseWeight) * 10) / 10;
    if (!isFinite(diff)) return null;
    return Math.abs(diff) < 0.05 ? 0 : diff;
  }

  // 用于显示的精简差值，例如 "+0.5kg" 或 "0kg"，无数据返回 "--"
  private get weightDiffText(): string {
    const diff = this.weightDiff;
    if (diff === null) return '--';
    const prefix = diff > 0 ? '+' : (diff < 0 ? '' : '');
    return `${prefix}${diff.toFixed(1)}kg`;
  }

  // 带前缀的比较文本，例如 "较昨日 +0.5kg"，无数据返回 "较昨日 --"
  private get weightCompareText(): string {
    const diff = this.weightDiff;
    if (diff === null) return '较昨日 --';
    if (Math.abs(diff) < 0.05) return '较昨日 0kg';
    const prefix = diff > 0 ? '+' : '';
    return `较昨日 ${prefix}${diff.toFixed(1)}kg`;
  }

  private get weightChangeColor(): string {
    if (!this.hasPreviousWeight || !this.healthData.weight || this.healthData.weight <= 0) {
      return AppColors.GRAY_600;
    }
    const current = this.normalizeWeightValue(this.healthData.weight);
    const prev = this.normalizeWeightValue(this.previousWeight);
    const diff = current - prev;
    if (diff > 0) {
      return AppColors.ERROR;
    }
    if (diff < 0) {
      return AppColors.SUCCESS;
    }
    return AppColors.GRAY_600;
  }

  private updateWeightFromInput(value: string) {
    this.weightText = value;
    const parsed = Number(value.trim());
    if (!isFinite(parsed) || parsed <= 0) {
      return;
    }

    const rounded = this.normalizeWeightValue(parsed);
    const next = new HealthData(this.healthData);
    next.updateWeight(rounded);
    this.healthData = next;

    // 输入框仅回显整洁文本，避免 70.0 在数字输入框被解释为 700
    this.weightText = this.weightToInputText(rounded);

    const nextUser = new User(this.user);
    nextUser.weight = rounded;
    this.user = nextUser;
    void AuthService.getInstance().updateUser(nextUser);

    void this.persistWeightAndHealthData();
  }

  private async persistWeightAndHealthData() {
    await this.persistHealthData();
  }

  private randomInt(min: number, max: number): number {
    const safeMin = Math.floor(min);
    const safeMax = Math.floor(max);
    if (safeMax <= safeMin) return safeMin;
    return Math.floor(Math.random() * (safeMax - safeMin + 1)) + safeMin;
  }

  private persistHealthData() {
    void HealthApiService.getInstance().saveDailyHealthData(this.selectedDate, this.healthData, this.user?.id);
  }

  private formatSelectedDate(): string {
    const year = this.selectedDate.getFullYear();
    const month = this.selectedDate.getMonth() + 1;
    const day = this.selectedDate.getDate();
    return `${year}年${month}月${day}日`;
  }
  

  
  /**
   * 增加步数（可为负数）
   */
  addSteps(steps: number) {
    const nextSteps = Math.max(this.healthData.steps + steps, 0);
    const newData = new HealthData(this.healthData);
    newData.steps = nextSteps;
    this.healthData = newData;
    this.persistHealthData();
  }
  
  /**
   * 增加饮水量（可为负数）
   */
  addWater(amount: number) {
    const nextWater = Math.max(this.healthData.waterIntake + amount, 0);
    const newData = new HealthData(this.healthData);
    newData.waterIntake = nextWater;
    this.healthData = newData;
    this.persistHealthData();
  }

  /**
   * 更新体重
   */
  updateWeight(weight: number) {
    const next = new HealthData(this.healthData);
    next.updateWeight(weight);
    this.healthData = next;
    this.persistHealthData();
  }
  
  /**
   * 更新睡眠时长
   */
  updateSleep(hours: number) {
    const next = new HealthData(this.healthData);
    next.updateSleep(hours);
    this.healthData = next;
    this.persistHealthData();
  }

  /**
   * 增加心率（可为负数）
   */
  addHeartRate(rate: number) {
    const next = new HealthData(this.healthData);
    const newRate = this.healthData.heartRate + rate;
    // 确保心率在合理范围内（30-200）
    if (newRate < 30) {
      next.updateHeartRate(30);
    } else if (newRate > 200) {
      next.updateHeartRate(200);
    } else {
      next.updateHeartRate(newRate);
    }
    this.healthData = next;
    this.persistHealthData();
  }

  /**
   * 增加卡路里（可为负数）
   */
  // 卡路里交互已移除
  
  /**
   * 构建用户信息卡片
   */
  @Builder
  buildUserCard() {
    HealthCard({
      title: '用户信息',
      cardBackgroundColor: AppColors.WHITE,
      iconColor: AppColors.PRIMARY
    }) {
      Row({ space: 16 }) {
        // 用户头像
        Column() {
          Text(this.user.name.substring(0, 1))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.WHITE)
            .textAlign(TextAlign.Center)
            .width(AppSizes.AVATAR_SIZE)
            .height(AppSizes.AVATAR_SIZE)
            .borderRadius(AppSizes.AVATAR_SIZE / 2)
            .backgroundColor(AppColors.PRIMARY)
        }
        
        // 用户信息
        Column({ space: 8 }) {
          Row() {
            Text(this.user.name)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.GRAY_900)
            
            Text(`${this.user.age}岁`)
              .fontSize(14)
              .fontColor(AppColors.GRAY_600)
              .margin({ left: 8 })
          }
          
          Row({ space: 12 }) {
            Column({ space: 2 }) {
              Text('身高')
                .fontSize(12)
                .fontColor(AppColors.GRAY_500)
              
              Text(`${this.user.height}cm`)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.GRAY_900)
            }
            
            Column({ space: 2 }) {
              Text('体重')
                .fontSize(12)
                .fontColor(AppColors.GRAY_500)
              
              Text(`${this.user.weight}kg`)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.GRAY_900)
            }
            
            Column({ space: 2 }) {
              Text('BMI')
                .fontSize(12)
                .fontColor(AppColors.GRAY_500)
              
              Text(`${this.user.bmi}`)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.user.bmiColor)
            }
          }
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
    }
  }
  
  /**
   * 构建步数卡片
   */
  @Builder
  buildStepsCard() {
    HealthCard({
      title: '今日步数',
      cardBackgroundColor: AppColors.WHITE,
      iconColor: AppColors.STEPS_COLOR
    }) {
      Column({ space: 16 }) {
        // 步数圆环
        MediumStepRing(this.healthData.steps, this.healthData.stepGoal)
        
        // 步数操作按钮
        Row({ space: 12 }) {
          Button('+500步')
            .width('30%')
            .height(36)
            .fontSize(12)
            .fontColor(AppColors.WHITE)
            .backgroundColor(AppColors.STEPS_COLOR)
            .borderRadius(AppSizes.BUTTON_RADIUS)
            .onClick(() => this.addSteps(500))
          
          Button('+1000步')
            .width('30%')
            .height(36)
            .fontSize(12)
            .fontColor(AppColors.WHITE)
            .backgroundColor(AppColors.STEPS_COLOR)
            .borderRadius(AppSizes.BUTTON_RADIUS)
            .onClick(() => this.addSteps(1000))
          
          Button('+2000步')
            .width('30%')
            .height(36)
            .fontSize(12)
            .fontColor(AppColors.WHITE)
            .backgroundColor(AppColors.STEPS_COLOR)
            .borderRadius(AppSizes.BUTTON_RADIUS)
            .onClick(() => this.addSteps(2000))
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
    }
  }
  
  /**
   * 构建饮水卡片
   */
  @Builder
  buildWaterCard() {
    HealthCard({
      title: '今日饮水',
      cardBackgroundColor: AppColors.WHITE,
      iconColor: AppColors.WATER_COLOR
    }) {
      Column({ space: 16 }) {
        Row() {
          Column({ space: 4 }) {
            Text(`${this.healthData.waterIntake}ml / ${this.healthData.waterGoal}ml`)
              .fontSize(14)
              .fontColor(AppColors.GRAY_600)
          }
          .layoutWeight(1)

          Text(this.waterPercentText)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.WATER_COLOR)
        }
        .width('100%')

        // 使用响应式进度条组件
        WaterProgressBar({
          currentWater: this.healthData.waterIntake,
          waterGoal: this.healthData.waterGoal
        })

        Row({ space: 12 }) {
          Button('+250ml')
            .height(36)
            .fontSize(12)
            .fontColor(AppColors.WHITE)
            .backgroundColor(AppColors.WATER_COLOR)
            .borderRadius(AppSizes.BUTTON_RADIUS)
            .onClick(() => this.addWater(250))

          Text('点击按钮记录饮水')
            .fontSize(12)
            .fontColor(AppColors.GRAY_600)
            .layoutWeight(1)
        }
        .width('100%')

        if (this.healthData.waterGoal - this.healthData.waterIntake > 0) {
          Text(`还需饮用 ${this.healthData.waterGoal - this.healthData.waterIntake}ml 完成目标`)
            .fontSize(12)
            .fontColor(AppColors.GRAY_500)
            .width('100%')
            .textAlign(TextAlign.Center)
        } else {
          Text('🎉 恭喜完成今日饮水目标！')
            .fontSize(12)
            .fontColor(AppColors.SUCCESS)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .textAlign(TextAlign.Center)
        }
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
    }
  }

  /**
   * 构建体重输入卡片
   */
  @Builder
  buildWeightCard() {
    HealthCard({
      title: '今日体重',
      cardBackgroundColor: AppColors.WHITE,
      iconColor: AppColors.PRIMARY
    }) {
      Column({ space: 14 }) {
        Row({ space: 12 }) {
          Column({ space: 4 }) {
            Text('当前体重')
              .fontSize(14)
              .fontColor(AppColors.GRAY_600)

            Text(this.formatWeight(this.healthData.weight))
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.GRAY_900)
          }
          .layoutWeight(1)

          Column({ space: 4 }) {
            Text(this.weightCompareText)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.weightChangeColor)
          }
          .alignItems(HorizontalAlign.End)
        }

        TextInput({
          placeholder: '输入体重 (kg)',
          text: this.weightText
        })
          .type(InputType.Normal)
          .width('100%')
          .height(44)
          .padding({ left: 12, right: 12 })
          .backgroundColor(AppColors.GRAY_50)
          .borderRadius(AppSizes.BUTTON_RADIUS)
          .border({ width: 1, color: AppColors.GRAY_200 })
          .onChange((value: string) => {
            this.updateWeightFromInput(value);
          })

        Text('输入后自动保存，并按前一天体重计算变化值')
          .fontSize(12)
          .fontColor(AppColors.GRAY_500)
          .width('100%')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
    }
  }
  
  /**
   * 构建睡眠卡片
   */
  @Builder
  buildSleepCard() {
    HealthCard({
      title: '睡眠时长',
      cardBackgroundColor: AppColors.WHITE,
      iconColor: AppColors.SLEEP_COLOR
    }) {
      Column({ space: 12 }) {
        // 睡眠进度 - 直接使用组件而不是@Builder函数
        ProgressCardComponent({
          title: '昨晚睡眠',
          value: this.healthData.sleepHours,
          total: this.healthData.sleepGoal,
          unit: '小时',
          color: AppColors.SLEEP_COLOR,
          icon: 'sleep'
        })
        
        // 睡眠调整按钮
        Row({ space: 12 }) {
          Button('-0.5小时')
            .width('45%')
            .height(36)
            .fontSize(12)
            .fontColor(AppColors.GRAY_700)
            .backgroundColor(AppColors.GRAY_100)
            .borderRadius(AppSizes.BUTTON_RADIUS)
            .onClick(() => {
              const newHours = Math.max(0, this.healthData.sleepHours - 0.5);
              this.updateSleep(newHours);
            })
          
          Button('+0.5小时')
            .width('45%')
            .height(36)
            .fontSize(12)
            .fontColor(AppColors.WHITE)
            .backgroundColor(AppColors.SLEEP_COLOR)
            .borderRadius(AppSizes.BUTTON_RADIUS)
            .onClick(() => {
              const newHours = Math.min(24, this.healthData.sleepHours + 0.5);
              this.updateSleep(newHours);
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
    }
  }
  
  /**
   * 构建健康概览卡片
   */
  @Builder
  buildHealthOverview() {
    HealthCard({
      title: '健康概览',
      cardBackgroundColor: AppColors.WHITE,
      iconColor: AppColors.PRIMARY
    }) {
      Grid() {
        // 心率
        GridItem() {
          Column({ space: 8 }) {
            Image('heart')
              .width(32)
              .height(32)
              .objectFit(ImageFit.Contain)
              .fillColor(AppColors.HEART_COLOR)
            
            Text(`${this.healthData.heartRate}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.GRAY_900)
            
            Text('心率')
              .fontSize(14)
              .fontColor(AppColors.GRAY_600)
            
            Row({ space: 4 }) {
              Button('-')
                .width(32)
                .height(32)
                .fontSize(14)
                .fontColor(AppColors.WHITE)
                .backgroundColor(AppColors.HEART_COLOR)
                .borderRadius(16)
                .onClick(() => {
                  this.addHeartRate(-5);
                })
              
              Button('+')
                .width(32)
                .height(32)
                .fontSize(14)
                .fontColor(AppColors.WHITE)
                .backgroundColor(AppColors.HEART_COLOR)
                .borderRadius(16)
                .onClick(() => {
                  this.addHeartRate(5);
                })
            }
            .margin({ top: 4 })
          }
          .width('100%')
          .padding(12)
          .backgroundColor(AppColors.GRAY_50)
          .borderRadius(AppSizes.CARD_RADIUS)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        
        // 体重
        GridItem() {
          Column({ space: 8 }) {
            Text(this.formatWeight(this.healthData.weight))
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.PRIMARY)
              .textAlign(TextAlign.Center)
              .width('100%')

            Text('体重')
              .fontSize(12)
              .fontColor(AppColors.GRAY_600)
              .textAlign(TextAlign.Center)
              .width('100%')

            Text(this.weightCompareTextFromJson)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.weightCompareColorFromJson)
              .textAlign(TextAlign.Center)
              .width('100%')

            Text('较昨日变化量')
              .fontSize(12)
              .fontColor(AppColors.GRAY_500)
              .textAlign(TextAlign.Center)
              .width('100%')
          }
          .width('100%')
          .padding(12)
          .backgroundColor(AppColors.GRAY_50)
          .borderRadius(AppSizes.CARD_RADIUS)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        
        // 步数
        GridItem() {
          Column({ space: 8 }) {
            Image('steps')
              .width(32)
              .height(32)
              .objectFit(ImageFit.Contain)
              .fillColor(AppColors.STEPS_COLOR)
            
            Text(`${this.healthData.steps}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.GRAY_900)
            
            Text('步数')
              .fontSize(14)
              .fontColor(AppColors.GRAY_600)
            
            Row({ space: 4 }) {
              Button('-500')
                .width(48)
                .height(32)
                .fontSize(12)
                .fontColor(AppColors.WHITE)
                .backgroundColor(AppColors.STEPS_COLOR)
                .borderRadius(16)
                .onClick(() => {
                  this.addSteps(-500);
                })
              
              Button('+500')
                .width(48)
                .height(32)
                .fontSize(12)
                .fontColor(AppColors.WHITE)
                .backgroundColor(AppColors.STEPS_COLOR)
                .borderRadius(16)
                .onClick(() => {
                  this.addSteps(500);
                })
            }
            .margin({ top: 4 })
          }
          .width('100%')
          .padding(12)
          .backgroundColor(AppColors.GRAY_50)
          .borderRadius(AppSizes.CARD_RADIUS)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        
        // 饮水
        GridItem() {
          Column({ space: 8 }) {
            Image('water')
              .width(32)
              .height(32)
              .objectFit(ImageFit.Contain)
              .fillColor(AppColors.WATER_COLOR)
            
            Text(`${this.healthData.waterIntake}ml`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.GRAY_900)
            
            Text('饮水')
              .fontSize(14)
              .fontColor(AppColors.GRAY_600)
            
            Row({ space: 4 }) {
              Button('-250')
                .width(48)
                .height(32)
                .fontSize(12)
                .fontColor(AppColors.WHITE)
                .backgroundColor(AppColors.WATER_COLOR)
                .borderRadius(16)
                .onClick(() => {
                  this.addWater(-250);
                })
              
              Button('+250')
                .width(48)
                .height(32)
                .fontSize(12)
                .fontColor(AppColors.WHITE)
                .backgroundColor(AppColors.WATER_COLOR)
                .borderRadius(16)
                .onClick(() => {
                  this.addWater(250);
                })
            }
            .margin({ top: 4 })
          }
          .width('100%')
          .padding(12)
          .backgroundColor(AppColors.GRAY_50)
          .borderRadius(AppSizes.CARD_RADIUS)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width('100%')
      .height(240)
      .padding({ top: 8, bottom: 8 })
    }
  }
  
  // 本周睡眠柱状图模块已移除
  
  build() {
    Stack() {
      // 渐变背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Gray)
        .opacity(0.1)
        .opacity(0.1)
      
      // 主内容
      Scroll() {
        Column({ space: 16 }) {
          // 欢迎标题
          Column({ space: 8 }) {
            Text('HarmonyCare')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.GRAY_900)
              .opacity(this.showWelcome ? 0 : 1)
              .animation({
                duration: 500,
                curve: Curve.EaseInOut
              })
            
            Text('您的健康管理助手')
              .fontSize(16)
              .fontColor(AppColors.GRAY_600)
              .opacity(this.showWelcome ? 0 : 1)
              .animation({
                duration: 500,
                curve: Curve.EaseInOut,
                delay: 200
              })
          }
          .width('100%')
          .padding({ top: 24, bottom: 8 })
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 24, right: 24 })

          // 数据日期选择
          Row({ space: 12 }) {
            Column({ space: 4 }) {
              Text('数据日期')
                .fontSize(12)
                .fontColor(AppColors.GRAY_600)

              Text(this.formatSelectedDate())
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.GRAY_900)
            }
            .layoutWeight(1)

            Row({ space: 8 }) {
              Button('选择日期')
                .height(36)
                .fontSize(14)
                .fontColor(AppColors.WHITE)
                .backgroundColor(AppColors.PRIMARY)
                .borderRadius(AppSizes.BUTTON_RADIUS)
                .padding({ left: 12, right: 12 })
                .onClick(() => this.goToCalendar())

              Button('一周概览')
                .height(36)
                .fontSize(14)
                .fontColor(AppColors.PRIMARY)
                .backgroundColor(AppColors.WHITE)
                .border({ width: 1, color: AppColors.GRAY_200 })
                .borderRadius(AppSizes.BUTTON_RADIUS)
                .padding({ left: 12, right: 12 })
                .onClick(() => this.goToWeeklyOverview())
            }
          }
          .width('100%')
          .padding({ left: 24, right: 24, bottom: 8 })
          .opacity(this.showWelcome ? 0 : 1)
          .animation({
            duration: 500,
            curve: Curve.EaseInOut,
            delay: 250
          })

          // 页面跳转操作
          Row({ space: 12 }) {
            Button('目标设置')
              .height(36)
              .fontSize(14)
              .fontColor(AppColors.PRIMARY)
              .backgroundColor(AppColors.WHITE)
              .border({ width: 1, color: AppColors.GRAY_200 })
              .borderRadius(AppSizes.BUTTON_RADIUS)
              .padding({ left: 12, right: 12 })
              .onClick(() => this.goToGoalSetting())

            Button('用户信息设置')
              .height(36)
              .fontSize(14)
              .fontColor(AppColors.PRIMARY)
              .backgroundColor(AppColors.WHITE)
              .border({ width: 1, color: AppColors.GRAY_200 })
              .borderRadius(AppSizes.BUTTON_RADIUS)
              .padding({ left: 12, right: 12 })
              .onClick(() => this.goToUserInfoSetting())

            Button('设置')
              .height(36)
              .fontSize(14)
              .fontColor(AppColors.GRAY_700)
              .backgroundColor(AppColors.GRAY_100)
              .borderRadius(AppSizes.BUTTON_RADIUS)
              .padding({ left: 12, right: 12 })
              .onClick(() => this.goToSettings())
          }
          .width('100%')
          .padding({ left: 24, right: 24, bottom: 8 })
          .opacity(this.showWelcome ? 0 : 1)
          .animation({
            duration: 500,
            curve: Curve.EaseInOut,
            delay: 300
          })
          
          // 用户信息卡片
          Column() {
            this.buildUserCard()
          }
          .margin({ left: 16, right: 16 })
          .opacity(this.showWelcome ? 0 : 1)
          .animation({
            duration: 500,
            curve: Curve.EaseInOut,
            delay: 400
          })
          
          // 步数卡片
          Column() {
            this.buildStepsCard()
          }
          .margin({ left: 16, right: 16 })
          .opacity(this.showWelcome ? 0 : 1)
          .animation({
            duration: 500,
            curve: Curve.EaseInOut,
            delay: 600
          })
          
          // 饮水卡片
          Column() {
            this.buildWaterCard()
          }
          .margin({ left: 16, right: 16 })
          .opacity(this.showWelcome ? 0 : 1)
          .animation({
            duration: 500,
            curve: Curve.EaseInOut,
            delay: 800
          })

          // 体重卡片
          Column() {
            this.buildWeightCard()
          }
          .margin({ left: 16, right: 16 })
          .opacity(this.showWelcome ? 0 : 1)
          .animation({
            duration: 500,
            curve: Curve.EaseInOut,
            delay: 900
          })
          
          // 睡眠卡片
          Column() {
            this.buildSleepCard()
          }
          .margin({ left: 16, right: 16 })
          .opacity(this.showWelcome ? 0 : 1)
          .animation({
            duration: 500,
            curve: Curve.EaseInOut,
            delay: 1000
          })
          
          // 健康概览
          Column() {
            this.buildHealthOverview()
          }
          .margin({ left: 16, right: 16 })
          .opacity(this.showWelcome ? 0 : 1)
          .animation({
            duration: 500,
            curve: Curve.EaseInOut,
            delay: 1200
          })
        }
        .width('100%')
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.GRAY_50)
  }
}