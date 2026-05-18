/**
 * 健康卡片组件
 * 用于展示健康数据的卡片式组件
 */
import { AppColors, AppSizes } from '../utils/Constants';

@Component
export struct HealthCard {
  // 卡片标题
  @Prop title: string = '';
  
  // 卡片内容
  @Prop content: string = '';
  
  // 图标
  @Prop icon: string = '';
  
  // 图标颜色
  @Prop iconColor: ResourceColor = AppColors.PRIMARY;
  
  // 背景颜色
  @Prop cardBackgroundColor: ResourceColor = AppColors.WHITE;
  
  // 文本颜色
  @Prop cardTextColor: ResourceColor = AppColors.GRAY_900;
  
  // 是否显示阴影
  @Prop showShadow: boolean = true;
  
  // 是否启用点击动画
  @Prop enableClickAnimation: boolean = true;
  
  // 点击状态
  @State isPressed: boolean = false;
  
  // 自定义内容插槽
  @BuilderParam contentBuilder?: () => void;
  
  build() {
    Column() {
      // 标题区域
      if (this.title) {
        Row({ space: 8 }) {
          // 图标
          if (this.icon) {
            Image(this.icon)
              .width(AppSizes.ICON_SIZE)
              .height(AppSizes.ICON_SIZE)
              .objectFit(ImageFit.Contain)
              .fillColor(this.iconColor)
          }
          
          // 标题文本
          Text(this.title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.cardTextColor)
            .textAlign(TextAlign.Start)
            .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 12 })
      }
      
      // 内容区域
      if (this.contentBuilder) {
        // 使用自定义内容
        this.contentBuilder()
      } else if (this.content) {
        // 使用文本内容
        Text(this.content)
          .fontSize(16)
          .fontColor(this.cardTextColor)
          .textAlign(TextAlign.Start)
          .width('100%')
      }
    }
    .width('100%')
    .padding(AppSizes.CARD_PADDING)
    .backgroundColor(this.cardBackgroundColor)
    .borderRadius(AppSizes.CARD_RADIUS)
    .shadow(this.showShadow ? {
      radius: 8,
      color: AppColors.BLACK_10,
      offsetX: 0,
      offsetY: 2
    } : undefined)
    .opacity(this.isPressed && this.enableClickAnimation ? 0.8 : 1)
    .scale(this.isPressed && this.enableClickAnimation ? { x: 0.98, y: 0.98 } : { x: 1, y: 1 })
  }
  
  /**
   * 创建带有进度条的健康卡片
   */
  @Builder static ProgressCard(
    title: string,
    value: number,
    total: number,
    unit: string,
    color: string,
    icon: string
  ) {
    Column({ space: 8 }) {
      // 标题和数值
      Row() {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.GRAY_700)
          .layoutWeight(1)
        
        Text(`${value} / ${total} ${unit}`)
          .fontSize(14)
          .fontColor(AppColors.GRAY_600)
      }
      .width('100%')
      
      // 进度条
      Stack() {
        // 背景条
        Row()
          .width('100%')
          .height(8)
          .backgroundColor(AppColors.GRAY_200)
          .borderRadius(4)
        
        // 进度条
        Row()
          .width(`${Math.min(Math.round((value / total) * 100), 100)}%`)
          .height(8)
          .backgroundColor(color)
          .borderRadius(4)
      }
      .width('100%')
      .height(8)
      
      // 百分比
      Row() {
        Text(`${Math.min(Math.round((value / total) * 100), 100)}%`)
          .fontSize(12)
          .fontColor(AppColors.GRAY_600)
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
  }
  
  /**
   * 创建带有图标的健康卡片
   */
  @Builder static IconCard(
    title: string,
    value: string,
    icon: string,
    iconColor: ResourceColor = AppColors.PRIMARY,
    cardBackgroundColor: ResourceColor = AppColors.WHITE
  ) {
    Column({ space: 12 }) {
      // 图标
      Image(icon)
        .width(32)
        .height(32)
        .objectFit(ImageFit.Contain)
        .fillColor(iconColor)
      
      // 数值
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.GRAY_900)
      
      // 标题
      Text(title)
        .fontSize(14)
        .fontColor(AppColors.GRAY_600)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(cardBackgroundColor)
    .borderRadius(AppSizes.CARD_RADIUS)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}

/**
 * 进度卡片组件 - 支持响应式更新
 */
@Component
export struct ProgressCardComponent {
  @Prop @Watch('onDataChange') title: string = '';
  @Prop @Watch('onDataChange') value: number = 0;
  @Prop @Watch('onDataChange') total: number = 100;
  @Prop unit: string = '';
  @Prop color: string = AppColors.PRIMARY;
  @Prop icon: string = '';
  
  // 内部状态：计算后的百分比
  @State private displayPercentage: number = 0;
  
  // 数据变化时重新计算
  onDataChange() {
    this.calculatePercentage();
  }
  
  aboutToAppear() {
    this.calculatePercentage();
  }
  
  // 计算百分比（带防护）
  private calculatePercentage() {
    // 防护：确保total不为0或undefined
    if (!this.total || this.total <= 0 || typeof this.total !== 'number') {
      this.displayPercentage = 0;
      return;
    }
    // 防护：确保value是有效数字
    if (typeof this.value !== 'number' || isNaN(this.value)) {
      this.displayPercentage = 0;
      return;
    }
    const p = (this.value / this.total) * 100;
    this.displayPercentage = Math.min(Math.round(p), 100);
  }
  
  build() {
    Column({ space: 8 }) {
      // 标题和数值
      Row() {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.GRAY_700)
          .layoutWeight(1)

        Text(`${this.value} / ${this.total} ${this.unit}`)
          .fontSize(14)
          .fontColor(AppColors.GRAY_600)
      }
      .width('100%')

      // 进度条
      Stack({ alignContent: Alignment.Start }) {
        // 背景条
        Row()
          .width('100%')
          .height(8)
          .backgroundColor(AppColors.GRAY_200)
          .borderRadius(4)

        // 进度条
        Row()
          .width(`${this.displayPercentage}%`)
          .height(8)
          .backgroundColor(this.color)
          .borderRadius(4)
      }
      .width('100%')
      .height(8)

      // 百分比
      Row() {
        Text(`${this.displayPercentage}%`)
          .fontSize(12)
          .fontColor(AppColors.GRAY_600)
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
  }
}

@Builder
export function ProgressCard(
  title: string,
  value: number,
  total: number,
  unit: string,
  color: string,
  icon: string
) {
  ProgressCardComponent({
    title: title,
    value: value,
    total: total,
    unit: unit,
    color: color,
    icon: icon
  })
}

@Builder
export function IconCard(
  title: string,
  value: string,
  icon: string,
  iconColor: ResourceColor = AppColors.PRIMARY,
  cardBackgroundColor: ResourceColor = AppColors.WHITE
) {
  Column({ space: 12 }) {
    // 图标
    Image(icon)
      .width(32)
      .height(32)
      .objectFit(ImageFit.Contain)
      .fillColor(iconColor)

    // 数值
    Text(value)
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
      .fontColor(AppColors.GRAY_900)

    // 标题
    Text(title)
      .fontSize(14)
      .fontColor(AppColors.GRAY_600)
  }
  .width('100%')
  .padding(16)
  .backgroundColor(cardBackgroundColor)
  .borderRadius(AppSizes.CARD_RADIUS)
  .justifyContent(FlexAlign.Center)
  .alignItems(HorizontalAlign.Center)
}