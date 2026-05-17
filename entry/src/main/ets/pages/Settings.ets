/**
 * 设置页面
 * 包含深色模式切换等功能
 */
import { HealthCard } from '../components/index';
import { User } from '../model/User';
import { AppColors, AppSizes } from '../utils/Constants';

@Entry
@Component
struct Settings {
  // 用户设置
  @State user: User = new User();
  
  aboutToAppear() {
    // 初始化用户数据
    this.user.name = '张三';
    this.user.darkMode = false;
    this.user.notifications = true;
    this.user.healthReminders = true;
  }
  
  // 应用版本
  @State appVersion: string = '1.0.0';
  
  // 动画状态
  @State darkModeAnimating: boolean = false;
  
  /**
   * 切换深色模式
   */
  toggleDarkMode() {
    this.darkModeAnimating = true;
    
    // 模拟切换动画
    setTimeout(() => {
      this.user.toggleDarkMode();
      this.darkModeAnimating = false;
      
      // 在实际应用中，这里会更新应用主题
      // 由于我们仅使用Previewer，这里只更新状态
    }, 300);
  }
  
  /**
   * 切换通知设置
   */
  toggleNotifications() {
    this.user.notifications = !this.user.notifications;
  }
  
  /**
   * 切换健康提醒
   */
  toggleHealthReminders() {
    this.user.healthReminders = !this.user.healthReminders;
  }
  
  /**
   * 构建用户信息卡片
   */
  @Builder
  buildUserInfoCard() {
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
        Column({ space: 4 }) {
          Text(this.user.name)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
          
          Text('健康管理用户')
            .fontSize(14)
            .fontColor(AppColors.GRAY_600)
          
          Text('ID: ' + this.user.id)
            .fontSize(12)
            .fontColor(AppColors.GRAY_500)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
    }
  }
  
  /**
   * 构建主题设置卡片
   */
  @Builder
  buildThemeCard() {
    HealthCard({
      title: '主题设置',
      cardBackgroundColor: AppColors.WHITE,
      iconColor: AppColors.PRIMARY
    }) {
      Column({ space: 12 }) {
        // 深色模式切换
        Row() {
          Column({ space: 4 }) {
            Text('深色模式')
              .fontSize(16)
              .fontColor(AppColors.GRAY_900)
            
            Text('切换应用主题颜色')
              .fontSize(12)
              .fontColor(AppColors.GRAY_600)
          }
          .layoutWeight(1)
          
          Toggle({
            type: ToggleType.Switch,
            isOn: this.user.darkMode
          })
          .width(40)
          .height(24)
          .selectedColor(AppColors.PRIMARY)
          .switchPointColor(AppColors.WHITE)
          .onChange((isOn: boolean) => {
            this.toggleDarkMode();
          })
          .opacity(this.darkModeAnimating ? 0.5 : 1)
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        
        // 主题预览
        Row({ space: 16 }) {
          // 浅色主题预览
          Column({ space: 4 }) {
            Column()
              .width(60)
              .height(40)
              .backgroundColor(AppColors.GRAY_50)
              .border({
                width: this.user.darkMode ? 1 : 2,
                color: this.user.darkMode ? AppColors.GRAY_300 : AppColors.PRIMARY
              })
              .borderRadius(8)
            
            Text('浅色')
              .fontSize(12)
              .fontColor(AppColors.GRAY_700)
          }
          .opacity(this.user.darkMode ? 0.5 : 1)
          .onClick(() => {
            if (this.user.darkMode) {
              this.toggleDarkMode();
            }
          })
          
          // 深色主题预览
          Column({ space: 4 }) {
            Column()
              .width(60)
              .height(40)
              .backgroundColor(AppColors.GRAY_800)
              .border({
                width: this.user.darkMode ? 2 : 1,
                color: this.user.darkMode ? AppColors.PRIMARY : AppColors.GRAY_600
              })
              .borderRadius(8)
            
            Text('深色')
              .fontSize(12)
              .fontColor(AppColors.GRAY_700)
          }
          .opacity(this.user.darkMode ? 1 : 0.5)
          .onClick(() => {
            if (!this.user.darkMode) {
              this.toggleDarkMode();
            }
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 8 })
      }
      .width('100%')
    }
  }
  
  /**
   * 构建通知设置卡片
   */
  @Builder
  buildNotificationCard() {
    HealthCard({
      title: '通知设置',
      cardBackgroundColor: AppColors.WHITE,
      iconColor: AppColors.PRIMARY
    }) {
      Column({ space: 12 }) {
        // 通知开关
        Row() {
          Column({ space: 4 }) {
            Text('推送通知')
              .fontSize(16)
              .fontColor(AppColors.GRAY_900)
            
            Text('接收应用通知和提醒')
              .fontSize(12)
              .fontColor(AppColors.GRAY_600)
          }
          .layoutWeight(1)
          
          Toggle({
            type: ToggleType.Switch,
            isOn: this.user.notifications
          })
          .width(40)
          .height(24)
          .selectedColor(AppColors.PRIMARY)
          .switchPointColor(AppColors.WHITE)
          .onChange((isOn: boolean) => {
            this.toggleNotifications();
          })
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        
        // 健康提醒开关
        Row() {
          Column({ space: 4 }) {
            Text('健康提醒')
              .fontSize(16)
              .fontColor(AppColors.GRAY_900)
            
            Text('定时提醒饮水和运动')
              .fontSize(12)
              .fontColor(AppColors.GRAY_600)
          }
          .layoutWeight(1)
          
          Toggle({
            type: ToggleType.Switch,
            isOn: this.user.healthReminders
          })
          .width(40)
          .height(24)
          .selectedColor(AppColors.PRIMARY)
          .switchPointColor(AppColors.WHITE)
          .onChange((isOn: boolean) => {
            this.toggleHealthReminders();
          })
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
      }
      .width('100%')
    }
  }
  
  /**
   * 构建关于卡片
   */
  @Builder
  buildAboutCard() {
    HealthCard({
      title: '关于应用',
      cardBackgroundColor: AppColors.WHITE,
      iconColor: AppColors.PRIMARY
    }) {
      Column({ space: 16 }) {
        // 应用信息
        Column({ space: 8 }) {
          Row() {
            Text('应用名称')
              .fontSize(14)
              .fontColor(AppColors.GRAY_600)
              .layoutWeight(1)
            
            Text('HarmonyCare')
              .fontSize(14)
              .fontColor(AppColors.GRAY_900)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          
          Row() {
            Text('版本')
              .fontSize(14)
              .fontColor(AppColors.GRAY_600)
              .layoutWeight(1)
            
            Text(this.appVersion)
              .fontSize(14)
              .fontColor(AppColors.GRAY_900)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          
          Row() {
            Text('开发者')
              .fontSize(14)
              .fontColor(AppColors.GRAY_600)
              .layoutWeight(1)
            
            Text('HarmonyOS 开发者')
              .fontSize(14)
              .fontColor(AppColors.GRAY_900)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        
        // 应用描述
        Text('HarmonyCare 是一个健康管理应用，帮助您追踪日常健康数据，达成健康目标。')
          .fontSize(12)
          .fontColor(AppColors.GRAY_600)
          .textAlign(TextAlign.Start)
          .width('100%')
          .padding({ top: 8 })
      }
      .width('100%')
    }
  }
  
  /**
   * 构建操作按钮
   */
  @Builder
  buildActionButtons() {
    Column({ space: 12 }) {
      // 反馈按钮
      Button('意见反馈')
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
          // 在实际应用中，这里会打开反馈页面
        })
      
      // 检查更新按钮
      Button('检查更新')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.WHITE)
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius(AppSizes.BUTTON_RADIUS)
        .onClick(() => {
          // 在实际应用中，这里会检查应用更新
        })
      
      // 退出登录按钮
      Button('退出登录')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.ERROR)
        .backgroundColor(AppColors.WHITE)
        .border({
          width: 1,
          color: AppColors.ERROR
        })
        .borderRadius(AppSizes.BUTTON_RADIUS)
        .onClick(() => {
          // 在实际应用中，这里会处理退出登录逻辑
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
          // 标题
          Column({ space: 8 }) {
            Text('设置')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.GRAY_900)
            
            Text('管理您的应用设置')
              .fontSize(14)
              .fontColor(AppColors.GRAY_600)
          }
          .width('100%')
          .padding({ top: 24, bottom: 8 })
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 24, right: 24 })
          
          // 用户信息卡片
          Column() {
            this.buildUserInfoCard()
          }
          .margin({ left: 16, right: 16 })
          
          // 主题设置卡片
          Column() {
            this.buildThemeCard()
          }
          .margin({ left: 16, right: 16 })
          
          // 通知设置卡片
          Column() {
            this.buildNotificationCard()
          }
          .margin({ left: 16, right: 16 })
          
          // 关于卡片
          Column() {
            this.buildAboutCard()
          }
          .margin({ left: 16, right: 16 })
          
          // 操作按钮
          Column() {
            this.buildActionButtons()
          }
          .margin({ left: 16, right: 16, bottom: 24 })
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