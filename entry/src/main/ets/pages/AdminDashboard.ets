/**
 * 管理端后台页面
 * 展示用户统计信息和用户反馈记录
 */
import { HealthCard } from '../components/index';
import { FeedbackRecord } from '../model/FeedbackRecord';
import { User } from '../model/User';
import { AppColors, AppSizes } from '../utils/Constants';
import { AuthService } from '../utils/AuthService';
import router from '@ohos.router';


@Entry
@Component
struct AdminDashboard {
  @State users: User[] = [];
  @State feedbacks: FeedbackRecord[] = [];
  @State totalUsers: number = 0;
  @State totalLoginCount: number = 0;
  @State totalFeedbackCount: number = 0;
  @State isLoading: boolean = false;

  async aboutToAppear() {
    await this.loadDashboard();
  }

  private recalculateDashboardMetrics(users: User[], feedbacks: FeedbackRecord[]): void {
    let loginCount = 0;
    for (let i = 0; i < users.length; i += 1) {
      const current = users[i];
      loginCount += typeof current.loginCount === 'number' ? current.loginCount : 0;
    }

    this.totalUsers = users.length;
    this.totalLoginCount = loginCount;
    this.totalFeedbackCount = feedbacks.length;
  }

  private async loadDashboard() {
    this.isLoading = true;
    try {
      const authService = AuthService.getInstance();
      const users = await authService.getAllUsers();
      const feedbacks = await authService.getFeedbackList();

      this.users = users;
      this.feedbacks = feedbacks;
      this.recalculateDashboardMetrics(users, feedbacks);
    } catch (error) {
      console.error('加载后台数据失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  private getTotalUsersValue(): number {
    return this.totalUsers;
  }

  private getTotalLoginCountValue(): number {
    let loginCount = 0;
    for (let i = 0; i < this.users.length; i += 1) {
      const current = this.users[i];
      loginCount += typeof current.loginCount === 'number' ? current.loginCount : 0;
    }
    return loginCount;
  }

  private getTotalFeedbackCountValue(): number {
    return this.totalFeedbackCount;
  }

  private goBack() {
    router.back();
  }

  @Builder
  buildMetricCard(title: string, value: string, tip: string, accentColor: ResourceColor) {
    Column({ space: 6 }) {
      Text(title)
        .fontSize(13)
        .fontColor(AppColors.GRAY_600)

      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.GRAY_900)

      Text(tip)
        .fontSize(12)
        .fontColor(accentColor)
    }
    .layoutWeight(1)
    .padding(16)
    .backgroundColor(AppColors.WHITE)
    .borderRadius(AppSizes.CARD_RADIUS)
    .shadow({
      radius: 8,
      color: AppColors.BLACK_10,
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  buildUserRow(user: User) {
    Row({ space: 12 }) {
      Column() {
        Text(user.name ? user.name.substring(0, 1) : user.username.substring(0, 1))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.WHITE)
          .textAlign(TextAlign.Center)
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor(AppColors.PRIMARY)
      }

      Column({ space: 4 }) {
        Text(user.name || user.username)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.GRAY_900)

        Text('用户名：' + user.username)
          .fontSize(12)
          .fontColor(AppColors.GRAY_600)

        Text('登录次数：' + (typeof user.loginCount === 'number' ? user.loginCount : 0))
          .fontSize(12)
          .fontColor(AppColors.GRAY_600)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  @Builder
  buildFeedbackItem(feedback: FeedbackRecord) {
    Column({ space: 8 }) {
      Row() {
        Text(feedback.username)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.GRAY_900)
          .layoutWeight(1)

        Text(feedback.createdAt)
          .fontSize(11)
          .fontColor(AppColors.GRAY_500)
      }
      .width('100%')

      Text(feedback.content)
        .fontSize(14)
        .fontColor(AppColors.GRAY_700)
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(AppColors.WHITE)
    .borderRadius(AppSizes.CARD_RADIUS)
    .shadow({
      radius: 8,
      color: AppColors.BLACK_10,
      offsetX: 0,
      offsetY: 2
    })
    .margin({ bottom: 12 })
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.GRAY_50)

      if (this.isLoading) {
        Column({ space: 12 }) {
          Text('后台数据加载中...')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.GRAY_700)

          Text('正在读取用户列表、登录次数和反馈信息')
            .fontSize(14)
            .fontColor(AppColors.GRAY_500)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            Row() {
              Button('返回')
                .height(34)
                .fontSize(14)
                .fontColor(AppColors.GRAY_700)
                .backgroundColor(AppColors.WHITE)
                .border({ width: 1, color: AppColors.GRAY_200 })
                .borderRadius(AppSizes.BUTTON_RADIUS)
                .padding({ left: 12, right: 12 })
                .onClick(() => this.goBack())

              Button('刷新数据')
                .height(34)
                .fontSize(14)
                .fontColor(AppColors.WHITE)
                .backgroundColor(AppColors.PRIMARY)
                .borderRadius(AppSizes.BUTTON_RADIUS)
                .padding({ left: 12, right: 12 })
                .onClick(() => this.loadDashboard())
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16 })
            .justifyContent(FlexAlign.SpaceBetween)

            Column({ space: 8 }) {
              Text('后台管理')
                .fontSize(26)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.GRAY_900)

              Text('查看系统用户、登录统计和反馈信息')
                .fontSize(14)
                .fontColor(AppColors.GRAY_600)
            }
            .width('100%')
            .padding({ left: 20, right: 20 })
            .alignItems(HorizontalAlign.Start)

            Row({ space: 12 }) {
              this.buildMetricCard('用户总数', this.getTotalUsersValue().toString(), '已注册账号数量', AppColors.PRIMARY)
              this.buildMetricCard('登录次数', this.getTotalLoginCountValue().toString(), '成功登录总计', AppColors.SUCCESS)
              this.buildMetricCard('反馈数', this.getTotalFeedbackCountValue().toString(), '用户提交意见', AppColors.WARNING)
            }
            .width('100%')
            .padding({ left: 16, right: 16 })

            Column() {
              HealthCard({
                title: '用户数据',
                cardBackgroundColor: AppColors.WHITE,
                iconColor: AppColors.PRIMARY
              }) {
                Column({ space: 4 }) {
                  if (this.users.length === 0) {
                    Text('暂无用户数据')
                      .fontSize(14)
                      .fontColor(AppColors.GRAY_600)
                      .padding({ top: 12, bottom: 12 })
                  } else {
                    ForEach(this.users, (item: User) => {
                      this.buildUserRow(item)
                    }, (item: User) => item.id)
                  }
                }
              }
            }
            .margin({ left: 16, right: 16 })

            Column() {
              HealthCard({
                title: '用户反馈',
                cardBackgroundColor: AppColors.WHITE,
                iconColor: AppColors.PRIMARY
              }) {
                Column({ space: 4 }) {
                  if (this.feedbacks.length === 0) {
                    Text('暂无反馈信息')
                      .fontSize(14)
                      .fontColor(AppColors.GRAY_600)
                      .padding({ top: 12, bottom: 12 })
                  } else {
                    ForEach(this.feedbacks, (item: FeedbackRecord) => {
                      this.buildFeedbackItem(item)
                    }, (item: FeedbackRecord) => item.id)
                  }
                }
              }
            }
            .margin({ left: 16, right: 16, bottom: 24 })
          }
          .width('100%')
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
  }
}