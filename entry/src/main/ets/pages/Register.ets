/**
 * 注册页面
 * 新用户注册
 */
import { AuthService } from '../utils/AuthService';
import { AppColors, AppSizes } from '../utils/Constants';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';


@Entry
@Component
struct Register {
  @State username: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State email: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';

  private authService: AuthService = AuthService.getInstance();

  // 处理注册
  private async handleRegister() {
    // 验证输入
    if (!this.username.trim()) {
      this.showError('请输入用户名');
      return;
    }
    if (!this.password.trim()) {
      this.showError('请输入密码');
      return;
    }
    if (this.password !== this.confirmPassword) {
      this.showError('两次输入的密码不一致');
      return;
    }
    if (this.password.length < 6) {
      this.showError('密码长度不能少于6位');
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      const success = await this.authService.register(this.username, this.password, this.email);
      if (success) {
        promptAction.showToast({
          message: '注册成功，请登录',
          duration: 2000
        });
        // 返回登录页面
        router.back();
      } else {
        this.showError('用户名已存在');
      }
    } catch (error) {
      this.showError('注册失败，请稍后重试');
      console.error('Register error:', error);
    } finally {
      this.isLoading = false;
    }
  }

  // 返回登录页面
  private goToLogin() {
    router.back();
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
        Text('注册账号')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.PRIMARY)

        Text('创建您的HarmonyCare账户')
          .fontSize(14)
          .fontColor(AppColors.GRAY_600)
      }
      .margin({ top: 60, bottom: 40 })
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // 注册表单
      Column({ space: 20 }) {
        // 用户名输入框
        Column({ space: 8 }) {
          Text('用户名')
            .fontSize(14)
            .fontColor(AppColors.GRAY_700)
            .alignSelf(ItemAlign.Start)

          TextInput({
            placeholder: '请输入用户名（用于登录）',
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

        // 邮箱输入框（可选）
        Column({ space: 8 }) {
          Text('邮箱（可选）')
            .fontSize(14)
            .fontColor(AppColors.GRAY_700)
            .alignSelf(ItemAlign.Start)

          TextInput({
            placeholder: '请输入邮箱地址',
            text: this.email
          })
            .width('100%')
            .height(48)
            .padding({ left: 16, right: 16 })
            .backgroundColor(AppColors.WHITE)
            .borderRadius(AppSizes.BUTTON_RADIUS)
            .border({
              width: 1,
              color: AppColors.GRAY_300
            })
            .onChange((value: string) => {
              this.email = value;
            })
        }

        // 密码输入框
        Column({ space: 8 }) {
          Text('密码')
            .fontSize(14)
            .fontColor(AppColors.GRAY_700)
            .alignSelf(ItemAlign.Start)

          TextInput({
            placeholder: '请输入密码（至少6位）',
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

        // 确认密码输入框
        Column({ space: 8 }) {
          Text('确认密码')
            .fontSize(14)
            .fontColor(AppColors.GRAY_700)
            .alignSelf(ItemAlign.Start)

          TextInput({
            placeholder: '请再次输入密码',
            text: this.confirmPassword
          })
          .type(InputType.Password)
            .width('100%')
            .height(48)
            .padding({ left: 16, right: 16 })
            .backgroundColor(AppColors.WHITE)
            .borderRadius(AppSizes.BUTTON_RADIUS)
            .border({
              width: 1,
              color: this.errorMessage && this.password !== this.confirmPassword ? AppColors.ERROR : AppColors.GRAY_300
            })
            .onChange((value: string) => {
              this.confirmPassword = value;
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

        // 注册按钮
        Button(this.isLoading ? '注册中...' : '注册', { type: ButtonType.Capsule })
          .width('100%')
          .height(48)
          .backgroundColor(AppColors.PRIMARY)
          .fontColor(AppColors.WHITE)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .enabled(!this.isLoading)
          .onClick(() => {
            this.handleRegister();
          })
          .margin({ top: 16 })

        // 返回登录链接
        Row({ space: 4 }) {
          Text('已有账号？')
            .fontSize(14)
            .fontColor(AppColors.GRAY_600)

          Text('返回登录')
            .fontSize(14)
            .fontColor(AppColors.PRIMARY)
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.goToLogin();
            })
        }
        .margin({ top: 24 })
        .justifyContent(FlexAlign.Center)
        .width('100%')
      }
      .width('80%')
      .alignItems(HorizontalAlign.Center)

      // 底部信息
      Column({ space: 8 }) {
        Text('注册即表示您同意我们的服务条款和隐私政策')
          .fontSize(12)
          .fontColor(AppColors.GRAY_400)
          .textAlign(TextAlign.Center)
          .width('80%')
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