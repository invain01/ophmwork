/**
 * 登录页面
 * 用户登录和跳转到注册页面
 */
import { AuthService } from '../utils/AuthService';
import { AppColors, AppSizes } from '../utils/Constants';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';


@Entry
@Component
struct Login {
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';

  private authService: AuthService = AuthService.getInstance();

  // 处理登录
  private async handleLogin() {
    if (!this.username.trim()) {
      this.showError('请输入用户名');
      return;
    }
    if (!this.password.trim()) {
      this.showError('请输入密码');
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      const user = await this.authService.login(this.username, this.password);
      if (user) {
        promptAction.showToast({
          message: '登录成功',
          duration: 2000
        });
        // 跳转到首页
        router.replaceUrl({
          url: 'pages/Index'
        });
      } else {
        this.showError('用户名或密码错误');
      }
    } catch (error) {
      this.showError('登录失败，请稍后重试');
      console.error('Login error:', error);
    } finally {
      this.isLoading = false;
    }
  }

  // 跳转到注册页面
  private goToRegister() {
    router.pushUrl({
      url: 'pages/Register'
    });
  }

  // 跳转到管理端页面
  private goToAdminDashboard() {
    router.pushUrl({
      url: 'pages/AdminDashboard'
    });
  }

  // 显示错误信息
  private showError(message: string) {
    this.errorMessage = message;
    promptAction.showToast({
      message: message,
      duration: 3000
    });
  }

  // 清除错误信息
  private clearError() {
    this.errorMessage = '';
  }

  async aboutToAppear() {
    // 检查是否已登录，如果已登录则跳转到首页
    const isLoggedIn = await this.authService.isLoggedIn();
    if (isLoggedIn) {
      router.replaceUrl({ url: 'pages/Index' });
    }
  }

  build() {
    Column() {
      // 顶部标题
      Column({ space: 8 }) {
        Text('HarmonyCare')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.PRIMARY)

        Text('健康管理平台')
          .fontSize(16)
          .fontColor(AppColors.GRAY_600)
      }
      .margin({ top: 80, bottom: 40 })
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // 登录表单
      Column({ space: 24 }) {
        // 用户名输入框
        Column({ space: 8 }) {
          Text('用户名')
            .fontSize(14)
            .fontColor(AppColors.GRAY_700)
            .alignSelf(ItemAlign.Start)

          TextInput({
            placeholder: '请输入用户名',
            text: this.username
          })
            .width('100%')
            .height(48)
            .padding({ left: 16, right: 16 })
            .backgroundColor(AppColors.WHITE)
            .borderRadius(AppSizes.BUTTON_RADIUS)
            .border({
              width: 1,
              color: this.errorMessage && !this.username.trim() ? AppColors.ERROR : AppColors.GRAY_300
            })
            .onChange((value: string) => {
              this.username = value;
              this.clearError();
            })
        }

        // 密码输入框
        Column({ space: 8 }) {
          Text('密码')
            .fontSize(14)
            .fontColor(AppColors.GRAY_700)
            .alignSelf(ItemAlign.Start)

          TextInput({
            placeholder: '请输入密码',
            text: this.password
          })
          .type(InputType.Password)
            .width('100%')
            .height(48)
            .padding({ left: 16, right: 16 })
            .backgroundColor(AppColors.WHITE)
            .borderRadius(AppSizes.BUTTON_RADIUS)
            .border({
              width: 1,
              color: this.errorMessage && !this.password.trim() ? AppColors.ERROR : AppColors.GRAY_300
            })
            .onChange((value: string) => {
              this.password = value;
              this.clearError();
            })
        }

        // 错误信息显示
        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontSize(12)
            .fontColor(AppColors.ERROR)
            .width('100%')
            .textAlign(TextAlign.Start)
            .margin({ top: 8 })
        }

        // 登录按钮
        Button(this.isLoading ? '登录中...' : '登录', { type: ButtonType.Capsule })
          .width('100%')
          .height(48)
          .backgroundColor(AppColors.PRIMARY)
          .fontColor(AppColors.WHITE)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .enabled(!this.isLoading)
          .onClick(() => {
            this.handleLogin();
          })
          .margin({ top: 16 })

        // 注册链接
        Row({ space: 4 }) {
          Text('还没有账号？')
            .fontSize(14)
            .fontColor(AppColors.GRAY_600)

          Text('立即注册')
            .fontSize(14)
            .fontColor(AppColors.PRIMARY)
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.goToRegister();
            })
        }
        .margin({ top: 24 })
        .justifyContent(FlexAlign.Center)
        .width('100%')

        Button('进入管理端')
          .width('100%')
          .height(44)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.PRIMARY)
          .backgroundColor(AppColors.WHITE)
          .border({
            width: 1,
            color: AppColors.PRIMARY
          })
          .borderRadius(AppSizes.BUTTON_RADIUS)
          .margin({ top: 12 })
          .onClick(() => {
            this.goToAdminDashboard();
          })
      }
      .width('80%')
      .alignItems(HorizontalAlign.Center)

      // 底部信息
      Column({ space: 8 }) {
        Text('HarmonyCare v1.0')
          .fontSize(12)
          .fontColor(AppColors.GRAY_400)

        Text('健康生活，从每一天开始')
          .fontSize(12)
          .fontColor(AppColors.GRAY_400)
      }
      .margin({ top: 60, bottom: 40 })
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.GRAY_50)
    .padding(24)
    .justifyContent(FlexAlign.SpaceBetween)
  }
}