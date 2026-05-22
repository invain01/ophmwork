/**
 * 健康助手聊天页
 * 用户可以自由输入健康问题并获取 GPT 回复
 */
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { AppColors, AppSizes } from '../utils/Constants';
import { HealthAssistantHistoryItem, HealthAssistantService } from '../utils/HealthAssistantService';

class ChatMessage {
  id: string;
  role: string;
  content: string;
  createdAt: string;

  constructor(role: string, content: string) {
    this.id = `${Date.now()}_${Math.floor(Math.random() * 1000000)}`;
    this.role = role;
    this.content = content;
    this.createdAt = new Date().toLocaleTimeString('zh-CN', {
      hour: '2-digit',
      minute: '2-digit'
    });
  }
}

@Entry
@Component
struct HealthAssistant {
  @State inputText: string = '';
  @State isSending: boolean = false;
  @State messages: ChatMessage[] = [
    new ChatMessage(
      'assistant',
      '你好，我是健康助手。你可以问我饮食、运动、睡眠、体重、步数和日常健康管理相关的问题。'
    )
  ];

  private readonly assistantService: HealthAssistantService = HealthAssistantService.getInstance();

  private goBack() {
    router.back();
  }

  private buildHistory(): HealthAssistantHistoryItem[] {
    const startIndex = this.messages.length > 12 ? this.messages.length - 12 : 0;
    const recentMessages = this.messages.slice(startIndex);
    const history: HealthAssistantHistoryItem[] = [];
    for (const message of recentMessages) {
      history.push({
        role: message.role,
        content: message.content
      });
    }
    return history;
  }

  private async sendMessage() {
    const userText = this.inputText.trim();
    if (!userText || this.isSending) {
      return;
    }

    const history = this.buildHistory();
    this.inputText = '';
    this.isSending = true;
    this.messages = [...this.messages, new ChatMessage('user', userText)];

    try {
      const reply = await this.assistantService.sendMessage(userText, history);
      this.messages = [...this.messages, new ChatMessage('assistant', reply)];
    } catch (error) {
      console.error('Health assistant send error:', error);
      const fallback = '当前健康助手暂时不可用，请稍后重试。';
      this.messages = [...this.messages, new ChatMessage('assistant', fallback)];
      promptAction.showToast({
        message: fallback,
        duration: 2000
      });
    } finally {
      this.isSending = false;
    }
  }

  private getBubbleBackground(role: string): string {
    return role === 'user' ? '#DDF3FF' : '#FFFFFF';
  }

  private getBubbleBorderColor(role: string): string {
    return role === 'user' ? '#B7DBF7' : AppColors.GRAY_200;
  }

  private getBubbleTextColor(role: string): string {
    return role === 'user' ? AppColors.GRAY_900 : AppColors.GRAY_900;
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#F4FAFC')

      Column({ space: 0 }) {
        Row({ space: 12 }) {
          Button('返回')
            .height(36)
            .fontSize(14)
            .fontColor(AppColors.WHITE)
            .backgroundColor(AppColors.PRIMARY_DARK)
            .borderRadius(18)
            .padding({ left: 12, right: 12 })
            .onClick(() => this.goBack())

          Column({ space: 2 }) {
            Text('健康助手')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.GRAY_900)
          }
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 20, bottom: 12 })

        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.messages, (message: ChatMessage) => {
              Row() {
                if (message.role === 'user') {
                  Column().layoutWeight(1)
                  Column({ space: 4 }) {
                    Text('我')
                      .fontSize(12)
                      .fontColor(AppColors.GRAY_600)
                    Text(message.content)
                      .fontSize(15)
                      .fontColor(this.getBubbleTextColor(message.role))
                      .lineHeight(22)
                      .textAlign(TextAlign.Start)
                    Text(message.createdAt)
                      .fontSize(11)
                      .fontColor(AppColors.GRAY_500)
                  }
                  .padding(14)
                  .backgroundColor(this.getBubbleBackground(message.role))
                  .border({ width: 1, color: this.getBubbleBorderColor(message.role) })
                  .borderRadius(18)
                  .width('78%')
                } else {
                  Column({ space: 4 }) {
                    Text('健康助手')
                      .fontSize(12)
                      .fontColor(AppColors.PRIMARY_DARK)
                    Text(message.content)
                      .fontSize(15)
                      .fontColor(this.getBubbleTextColor(message.role))
                      .lineHeight(22)
                      .textAlign(TextAlign.Start)
                    Text(message.createdAt)
                      .fontSize(11)
                      .fontColor(AppColors.GRAY_500)
                  }
                  .padding(14)
                  .backgroundColor(this.getBubbleBackground(message.role))
                  .border({ width: 1, color: this.getBubbleBorderColor(message.role) })
                  .borderRadius(18)
                  .shadow({
                    radius: 8,
                    color: AppColors.BLACK_10,
                    offsetX: 0,
                    offsetY: 1
                  })
                  .width('78%')
                  Column().layoutWeight(1)
                }
              }
              .width('100%')
            }, (message: ChatMessage) => message.id)

            if (this.isSending) {
              Row() {
                Column({ space: 4 }) {
                  Text('健康助手正在思考...')
                    .fontSize(13)
                    .fontColor(AppColors.GRAY_600)
                }
                .padding({ left: 6, right: 6 })
                Column().layoutWeight(1)
              }
              .width('100%')
            }
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 4, bottom: 16 })
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)

        Column({ space: 12 }) {
          TextArea({ placeholder: '输入你的健康问题', text: this.inputText })
            .width('100%')
            .height(96)
            .padding(14)
            .fontSize(15)
            .backgroundColor(AppColors.WHITE)
            .borderRadius(AppSizes.CARD_RADIUS)
            .border({ width: 1, color: AppColors.GRAY_300 })
            .onChange((value: string) => {
              this.inputText = value;
            })

          Row({ space: 12 }) {
            Text(this.isSending ? '发送中...' : '准备发送')
              .fontSize(12)
              .fontColor(AppColors.GRAY_600)
              .layoutWeight(1)

            Button('发送')
              .height(44)
              .fontSize(15)
              .fontColor(AppColors.WHITE)
              .backgroundColor(this.isSending ? AppColors.GRAY_400 : AppColors.PRIMARY_DARK)
              .borderRadius(22)
              .padding({ left: 18, right: 18 })
              .enabled(!this.isSending)
              .onClick(() => this.sendMessage())
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 20 })
        .backgroundColor('#F4FAFC')
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}