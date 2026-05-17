/**
 * 步数圆环进度条组件
 * 使用Arc组件实现的步数圆环
 */
import { AppColors, AppSizes } from '../utils/Constants';

@Component
export struct StepRing {
  // 当前步数
  @Prop currentSteps: number = 0;
  
  // 目标步数
  @Prop goalSteps: number = 10000;
  
  // 圆环尺寸
  @Prop ringSize: number = 200;
  
  // 圆环宽度
  @Prop ringWidth: number = 16;
  
  // 是否显示动画
  @Prop animated: boolean = true;
  
  // 动画持续时间
  @Prop animationDuration: number = 1000;
  
  // 圆环颜色
  @Prop ringColor: ResourceColor = Color.Blue;
  
  // 背景颜色
  @Prop ringBackgroundColor: ResourceColor = Color.Gray;
  
  // 文本颜色
  @Prop textColor: ResourceColor = Color.Black;
  
  // 子标题颜色
  @Prop subtitleColor: ResourceColor = Color.Gray;
  
  // 是否显示目标文本
  @Prop showGoalText: boolean = true;
  
  // 动画进度（0-1）
  @State private animationProgress: number = 0;
  
  aboutToAppear() {
    if (this.animated) {
      // 启动动画
      this.startAnimation();
    } else {
      this.animationProgress = 1;
    }
  }
  
  startAnimation() {
    this.animationProgress = 0;
    animateTo({
      duration: this.animationDuration,
      curve: Curve.EaseInOut,
      onFinish: () => {
        this.animationProgress = 1;
      }
    }, () => {
      this.animationProgress = 1;
    });
  }
  
  /**
   * 计算进度百分比
   */
  get percentage(): number {
    const p = this.currentSteps / this.goalSteps;
    return p > 1 ? 1 : p;
  }
  
  /**
   * 计算动画进度
   */
  get animatedPercentage(): number {
    return this.percentage * this.animationProgress;
  }
  
  /**
   * 计算圆环角度
   */
  get ringAngle(): number {
    return this.animatedPercentage * 360;
  }
  
  /**
   * 计算圆环半径
   */
  get radius(): number {
    return (this.ringSize - this.ringWidth) / 2;
  }
  
  /**
   * 计算圆环周长
   */
  get circumference(): number {
    return 2 * Math.PI * this.radius;
  }
  
  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 背景圆环
      Circle({ width: this.ringSize, height: this.ringSize })
        .fill(this.ringBackgroundColor)
        .strokeWidth(0)
      
      // 进度圆环（使用Circle和strokeDashArray）
      if (this.ringAngle > 0) {
        Circle({ width: this.ringSize, height: this.ringSize })
          .fill(Color.Transparent)
          .strokeWidth(this.ringWidth)
          .stroke(this.ringColor)
          .strokeDashArray([this.circumference * this.animatedPercentage, this.circumference])
      }
      
      // 中心内容
      Column({ space: 4 }) {
        // 步数
        Text(`${this.currentSteps}`)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textColor)
        
        // 单位
        Text('步')
          .fontSize(14)
          .fontColor(this.subtitleColor)
          .margin({ top: 4 })
        
        // 目标文本
        if (this.showGoalText) {
          Text(`目标: ${this.goalSteps}步`)
            .fontSize(12)
            .fontColor(this.subtitleColor)
            .margin({ top: 8 })
        }
        
        // 百分比
        Text(`${Math.floor(this.percentage * 100)}%`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.ringColor)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width(this.ringSize)
    .height(this.ringSize)
  }
  
  /**
   * 创建预设的小尺寸步数圆环
   */
  @Builder static SmallStepRing(currentSteps: number, goalSteps: number = 10000) {
    StepRing({
      currentSteps: currentSteps,
      goalSteps: goalSteps,
      ringSize: 120,
      ringWidth: 10,
      animated: true,
      animationDuration: 800,
      showGoalText: false
    })
  }
  
  /**
   * 创建预设的中等尺寸步数圆环
   */
  @Builder static MediumStepRing(currentSteps: number, goalSteps: number = 10000) {
    StepRing({
      currentSteps: currentSteps,
      goalSteps: goalSteps,
      ringSize: 160,
      ringWidth: 12,
      animated: true,
      animationDuration: 1000
    })
  }
  
  /**
   * 创建预设的大尺寸步数圆环
   */
  @Builder static LargeStepRing(currentSteps: number, goalSteps: number = 10000) {
    StepRing({
      currentSteps: currentSteps,
      goalSteps: goalSteps,
      ringSize: 200,
      ringWidth: 16,
      animated: true,
      animationDuration: 1200
    })
  }
}

@Builder
export function SmallStepRing(currentSteps: number, goalSteps: number = 10000) {
  StepRing({
    currentSteps: currentSteps,
    goalSteps: goalSteps,
    ringSize: 120,
    ringWidth: 10,
    animated: true,
    animationDuration: 800,
    showGoalText: false
  })
}

@Builder
export function MediumStepRing(currentSteps: number, goalSteps: number = 10000) {
  StepRing({
    currentSteps: currentSteps,
    goalSteps: goalSteps,
    ringSize: 160,
    ringWidth: 12,
    animated: true,
    animationDuration: 1000
  })
}

@Builder
export function LargeStepRing(currentSteps: number, goalSteps: number = 10000) {
  StepRing({
    currentSteps: currentSteps,
    goalSteps: goalSteps,
    ringSize: 200,
    ringWidth: 16,
    animated: true,
    animationDuration: 1200
  })
}