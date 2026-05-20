/**
 * 健康目标设置页面
 */
import { HealthCard } from '../components/index';
import { User } from '../model/User';
import { AppColors, AppSizes, DefaultValues } from '../utils/Constants';
import { AuthService } from '../utils/AuthService';
import router from '@ohos.router';


@Entry
@Component
struct GoalSetting {
  // 用户数据
  @State user: User = new User();
  
  async aboutToAppear() {
    // 检查登录状态
    const isLoggedIn = await AuthService.getInstance().isLoggedIn();
    if (!isLoggedIn) {
      router.replaceUrl({ url: 'pages/Login' });
      return;
    }
    // 初始化用户数据
    const initialUser = new User();
    initialUser.name = '张三';
    initialUser.dailyStepGoal = DefaultValues.DEFAULT_STEP_GOAL;
    initialUser.dailyWaterGoal = DefaultValues.DEFAULT_WATER_GOAL;
    initialUser.dailySleepGoal = DefaultValues.DEFAULT_SLEEP_GOAL;
    this.user = initialUser;
    
    // 初始化临时值
    this.tempStepGoal = this.user.dailyStepGoal;
    this.tempWaterGoal = this.user.dailyWaterGoal;
    this.tempSleepGoal = this.user.dailySleepGoal;
  }
  
  // 临时目标值
  @State tempStepGoal: number = DefaultValues.DEFAULT_STEP_GOAL;
  @State tempWaterGoal: number = DefaultValues.DEFAULT_WATER_GOAL;
  @State tempSleepGoal: number = DefaultValues.DEFAULT_SLEEP_GOAL;
  
  
  // 保存状态
  @State isSaving: boolean = false;
  @State showSuccess: boolean = false;

  private goBack() {
    router.back();
  }
  

  
  /**
   * 保存目标设置
   */
  saveGoals() {
    this.isSaving = true;
    
    // 模拟保存操作
    setTimeout(() => {
      const next = new User(this.user);
      next.updateGoals(
        this.tempStepGoal,
        this.tempWaterGoal,
        this.tempSleepGoal
      );
      this.user = next;
      
      this.isSaving = false;
      this.showSuccess = true;
      
      // 3秒后隐藏成功提示
      setTimeout(() => {
        this.showSuccess = false;
      }, 3000);
    }, 500);
  }
  
  /**
   * 重置为目标值
   */
  resetToDefaults() {
    this.tempStepGoal = DefaultValues.DEFAULT_STEP_GOAL;
    this.tempWaterGoal = DefaultValues.DEFAULT_WATER_GOAL;
    this.tempSleepGoal = DefaultValues.DEFAULT_SLEEP_GOAL;
  }
  
  /**
   * 构建步数目标设置
   */
  @Builder
  buildStepGoalSetting() {
    HealthCard({
      title: '每日步数目标',
      cardBackgroundColor: AppColors.WHITE,
      iconColor: AppColors.STEPS_COLOR
    }) {
      Column({ space: 16 }) {
        // 当前值显示
        Row() {
          Text('当前目标: ')
            .fontSize(14)
            .fontColor(AppColors.GRAY_600)
          
          Text(`${this.user.dailyStepGoal.toLocaleString()} 步`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.STEPS_COLOR)
        }
        .width('100%')
        
        // 滑块设置
        Column({ space: 8 }) {
          Row() {
            Text('0')
              .fontSize(12)
              .fontColor(AppColors.GRAY_500)
            
            Text('25,000')
              .fontSize(12)
              .fontColor(AppColors.GRAY_500)
              .layoutWeight(1)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          
          Slider({
            value: this.tempStepGoal,
            min: 1000,
            max: 25000,
            step: 500,
            style: SliderStyle.OutSet
          })
          .width('100%')
          .blockColor(AppColors.STEPS_COLOR)
          .trackColor(AppColors.GRAY_300)
          .selectedColor(AppColors.STEPS_COLOR)
          .showSteps(true)
          .onChange((value: number) => {
            this.tempStepGoal = Math.round(value / 500) * 500;
          })
          
          // 当前选择的值
          Row() {
            Text('设置: ')
              .fontSize(14)
              .fontColor(AppColors.GRAY_600)
            
            Text(`${this.tempStepGoal.toLocaleString()} 步`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.STEPS_COLOR)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 8 })
        }
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })
    }
  }
  
  /**
   * 构建饮水目标设置
   */
  @Builder
  buildWaterGoalSetting() {
    HealthCard({
      title: '每日饮水目标',
      cardBackgroundColor: AppColors.WHITE,
      iconColor: AppColors.WATER_COLOR
    }) {
      Column({ space: 16 }) {
        // 当前值显示
        Row() {
          Text('当前目标: ')
            .fontSize(14)
            .fontColor(AppColors.GRAY_600)
          
          Text(`${this.user.dailyWaterGoal} ml`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.WATER_COLOR)
        }
        .width('100%')
        
        // 滑块设置
        Column({ space: 8 }) {
          Row() {
            Text('500ml')
              .fontSize(12)
              .fontColor(AppColors.GRAY_500)
            
            Text('4000ml')
              .fontSize(12)
              .fontColor(AppColors.GRAY_500)
              .layoutWeight(1)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          
          Slider({
            value: this.tempWaterGoal,
            min: 500,
            max: 4000,
            step: 250,
            style: SliderStyle.OutSet
          })
          .width('100%')
          .blockColor(AppColors.WATER_COLOR)
          .trackColor(AppColors.GRAY_300)
          .selectedColor(AppColors.WATER_COLOR)
          .showSteps(true)
          .onChange((value: number) => {
            this.tempWaterGoal = Math.round(value / 250) * 250;
          })
          
          // 当前选择的值
          Row() {
            Text('设置: ')
              .fontSize(14)
              .fontColor(AppColors.GRAY_600)
            
            Text(`${this.tempWaterGoal} ml`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.WATER_COLOR)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 8 })
        }
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })
    }
  }
  
  /**
   * 构建睡眠目标设置
   */
  @Builder
  buildSleepGoalSetting() {
    HealthCard({
      title: '每日睡眠目标',
      cardBackgroundColor: AppColors.WHITE,
      iconColor: AppColors.SLEEP_COLOR
    }) {
      Column({ space: 16 }) {
        // 当前值显示
        Row() {
          Text('当前目标: ')
            .fontSize(14)
            .fontColor(AppColors.GRAY_600)
          
          Text(`${this.user.dailySleepGoal} 小时`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.SLEEP_COLOR)
        }
        .width('100%')
        
        // 滑块设置
        Column({ space: 8 }) {
          Row() {
            Text('4小时')
              .fontSize(12)
              .fontColor(AppColors.GRAY_500)
            
            Text('12小时')
              .fontSize(12)
              .fontColor(AppColors.GRAY_500)
              .layoutWeight(1)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          
          Slider({
            value: this.tempSleepGoal,
            min: 4,
            max: 12,
            step: 0.5,
            style: SliderStyle.OutSet
          })
          .width('100%')
          .blockColor(AppColors.SLEEP_COLOR)
          .trackColor(AppColors.GRAY_300)
          .selectedColor(AppColors.SLEEP_COLOR)
          .showSteps(true)
          .onChange((value: number) => {
            this.tempSleepGoal = Math.round(value * 2) / 2;
          })
          
          // 当前选择的值
          Row() {
            Text('设置: ')
              .fontSize(14)
              .fontColor(AppColors.GRAY_600)
            
            Text(`${this.tempSleepGoal.toFixed(1)} 小时`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.SLEEP_COLOR)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 8 })
        }
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })
    }
  }
  
  /**
   * 构建卡路里目标设置
   */
  
  
  /**
   * 构建操作按钮
   */
  @Builder
  buildActionButtons() {
    Column({ space: 12 }) {
      // 保存按钮
      Button(this.isSaving ? '保存中...' : '保存设置')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.WHITE)
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius(AppSizes.BUTTON_RADIUS)
        .opacity(this.isSaving ? 0.7 : 1)
        .onClick(() => {
          if (!this.isSaving) {
            this.saveGoals();
          }
        })
      
      // 重置按钮
      Button('恢复默认')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.PRIMARY)
        .backgroundColor(AppColors.WHITE)
        .border({
          width: 1,
          color: AppColors.PRIMARY
        })
        .borderRadius(AppSizes.BUTTON_RADIUS)
        .onClick(() => {
          this.resetToDefaults();
        })
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }
  
  build() {
    Stack() {
      // 背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Gray)
        .opacity(0.1)
      
      // 主内容
      Scroll() {
        Column({ space: 16 }) {
          // 返回
          Row() {
            Button('返回')
              .height(32)
              .fontSize(14)
              .fontColor(AppColors.GRAY_700)
              .backgroundColor(AppColors.WHITE)
              .border({ width: 1, color: AppColors.GRAY_200 })
              .borderRadius(AppSizes.BUTTON_RADIUS)
              .padding({ left: 12, right: 12 })
              .onClick(() => this.goBack())
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 16 })

          // 标题
          Column({ space: 8 }) {
            Text('健康目标设置')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.GRAY_900)
            
            Text('设置您的每日健康目标')
              .fontSize(14)
              .fontColor(AppColors.GRAY_600)
          }
          .width('100%')
          .padding({ top: 24, bottom: 8 })
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 24, right: 24 })
          
          // 成功提示
          if (this.showSuccess) {
            Column() {
              HealthCard({
                cardBackgroundColor: AppColors.SUCCESS,
                cardTextColor: AppColors.WHITE,
                showShadow: false
              }) {
                Row({ space: 8 }) {
                  Image('success')
                    .width(20)
                    .height(20)
                    .fillColor(AppColors.WHITE)
                  
                  Text('目标设置已保存！')
                    .fontSize(14)
                    .fontColor(AppColors.WHITE)
                    .fontWeight(FontWeight.Medium)
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
              }
            }
            .margin({ left: 16, right: 16 })
          }
          
          // 步数目标设置
          Column() {
            this.buildStepGoalSetting()
          }
          .margin({ left: 16, right: 16 })
          
          // 饮水目标设置
          Column() {
            this.buildWaterGoalSetting()
          }
          .margin({ left: 16, right: 16 })
          
          // 睡眠目标设置
          Column() {
            this.buildSleepGoalSetting()
          }
          .margin({ left: 16, right: 16 })
          
          
          
          
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