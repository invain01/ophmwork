/**
 * 一周数据概览页
 * 展示最近 7 天的饮水、步数、心率和体重折线图
 */
import { HealthCard } from '../components/index';
import { User } from '../model/User';
import { AppColors, AppSizes } from '../utils/Constants';
import { AuthService } from '../utils/AuthService';
import { DailyHealthRecord, HealthApiService } from '../utils/HealthApiService';
import { StorageService } from '../utils/StorageService';
import router from '@ohos.router';

class ChartPoint {
  x: number;
  y: number;
  isLast: boolean;

  constructor(x: number, y: number, isLast: boolean = false) {
    this.x = x;
    this.y = y;
    this.isLast = isLast;
  }
}

class AxisTick {
  value: number;
  y: number;

  constructor(value: number, y: number) {
    this.value = value;
    this.y = y;
  }
}

class WeekAxisLabel {
  dateLabel: string;
  weekdayLabel: string;
  isSelected: boolean;

  constructor(dateLabel: string, weekdayLabel: string, isSelected: boolean) {
    this.dateLabel = dateLabel;
    this.weekdayLabel = weekdayLabel;
    this.isSelected = isSelected;
  }
}

class MetricScale {
  bottomValue: number;
  topValue: number;
  step: number;
  ticks: AxisTick[];

  constructor(bottomValue: number, topValue: number, step: number, ticks: AxisTick[]) {
    this.bottomValue = bottomValue;
    this.topValue = topValue;
    this.step = step;
    this.ticks = ticks;
  }
}

type ChartShapePoint = [number, number];

class ChartRenderData {
  scale: MetricScale;
  points: ChartPoint[];
  polylinePoints: ChartShapePoint[];

  constructor(scale: MetricScale, points: ChartPoint[], polylinePoints: ChartShapePoint[]) {
    this.scale = scale;
    this.points = points;
    this.polylinePoints = polylinePoints;
  }
}

@Entry
@Component
struct WeekOverview {
  @State user: User = new User();
  @State selectedDate: Date = new Date();
  @State loading: boolean = true;
  @State weekLabels: WeekAxisLabel[] = [];
  @State waterSeries: number[] = [];
  @State stepSeries: number[] = [];
  @State heartRateSeries: number[] = [];
  @State weightSeries: number[] = [];

  private readonly chartWidth: number = 232;
  private readonly chartHeight: number = 160;
  private readonly chartPadding: number = 20;
  private readonly axisLabelWidth: number = 56;

  private get pageBackgroundColor(): string {
    return AppColors.GRAY_50;
  }

  private get cardBackgroundColor(): string {
    return AppColors.WHITE;
  }

  private get primaryTextColor(): string {
    return AppColors.GRAY_900;
  }

  private get secondaryTextColor(): string {
    return AppColors.GRAY_600;
  }

  private get mutedTextColor(): string {
    return AppColors.GRAY_500;
  }

  private get axisTextColor(): string {
    return AppColors.GRAY_500;
  }

  private get gridLineColor(): string {
    return AppColors.GRAY_200;
  }

  private get buttonBackgroundColor(): string {
    return AppColors.WHITE;
  }

  private get buttonBorderColor(): string {
    return AppColors.GRAY_200;
  }

  private get selectedLabelColor(): string {
    return AppColors.PRIMARY_DARK;
  }

  async aboutToAppear() {
    const isLoggedIn = await AuthService.getInstance().isLoggedIn();
    if (!isLoggedIn) {
      router.replaceUrl({ url: 'pages/Login' });
      return;
    }

    await this.loadPageData();
  }

  async onPageShow() {
    await this.loadPageData();
  }

  private async loadPageData() {
    this.loading = true;
    try {
      await this.loadUser();

      const savedDate = await StorageService.getInstance().getSelectedDateValue();
      const anchorDate = savedDate ?? new Date();
      anchorDate.setHours(0, 0, 0, 0);
      if (!savedDate) {
        await StorageService.getInstance().saveSelectedDateValue(anchorDate);
      }

      this.selectedDate = anchorDate;
      await this.loadWeekSeries(anchorDate);
    } finally {
      this.loading = false;
    }
  }

  private async loadUser() {
    const currentUser = await AuthService.getInstance().getCurrentUser();
    this.user = currentUser ?? new User();
  }

  private async loadWeekSeries(anchorDate: Date) {
    const startDate = this.getWeekStart(anchorDate);
    const endDate = new Date(anchorDate);
    endDate.setHours(0, 0, 0, 0);

    const remoteRecords = await HealthApiService.getInstance().fetchWeeklyHealthData(startDate, endDate, this.user?.id);
    const recordMap = new Map<string, DailyHealthRecord>();
    for (let i = 0; i < remoteRecords.length; i += 1) {
      const record = remoteRecords[i];
      recordMap.set(record.date, record);
    }

    const labels: WeekAxisLabel[] = [];
    const water: number[] = [];
    const steps: number[] = [];
    const heartRates: number[] = [];
    const weights: number[] = [];

    for (let i = 0; i < 7; i += 1) {
      const currentDate = new Date(startDate);
      currentDate.setDate(startDate.getDate() + i);
      currentDate.setHours(0, 0, 0, 0);
      const dateKey = this.getDateKey(currentDate);
      const record = recordMap.get(dateKey);
      labels.push(new WeekAxisLabel(
        this.formatCompactDate(currentDate),
        this.formatWeekday(currentDate),
        i === 6
      ));
      water.push(this.toSafeNumber(record?.waterIntake));
      steps.push(this.toSafeNumber(record?.steps));
      heartRates.push(this.toSafeNumber(record?.heartRate));
      weights.push(this.normalizeWeightValue(this.toSafeNumber(record?.weight)));
    }

    this.weekLabels = labels;
    this.waterSeries = water;
    this.stepSeries = steps;
    this.heartRateSeries = heartRates;
    this.weightSeries = weights;
  }

  private toSafeNumber(value?: number): number {
    return typeof value === 'number' && isFinite(value) ? value : 0;
  }

  private normalizeWeightValue(weight?: number): number {
    if (typeof weight !== 'number' || !isFinite(weight) || weight <= 0) {
      return 0;
    }
    let normalized = weight;
    while (normalized >= 300) {
      normalized = normalized / 10;
    }
    return Math.round(normalized * 10) / 10;
  }

  private getWeekStart(date: Date): Date {
    const start = new Date(date);
    start.setHours(0, 0, 0, 0);
    start.setDate(start.getDate() - 6);
    return start;
  }

  private getDateKey(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private formatSelectedDate(): string {
    return this.formatLongDate(this.selectedDate);
  }

  private formatLongDate(date: Date): string {
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const day = date.getDate();
    return `${year}年${month}月${day}日`;
  }

  private formatCompactDate(date: Date): string {
    const month = date.getMonth() + 1;
    const day = date.getDate();
    return `${month}/${day}`;
  }

  private formatWeekday(date: Date): string {
    const labels = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return labels[date.getDay()];
  }

  private formatMetricValue(value: number, unit: string, precision: number): string {
    const safeValue = typeof value === 'number' && isFinite(value) ? value : 0;
    if (precision <= 0) {
      return `${Math.round(safeValue)}${unit}`;
    }
    return `${safeValue.toFixed(precision)}${unit}`;
  }

  private formatMetricStep(step: number, unit: string, precision: number): string {
    return this.formatMetricValue(step, unit, precision);
  }

  private buildMetricScale(values: number[], useDataBounds: boolean = false): MetricScale {
    const maxValue = this.getMaxValue(values);
    const minValue = useDataBounds ? this.getMinValue(values) : 0;
    const tickCount = 5;
    const range = Math.max(maxValue - minValue, 0);
    const step = useDataBounds ? (range / (tickCount - 1)) : this.niceStep(range > 0 ? range / (tickCount - 1) : 1);
    const topValue = useDataBounds ? maxValue : step * (tickCount - 1);
    const bottomValue = useDataBounds ? minValue : 0;
    const ticks: AxisTick[] = [];
    for (let i = 0; i < tickCount; i += 1) {
      const value = topValue - step * i;
      const y = this.chartPadding + ((this.chartHeight - this.chartPadding * 2) / (tickCount - 1)) * i;
      ticks.push(new AxisTick(value, y));
    }
    return new MetricScale(bottomValue, topValue, step, ticks);
  }

  private getMaxValue(values: number[]): number {
    let maxValue = 0;
    for (let i = 0; i < values.length; i += 1) {
      const value = values[i];
      if (typeof value === 'number' && isFinite(value) && value > maxValue) {
        maxValue = value;
      }
    }
    return maxValue;
  }

  private getMinValue(values: number[]): number {
    let minValue: number | null = null;
    for (let i = 0; i < values.length; i += 1) {
      const value = values[i];
      if (typeof value === 'number' && isFinite(value)) {
        if (minValue === null || value < minValue) {
          minValue = value;
        }
      }
    }
    return minValue === null ? 0 : minValue;
  }

  private niceStep(value: number): number {
    if (typeof value !== 'number' || !isFinite(value) || value <= 0) {
      return 1;
    }
    const exponent = Math.floor(Math.log10(value));
    const fraction = value / Math.pow(10, exponent);
    let niceFraction = 1;
    if (fraction <= 1) {
      niceFraction = 1;
    } else if (fraction <= 2) {
      niceFraction = 2;
    } else if (fraction <= 2.5) {
      niceFraction = 2.5;
    } else if (fraction <= 5) {
      niceFraction = 5;
    } else {
      niceFraction = 10;
    }
    return niceFraction * Math.pow(10, exponent);
  }

  private buildLinePoints(values: number[], scale: MetricScale): ChartPoint[] {
    const safeWidth = Math.max(this.chartWidth, this.chartPadding * 2 + 1);
    const safeHeight = Math.max(this.chartHeight, this.chartPadding * 2 + 1);
    const usableWidth = safeWidth - this.chartPadding * 2;
    const usableHeight = safeHeight - this.chartPadding * 2;
    const gap = values.length > 1 ? usableWidth / (values.length - 1) : 0;
    const range = Math.max(scale.topValue - scale.bottomValue, 0);
    return values.map((value: number, index: number) => {
      const safeValue = typeof value === 'number' && isFinite(value) ? value : 0;
      const ratio = range > 0 ? Math.min(Math.max((safeValue - scale.bottomValue) / range, 0), 1) : 0;
      const x = this.chartPadding + gap * index;
      const y = safeHeight - this.chartPadding - ratio * usableHeight;
      return new ChartPoint(x, y, index === values.length - 1);
    });
  }

  private getChartRenderData(values: number[]): ChartRenderData {
    const scale = this.buildMetricScale(values);
    const points = this.buildLinePoints(values, scale);
    const polylinePoints = points.map((point: ChartPoint): ChartShapePoint => [point.x, point.y]);
    return new ChartRenderData(scale, points, polylinePoints);
  }

  private getWeightChartRenderData(values: number[]): ChartRenderData {
    const scale = this.buildMetricScale(values, true);
    const points = this.buildLinePoints(values, scale);
    const polylinePoints = points.map((point: ChartPoint): ChartShapePoint => [point.x, point.y]);
    return new ChartRenderData(scale, points, polylinePoints);
  }

  private getChartRenderDataByTitle(title: string, values: number[]): ChartRenderData {
    if (title === '体重趋势') {
      return this.getWeightChartRenderData(values);
    }
    return this.getChartRenderData(values);
  }

  @Builder
  buildChartTitle(step: number, unit: string, precision: number) {
  }

  @Builder
  buildMetricChart(title: string, values: number[], unit: string, color: string, precision: number) {
    HealthCard({
      title,
      cardBackgroundColor: this.cardBackgroundColor,
      iconColor: color,
      cardTextColor: this.primaryTextColor
    }) {
      Column({ space: 12 }) {
        this.buildChartTitle(this.getChartRenderDataByTitle(title, values).scale.step, unit, precision)

        Row({ space: 8 }) {
          Column({ space: 0 }) {
            ForEach(this.getChartRenderDataByTitle(title, values).scale.ticks, (tick: AxisTick) => {
              Text(this.formatMetricValue(tick.value, unit, precision))
                .fontSize(10)
                .fontColor(this.axisTextColor)
                .textAlign(TextAlign.RIGHT)
            })
          }
          .width(this.axisLabelWidth)
          .height(this.chartHeight)
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(HorizontalAlign.End)

          Stack() {
            ForEach(this.getChartRenderDataByTitle(title, values).scale.ticks, (tick: AxisTick) => {
              Row()
                .width('100%')
                .height(1)
                .backgroundColor(this.gridLineColor)
                .position({ x: 0, y: tick.y })
            })

            if (this.getChartRenderDataByTitle(title, values).points.length > 1) {
              Polyline()
                .points(this.getChartRenderDataByTitle(title, values).polylinePoints)
                .width('100%')
                .height('100%')
                .position({ x: 0, y: 0 })
                .stroke(color)
                .strokeWidth(2)
                .fill(Color.Transparent)
            }

            ForEach(this.getChartRenderDataByTitle(title, values).points, (point: ChartPoint) => {
              Circle({ width: point.isLast ? 8 : 6, height: point.isLast ? 8 : 6 })
                .fill(color)
                .position({ x: point.x - (point.isLast ? 4 : 3), y: point.y - (point.isLast ? 4 : 3) })
            })
          }
          .width(this.chartWidth)
          .height(this.chartHeight)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        Row() {
          Column()
            .width(this.axisLabelWidth)

          Row({ space: 0 }) {
            ForEach(this.weekLabels, (label: WeekAxisLabel) => {
              Column({ space: 2 }) {
                Text(label.dateLabel)
                  .fontSize(11)
                  .fontColor(label.isSelected ? this.selectedLabelColor : this.secondaryTextColor)
                  .fontWeight(label.isSelected ? FontWeight.Medium : FontWeight.Normal)

                Text(label.weekdayLabel)
                  .fontSize(10)
                  .fontColor(label.isSelected ? this.selectedLabelColor : this.mutedTextColor)
              }
              .width(`${100 / 7}%`)
              .alignItems(HorizontalAlign.Center)
            })
          }
          .width(this.chartWidth)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ top: 6, bottom: 8 })
    }
  }

  @Builder
  buildOverviewHeader() {
    HealthCard({
      title: '一周数据概览',
      cardBackgroundColor: this.cardBackgroundColor,
      iconColor: AppColors.PRIMARY,
      cardTextColor: this.primaryTextColor
    }) {
      Column({ space: 6 }) {
        Text(`所选日期：${this.formatSelectedDate()}`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.primaryTextColor)

        Text(`周范围：${this.formatLongDate(this.getWeekStart(this.selectedDate))} - ${this.formatLongDate(this.selectedDate)}`)
          .fontSize(12)
          .fontColor(this.axisTextColor)
      }
      .width('100%')
    }
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.pageBackgroundColor)

      Scroll() {
        Column({ space: 16 }) {
          Row({ space: 12 }) {
            Column({ space: 4 }) {
              Text('周数据概览')
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.primaryTextColor)

              Text('饮水、步数、心率与体重趋势')
                .fontSize(14)
                .fontColor(this.secondaryTextColor)
            }
            .layoutWeight(1)

            Button('返回')
              .height(36)
              .fontSize(14)
              .fontColor(AppColors.PRIMARY)
              .backgroundColor(this.buttonBackgroundColor)
              .border({ width: 1, color: this.buttonBorderColor })
              .borderRadius(AppSizes.BUTTON_RADIUS)
              .padding({ left: 12, right: 12 })
              .onClick(() => router.back())
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 24, bottom: 4 })

          Column() {
            this.buildOverviewHeader()
          }
          .margin({ left: 16, right: 16 })

          Column() {
            if (this.loading) {
              HealthCard({
                title: '加载中',
                cardBackgroundColor: this.cardBackgroundColor,
                iconColor: AppColors.PRIMARY,
                cardTextColor: this.primaryTextColor
              }) {
                Column({ space: 8 }) {
                  Text('正在读取最近 7 天的数据，请稍候。')
                    .fontSize(14)
                    .fontColor(this.secondaryTextColor)
                }
                .width('100%')
              }
            } else {
              Column() {
                this.buildMetricChart('饮水趋势', this.waterSeries, 'ml', AppColors.WATER_COLOR, 0)
              }
              .margin({ left: 16, right: 16 })

              Column() {
                this.buildMetricChart('步数趋势', this.stepSeries, '步', AppColors.STEPS_COLOR, 0)
              }
              .margin({ left: 16, right: 16 })

              Column() {
                this.buildMetricChart('心率趋势', this.heartRateSeries, 'bpm', AppColors.HEART_COLOR, 0)
              }
              .margin({ left: 16, right: 16 })

              Column() {
                this.buildMetricChart('体重趋势', this.weightSeries, 'kg', AppColors.PRIMARY_DARK, 1)
              }
              .margin({ left: 16, right: 16, bottom: 24 })
            }
          }
          .margin({ left: 16, right: 16 })
        }
        .width('100%')
        .opacity(1)
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