/**
 * 状态设置页面
 * 编辑用户基础信息并同步到首页
 */
import { HealthCard } from '../components/index';
import { User } from '../model/User';
import { AppColors, AppSizes } from '../utils/Constants';
import { AuthService } from '../utils/AuthService';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';


@Entry
@Component
struct StatusSetting {
  @State user: User = new User();

  @State tempName: string = '';
  @State tempAgeText: string = '';
  @State tempHeightText: string = '';
  @State tempWeightText: string = '';

  @State isSaving: boolean = false;
  @State showSuccess: boolean = false;

  async aboutToAppear() {
    const isLoggedIn = await AuthService.getInstance().isLoggedIn();
    if (!isLoggedIn) {
      router.replaceUrl({ url: 'pages/Login' });
      return;
    }

    const currentUser = await AuthService.getInstance().getCurrentUser();
    this.user = currentUser ?? new User();

    this.tempName = this.user.name;
    this.tempAgeText = this.user.age ? String(this.user.age) : '';
    this.tempHeightText = this.user.height ? String(this.user.height) : '';
    this.tempWeightText = this.user.weight ? String(this.user.weight) : '';
  }

  private goBack() {
    router.back();
  }

  private normalizeNumber(value: string, fallback: number): number {
    const num = Number(value);
    if (Number.isNaN(num)) {
      return fallback;
    }
    return num;
  }

  private validateAndBuildUser(): User | null {
    const name = this.tempName.trim();
    if (!name) {
      promptAction.showToast({
        message: '请输入姓名',
        duration: 2000
      });
      return null;
    }

    const age = Math.max(0, Math.round(this.normalizeNumber(this.tempAgeText, this.user.age)));
    const height = Math.max(0, Math.round(this.normalizeNumber(this.tempHeightText, this.user.height)));
    const weight = Math.max(0, Math.round(this.normalizeNumber(this.tempWeightText, this.user.weight)));

    const next = new User(this.user);
    next.updateProfile(name, age, height, weight);
    return next;
  }

  private async saveStatus() {
    if (this.isSaving) {
      return;
    }

    const next = this.validateAndBuildUser();
    if (!next) {
      return;
    }

    this.isSaving = true;
    await AuthService.getInstance().updateUser(next);
    this.user = next;

    this.isSaving = false;
    this.showSuccess = true;
    promptAction.showToast({
      message: '已保存并同步到首页',
      duration: 2000
    });

    setTimeout(() => {
      this.showSuccess = false;
    }, 2000);
  }

  private resetToCurrent() {
    this.tempName = this.user.name;
    this.tempAgeText = this.user.age ? String(this.user.age) : '';
    this.tempHeightText = this.user.height ? String(this.user.height) : '';
    this.tempWeightText = this.user.weight ? String(this.user.weight) : '';
  }

  @Builder
  buildProfileCard() {
    HealthCard({
      title: '基础信息',
      cardBackgroundColor: AppColors.WHITE,
      iconColor: AppColors.PRIMARY
    }) {
      Column({ space: 12 }) {
        Column({ space: 8 }) {
          Text('姓名')
            .fontSize(14)
            .fontColor(AppColors.GRAY_700)

          TextInput({
            placeholder: '请输入姓名',
            text: this.tempName
          })
            .width('100%')
            .height(44)
            .padding({ left: 12, right: 12 })
            .backgroundColor(AppColors.GRAY_50)
            .borderRadius(AppSizes.BUTTON_RADIUS)
            .border({ width: 1, color: AppColors.GRAY_200 })
            .onChange((value: string) => {
              this.tempName = value;
            })
        }

        Column({ space: 8 }) {
          Text('年龄')
            .fontSize(14)
            .fontColor(AppColors.GRAY_700)

          TextInput({
            placeholder: '请输入年龄',
            text: this.tempAgeText
          })
            .type(InputType.Number)
            .width('100%')
            .height(44)
            .padding({ left: 12, right: 12 })
            .backgroundColor(AppColors.GRAY_50)
            .borderRadius(AppSizes.BUTTON_RADIUS)
            .border({ width: 1, color: AppColors.GRAY_200 })
            .onChange((value: string) => {
              this.tempAgeText = value;
            })
        }

        Column({ space: 8 }) {
          Text('身高 (cm)')
            .fontSize(14)
            .fontColor(AppColors.GRAY_700)

          TextInput({
            placeholder: '请输入身高',
            text: this.tempHeightText
          })
            .type(InputType.Number)
            .width('100%')
            .height(44)
            .padding({ left: 12, right: 12 })
            .backgroundColor(AppColors.GRAY_50)
            .borderRadius(AppSizes.BUTTON_RADIUS)
            .border({ width: 1, color: AppColors.GRAY_200 })
            .onChange((value: string) => {
              this.tempHeightText = value;
            })
        }

        Column({ space: 8 }) {
          Text('体重 (kg)')
            .fontSize(14)
            .fontColor(AppColors.GRAY_700)

          TextInput({
            placeholder: '请输入体重',
            text: this.tempWeightText
          })
            .type(InputType.Number)
            .width('100%')
            .height(44)
            .padding({ left: 12, right: 12 })
            .backgroundColor(AppColors.GRAY_50)
            .borderRadius(AppSizes.BUTTON_RADIUS)
            .border({ width: 1, color: AppColors.GRAY_200 })
            .onChange((value: string) => {
              this.tempWeightText = value;
            })
        }
      }
      .width('100%')
    }
  }

  build() {
    Column() {
      Row() {
        Text('状态设置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.GRAY_900)
          .layoutWeight(1)

        Text('返回')
          .fontSize(14)
          .fontColor(AppColors.PRIMARY)
          .onClick(() => this.goBack())
      }
      .width('100%')
      .padding({ top: 24, left: 24, right: 24, bottom: 8 })

      Scroll() {
        Column({ space: 16 }) {
          this.buildProfileCard()

          Row({ space: 12 }) {
            Button(this.isSaving ? '保存中...' : '保存')
              .height(40)
              .layoutWeight(1)
              .fontSize(14)
              .fontColor(AppColors.WHITE)
              .backgroundColor(AppColors.PRIMARY)
              .borderRadius(AppSizes.BUTTON_RADIUS)
              .enabled(!this.isSaving)
              .onClick(() => this.saveStatus())

            Button('重置')
              .height(40)
              .layoutWeight(1)
              .fontSize(14)
              .fontColor(AppColors.GRAY_700)
              .backgroundColor(AppColors.GRAY_100)
              .borderRadius(AppSizes.BUTTON_RADIUS)
              .onClick(() => this.resetToCurrent())
          }
          .width('100%')

          if (this.showSuccess) {
            Text('已同步到首页')
              .fontSize(12)
              .fontColor(AppColors.SUCCESS)
              .width('100%')
              .textAlign(TextAlign.Center)
          }
        }
        .padding({ left: 24, right: 24, bottom: 24 })
        .width('100%')
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.GRAY_50)
  }
}
