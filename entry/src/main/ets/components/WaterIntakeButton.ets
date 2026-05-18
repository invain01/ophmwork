/**
 * 饮水记录按钮组件
 * 点击增加水量的按钮
 */
import { AppColors, AppSizes } from '../utils/Constants';

@Component
export struct WaterIntakeButton {
  // 当前饮水量（毫升）
  @Prop currentWater: number = 0;
  
  // 目标饮水量（毫升）
  @Prop waterGoal: number = 2000;
  
  // 每次点击增加的水量
  @Prop incrementAmount: number = 250;
  
  // 按钮尺寸
  @Prop buttonSize: number = 80;
  
  // 按钮颜色
  @Prop buttonColor: string = AppColors.WATER_COLOR;
  
  // 是否显示动画
  @Prop animated: boolean = true;
  
  // 按钮状态
  @State isPressed: boolean = false;
  @State scaleValue: number = 1;
  
  /**
   * 计算完成百分比
   */
  get percentage(): number {
    return Math.min(this.currentWater / this.waterGoal, 1);
  }
  
  /**
   * 处理按钮点击
   */
  handleClick() {
    if (this.animated) {
      // 点击动画
      this.isPressed = true;
      this.scaleValue = 0.9;
      
      setTimeout(() => {
        this.isPressed = false;
        this.scaleValue = 1;
      }, 100);
    }
    
  }
  
  build() {
    Column({ space: 8 }) {
      // 水杯图标
      Stack({ alignContent: Alignment.Center }) {
        // 水杯背景
        Circle({ width: this.buttonSize, height: this.buttonSize })
          .fill(this.buttonColor)
          .opacity(0.1)
        
        // 水杯主体
        Column({ space: 0 }) {
          // 杯口
          Row()
            .width(this.buttonSize * 0.7)
            .height(8)
            .backgroundColor(this.buttonColor)
            .borderRadius(4)
            .margin({ bottom: 4 })
          
          // 杯身
          Stack() {
            // 杯身背景
            Column()
              .width(this.buttonSize * 0.6)
              .height(this.buttonSize * 0.7)
              .backgroundColor('#FFFFFF')
              .borderRadius({ topLeft: 8, topRight: 8, bottomLeft: 16, bottomRight: 16 })
              .border({ width: 2, color: this.buttonColor })
            
            // 水位
            Column()
              .width(this.buttonSize * 0.6 - 4)
              .height(this.buttonSize * 0.7 * this.percentage - 4)
              .backgroundColor(this.buttonColor)
              .opacity(0.6)
              .borderRadius({ 
                topLeft: 6, 
                topRight: 6, 
                bottomLeft: this.percentage >= 0.95 ? 12 : 0, 
                bottomRight: this.percentage >= 0.95 ? 12 : 0 
              })
              .margin({ top: 2 })
          }
          .height(this.buttonSize * 0.7)
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width(this.buttonSize)
      .height(this.buttonSize)
      .scale({ x: this.scaleValue, y: this.scaleValue })
      .onClick(() => {
        this.handleClick();
      })
      
      // 水量文本
      Column({ space: 2 }) {
        Text('+')
          .fontSize(14)
          .fontColor(this.buttonColor)
          .fontWeight(FontWeight.Bold)
        
        Text(`${this.incrementAmount}ml`)
          .fontSize(12)
          .fontColor(AppColors.GRAY_700)
      }
      .opacity(this.isPressed ? 0.7 : 1)
    }
    .width(this.buttonSize + 40)
    .alignItems(HorizontalAlign.Center)
  }
  
  /**
   * 创建小尺寸饮水按钮
   */
  @Builder static SmallWaterButton(
    currentWater: number
  ) {
    WaterIntakeButton({
      currentWater: currentWater,
      incrementAmount: 250,
      buttonSize: 60
    })
  }
  
  /**
   * 创建中尺寸饮水按钮
   */
  @Builder static MediumWaterButton(
    currentWater: number
  ) {
    WaterIntakeButton({
      currentWater: currentWater,
      incrementAmount: 250,
      buttonSize: 80
    })
  }
  
  /**
   * 创建大尺寸饮水按钮
   */
  @Builder static LargeWaterButton(
    currentWater: number
  ) {
    WaterIntakeButton({
      currentWater: currentWater,
      incrementAmount: 500,
      buttonSize: 100
    })
  }
  
  /**
   * 创建饮水进度卡片
   */
  @Builder static WaterProgressCard(
    currentWater: number,
    waterGoal: number = 2000
  ) {
    Column({ space: 16 }) {
      // 标题和进度
      Row() {
        Column({ space: 4 }) {
          Text('今日饮水')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.GRAY_900)
          
          Text(`${currentWater}ml / ${waterGoal}ml`)
            .fontSize(14)
            .fontColor(AppColors.GRAY_600)
        }
        .layoutWeight(1)
        
        Text(`${Math.round(Math.min(currentWater / waterGoal, 1) * 100)}%`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.WATER_COLOR)
      }
      .width('100%')
      
      // 进度条
      Stack() {
        // 背景条
        Row()
          .width('100%')
          .height(12)
          .backgroundColor(AppColors.GRAY_200)
          .borderRadius(6)
        
        // 进度条
        Row()
          .width(`${Math.min(currentWater / waterGoal, 1) * 100}%`)
          .height(12)
          .backgroundColor(AppColors.WATER_COLOR)
          .borderRadius(6)
      }
      .width('100%')
      .height(12)
      
      // 饮水按钮
      Row({ space: 12 }) {
        SmallWaterButton(currentWater)
        
        Text('点击水杯记录饮水')
          .fontSize(12)
          .fontColor(AppColors.GRAY_600)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: 8 })
      
      // 剩余水量提示
      if (waterGoal - currentWater > 0) {
        Text(`还需饮用 ${waterGoal - currentWater}ml 完成目标`)
          .fontSize(12)
          .fontColor(AppColors.GRAY_500)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 8 })
      } else {
        Text('🎉 恭喜完成今日饮水目标！')
          .fontSize(12)
          .fontColor(AppColors.SUCCESS)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 8 })
      }
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
  }
}

@Builder
export function SmallWaterButton(
  currentWater: number
) {
  WaterIntakeButton({
    currentWater: currentWater,
    incrementAmount: 250,
    buttonSize: 60
  })
}

@Builder
export function MediumWaterButton(
  currentWater: number
) {
  WaterIntakeButton({
    currentWater: currentWater,
    incrementAmount: 250,
    buttonSize: 80
  })
}

@Builder
export function LargeWaterButton(
  currentWater: number
) {
  WaterIntakeButton({
    currentWater: currentWater,
    incrementAmount: 500,
    buttonSize: 100
  })
}

@Builder
export function WaterProgressCard(
  currentWater: number,
  waterGoal: number = 2000
) {
  Column({ space: 16 }) {
    // 标题和进度
    Row() {
      Column({ space: 4 }) {
        Text('今日饮水')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.GRAY_900)

        Text(`${currentWater}ml / ${waterGoal}ml`)
          .fontSize(14)
          .fontColor(AppColors.GRAY_600)
      }
      .layoutWeight(1)

      Text(`${Math.round(Math.min(currentWater / waterGoal, 1) * 100)}%`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.WATER_COLOR)
    }
    .width('100%')

    // 进度条
    Stack() {
      // 背景条
      Row()
        .width('100%')
        .height(12)
        .backgroundColor(AppColors.GRAY_200)
        .borderRadius(6)

      // 进度条
      Row()
        .width(`${Math.min(currentWater / waterGoal, 1) * 100}%`)
        .height(12)
        .backgroundColor(AppColors.WATER_COLOR)
        .borderRadius(6)
    }
    .width('100%')
    .height(12)

    // 饮水按钮
    Row({ space: 12 }) {
      SmallWaterButton(currentWater)

      Text('点击水杯记录饮水')
        .fontSize(12)
        .fontColor(AppColors.GRAY_600)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 8 })

    // 剩余水量提示
    if (waterGoal - currentWater > 0) {
      Text(`还需饮用 ${waterGoal - currentWater}ml 完成目标`)
        .fontSize(12)
        .fontColor(AppColors.GRAY_500)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })
    } else {
      Text('🎉 恭喜完成今日饮水目标！')
        .fontSize(12)
        .fontColor(AppColors.SUCCESS)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })
    }
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
}