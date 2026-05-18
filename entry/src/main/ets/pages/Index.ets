/**
 * HarmonyCare 首页
 * 展示用户信息与健康数据概览
 */
import { HealthCard, IconCard, MediumStepRing, ProgressCard, WaterProgressCard } from '../components/index';
import { HealthData } from '../model/HealthData';
import { User } from '../model/User';
import { AppColors, AppSizes, DefaultValues } from '../utils/Constants';
import { AuthService } from '../utils/AuthService';
import router from '@ohos.router';


@Entry
@Component
struct Index {
  // 用户数据
  @State user: User = new User();
  
  // 健康数据
  @State healthData: HealthData = new HealthData();
  
  async aboutToAppear() {
    // 检查登录状态
    const isLoggedIn = await AuthService.getInstance().isLoggedIn();
    if (!isLoggedIn) {
      router.replaceUrl({ url: 'pages/Login' });
      return;
    }
    
    // 初始化用户数据
    this.user = new User();
    this.user.name = '张三';
    this.user.age = 28;
    this.user.height = 175;
    this.user.weight = 70;
    this.user.dailyStepGoal = 10000;
    this.user.dailyWaterGoal = 2000;
    this.user.dailySleepGoal = 8;
    this.user.dailyCalorieGoal = 500;
    
    // 初始化健康数据
    this.healthData = new HealthData();
    this.healthData.steps = DefaultValues.DEFAULT_STEPS;
    this.healthData.stepGoal = DefaultValues.DEFAULT_STEP_GOAL;
    this.healthData.waterIntake = DefaultValues.DEFAULT_WATER;
    this.healthData.waterGoal = DefaultValues.DEFAULT_WATER_GOAL;
    this.healthData.sleepHours = DefaultValues.DEFAULT_SLEEP;
    this.healthData.sleepGoal = DefaultValues.DEFAULT_SLEEP_GOAL;
    this.healthData.heartRate = DefaultValues.DEFAULT_HEART_RATE;
    this.healthData.caloriesBurned = DefaultValues.DEFAULT_CALORIES;
    this.healthData.calorieGoal = DefaultValues.DEFAULT_CALORIE_GOAL;
    
    // 模拟加载数据
    setTimeout(() => {
      this.showWelcome = false;
    }, 1000);
  }
  
  // 页面滚动位置
  @State scrollOffset: number = 0;
  
  // 是否显示欢迎动画
  @State showWelcome: boolean = true;
  
  // 睡眠数据
  private sleepData: number[] = [6, 7, 7.5, 8, 7, 6.5, 8];
  private days: string[] = ['一', '二', '三', '四', '五', '六', '日'];
  
  // 计算最大睡眠时长
  private get maxSleep(): number {
    return Math.max(...this.sleepData);
  }

  private goToGoalSetting() {
    router.pushUrl({ url: 'pages/GoalSetting' });
  }

  private goToSettings() {
    router.pushUrl({ url: 'pages/Settings' });
  }
  

  
  /**
   * 增加步数（可为负数）
   */
  addSteps(steps: number) {
    const next = new HealthData(this.healthData);
    next.addSteps(steps);
    // 确保步数不为负数
    if (next.steps < 0) {
      next.steps = 0;
    }
    this.healthData = next;
  }
  
  /**
   * 增加饮水量（可为负数）
   */
  addWater(amount: number) {
    const next = new HealthData(this.healthData);
    next.addWater(amount);
    // 确保饮水量不为负数
    if (next.waterIntake < 0) {
      next.waterIntake = 0;
    }
    this.healthData = next;
  }
  
  /**
   * 更新睡眠时长
   */
  updateSleep(hours: number) {
    const next = new HealthData(this.healthData);
    next.updateSleep(hours);
    this.healthData = next;
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
  }

  /**
   * 增加卡路里（可为负数）
   */
  addCalories(calories: number) {
    const next = new HealthData(this.healthData);
    const newCalories = this.healthData.caloriesBurned + calories;
    // 确保卡路里不为负数
    if (newCalories < 0) {
      next.updateCalories(0);
    } else {
      next.updateCalories(newCalories);
    }
    this.healthData = next;
  }
  
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
    WaterProgressCard(
      this.healthData.waterIntake,
      this.healthData.waterGoal,
      (amount: number, newTotal: number) => {
        this.addWater(amount);
      }
    )
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
        // 睡眠进度
        ProgressCard(
          '昨晚睡眠',
          this.healthData.sleepHours,
          this.healthData.sleepGoal,
          '小时',
          AppColors.SLEEP_COLOR,
          'sleep'
        )
        
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
        
        // 卡路里
        GridItem() {
          Column({ space: 8 }) {
            Image('calories')
              .width(32)
              .height(32)
              .objectFit(ImageFit.Contain)
              .fillColor(AppColors.CALORIES_COLOR)
            
            Text(`${this.healthData.caloriesBurned}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.GRAY_900)
            
            Text('卡路里')
              .fontSize(14)
              .fontColor(AppColors.GRAY_600)
            
            Row({ space: 4 }) {
              Button('-10')
                .width(48)
                .height(32)
                .fontSize(12)
                .fontColor(AppColors.WHITE)
                .backgroundColor(AppColors.CALORIES_COLOR)
                .borderRadius(16)
                .onClick(() => {
                  this.addCalories(-10);
                })
              
              Button('+10')
                .width(48)
                .height(32)
                .fontSize(12)
                .fontColor(AppColors.WHITE)
                .backgroundColor(AppColors.CALORIES_COLOR)
                .borderRadius(16)
                .onClick(() => {
                  this.addCalories(10);
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
  
  /**
   * 构建睡眠柱状图
   */
  @Builder
  buildSleepChart() {
    
    HealthCard({
      title: '本周睡眠记录',
      cardBackgroundColor: AppColors.WHITE,
      iconColor: AppColors.SLEEP_COLOR
    }) {
      Column({ space: 16 }) {
        // 柱状图
        Row({ space: 8 }) {
          ForEach(this.sleepData, (value: number, index: number) => {
            Column({ space: 4 }) {
              // 柱子
              Column()
                .width(24)
                .height(80 * (value / this.maxSleep))
                .backgroundColor(AppColors.SLEEP_COLOR)
                .borderRadius({ topLeft: 4, topRight: 4 })
                .opacity(0.8)
              
              // 星期标签
              Text(this.days[index])
                .fontSize(12)
                .fontColor(AppColors.GRAY_600)
              
              // 数值标签
              Text(value.toFixed(1))
                .fontSize(10)
                .fontColor(AppColors.GRAY_500)
            }
            .height(120)
            .justifyContent(FlexAlign.End)
            .alignItems(HorizontalAlign.Center)
          })
        }
        .width('100%')
        .height(120)
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Bottom)
        
        // 图例
        Row({ space: 16 }) {
          Row({ space: 4 }) {
            Column()
              .width(12)
              .height(12)
              .backgroundColor(AppColors.SLEEP_COLOR)
              .borderRadius(2)
            
            Text('睡眠时长')
              .fontSize(12)
              .fontColor(AppColors.GRAY_600)
          }
          
          Row({ space: 4 }) {
            Column()
              .width(12)
              .height(12)
              .backgroundColor(AppColors.GRAY_300)
              .borderRadius(2)
            
            Text('目标: 8小时')
              .fontSize(12)
              .fontColor(AppColors.GRAY_600)
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 8 })
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
    }
  }
  
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
          
          // 睡眠柱状图
          Column() {
            this.buildSleepChart()
          }
          .margin({ left: 16, right: 16, bottom: 24 })
          .opacity(this.showWelcome ? 0 : 1)
          .animation({
            duration: 500,
            curve: Curve.EaseInOut,
            delay: 1400
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