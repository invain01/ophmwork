/**
 * 一周健康概览页面
 * 展示最近七天的健康趋势折线图
 */
import router from '@ohos.router';
import { HealthCard } from '../components/index';
import { AppColors, AppSizes, DefaultValues } from '../utils/Constants';
import { AuthService } from '../utils/AuthService';
import { HealthApiService, DailyHealthRecord } from '../utils/HealthApiService';
import { StorageService } from '../utils/StorageService';
import { HealthData } from '../model/HealthData';

class ChartPoint {
  x: number;
  y: number;

  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }
}

class ChartTick {
  value: number;
  ratio: number;

  constructor(value: number, ratio: number) {
    this.value = value;
    this.ratio = ratio;
  }
}

class ChartPointValue {
  point: ChartPoint;
  value: number;

  constructor(point: ChartPoint, value: number) {
    this.point = point;
    this.value = value;
  }
}

class ChartLabelPoint {
  label: string;
  point: ChartPoint;

  constructor(label: string, point: ChartPoint) {
    this.label = label;
    this.point = point;
  }
}

class WeeklyMetricData {
  steps: number[];
  water: number[];
  heart: number[];
  calories: number[];

  constructor(steps: number[], water: number[], heart: number[], calories: number[]) {
    this.steps = steps;
    this.water = water;
    this.heart = heart;
    this.calories = calories;
  }
}

@Entry
@Component
struct WeeklyOverview {
  @State weeklyLabels: string[] = [];
  @State weeklySteps: number[] = [];
  @State weeklyWater: number[] = [];
  @State weeklyHeart: number[] = [];
  @State weeklyCalories: number[] = [];
  @State dateRange: string = '';

  private readonly chartWidth: number = 320;
  private readonly chartHeight: number = 140;
  private readonly chartPadding: number = 12;
  private readonly yAxisWidth: number = 28;

  async aboutToAppear() {
    await this.loadWeeklyData();
  }

  async onPageShow() {
    await this.loadWeeklyData();
  }

  private async loadWeeklyData() {
    const anchorDate = await this.resolveAnchorDate();
    const dates = this.buildWeekDates(anchorDate);
    const labels = dates.map((date: Date) => this.formatLabel(date));

    this.weeklyLabels = labels;
    this.dateRange = dates.length === 7 ? `${labels[0]} - ${labels[6]}` : '';

    const remote = await this.loadRemoteWeeklyData(dates);
    if (remote) {
      this.weeklySteps = remote.steps;
      this.weeklyWater = remote.water;
      this.weeklyHeart = remote.heart;
      this.weeklyCalories = remote.calories;
      return;
    }

    const steps: number[] = [];
    const water: number[] = [];
    const heart: number[] = [];
    const calories: number[] = [];

    for (const date of dates) {
      const stored = await StorageService.getInstance().getHealthData(date);
      steps.push(this.safeNumber(stored?.steps));
      water.push(this.safeNumber(stored?.waterIntake));
      heart.push(this.safeNumber(stored?.heartRate));
      calories.push(this.safeNumber(stored?.caloriesBurned));
    }

    this.weeklySteps = steps;
    this.weeklyWater = water;
    this.weeklyHeart = heart;
    this.weeklyCalories = calories;
  }

  private async loadRemoteWeeklyData(dates: Date[]): Promise<WeeklyMetricData | null> {
    if (dates.length === 0) {
      return null;
    }

    const user = await AuthService.getInstance().getCurrentUser();
    const records = await HealthApiService.getInstance().fetchWeeklyHealthData(
      dates[0],
      dates[dates.length - 1],
      user?.id
    );

    if (!records.length) {
      return null;
    }

    const recordMap = new Map<string, DailyHealthRecord>();
    for (const record of records) {
      recordMap.set(record.date, record);
    }

    const steps: number[] = [];
    const water: number[] = [];
    const heart: number[] = [];
    const calories: number[] = [];

    for (const date of dates) {
      const key = this.formatDateKey(date);
      const record = recordMap.get(key);
      if (record) {
        steps.push(this.safeNumber(record.steps));
        water.push(this.safeNumber(record.waterIntake));
        heart.push(this.safeNumber(record.heartRate));
        calories.push(this.safeNumber(record.caloriesBurned));
      } else {
        const stored = await StorageService.getInstance().getHealthData(date);
        steps.push(this.safeNumber(stored?.steps));
        water.push(this.safeNumber(stored?.waterIntake));
        heart.push(this.safeNumber(stored?.heartRate));
        calories.push(this.safeNumber(stored?.caloriesBurned));
      }
    }

    await this.persistRemoteRecords(recordMap);

    return new WeeklyMetricData(steps, water, heart, calories);
  }

  private async persistRemoteRecords(records: Map<string, DailyHealthRecord>): Promise<void> {
    for (const record of records.values()) {
      const date = this.parseDateKey(record.date);
      if (!date) {
        continue;
      }
      const data = this.buildHealthDataFromRecord(record);
      await StorageService.getInstance().saveHealthData(date, data);
    }
  }

  private buildHealthDataFromRecord(record: DailyHealthRecord): HealthData {
    const data = new HealthData();
    data.steps = record.steps;
    data.stepGoal = DefaultValues.DEFAULT_STEP_GOAL;
    data.waterIntake = record.waterIntake;
    data.waterGoal = DefaultValues.DEFAULT_WATER_GOAL;
    data.sleepHours = record.sleepHours;
    data.sleepGoal = DefaultValues.DEFAULT_SLEEP_GOAL;
    data.heartRate = record.heartRate;
    data.caloriesBurned = record.caloriesBurned;
    data.calorieGoal = DefaultValues.DEFAULT_CALORIE_GOAL;
    data.lastUpdated = record.date;
    return data;
  }

  private get labels(): string[] {
    return this.weeklyLabels.length === 7
      ? this.weeklyLabels
      : ['-', '-', '-', '-', '-', '-', '-'];
  }

  private get stepsData(): number[] {
    return this.weeklySteps.length === 7 ? this.weeklySteps : new Array(7).fill(0);
  }

  private get waterData(): number[] {
    return this.weeklyWater.length === 7 ? this.weeklyWater : new Array(7).fill(0);
  }

  private get heartData(): number[] {
    return this.weeklyHeart.length === 7 ? this.weeklyHeart : new Array(7).fill(0);
  }

  private get caloriesData(): number[] {
    return this.weeklyCalories.length === 7 ? this.weeklyCalories : new Array(7).fill(0);
  }

  private async resolveAnchorDate(): Promise<Date> {
    const saved = await StorageService.getInstance().getSelectedDate();
    if (saved) {
      const parsed = new Date(saved);
      if (!isNaN(parsed.getTime())) {
        return parsed;
      }
    }
    return new Date();
  }

  private getStartOfDay(date: Date): Date {
    const start = new Date(date);
    start.setHours(0, 0, 0, 0);
    return start;
  }

  private buildWeekDates(anchorDate: Date): Date[] {
    const end = this.getStartOfDay(anchorDate);
    const dates: Date[] = [];
    for (let i = 6; i >= 0; i -= 1) {
      const date = new Date(end);
      date.setDate(end.getDate() - i);
      dates.push(date);
    }
    return dates;
  }

  private safeNumber(value?: number | string): number {
    if (typeof value === 'number' && isFinite(value)) {
      return value;
    }
    if (typeof value === 'string') {
      const parsed = Number(value);
      return isFinite(parsed) ? parsed : 0;
    }
    return 0;
  }



  private formatLabel(date: Date): string {
    const month = date.getMonth() + 1;
    const day = date.getDate();
    return `${month}/${day}`;
  }

  private formatDateKey(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private parseDateKey(value: string): Date | null {
    const match = value.match(/^(\d{4})-(\d{2})-(\d{2})$/);
    if (!match) {
      return null;
    }
    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);
    const date = new Date(year, month - 1, day);
    return isNaN(date.getTime()) ? null : date;
  }



  private formatValue(value: number, unit: string): string {
    const rounded = Math.round(value);
    return unit ? `${rounded}${unit}` : `${rounded}`;
  }

  private formatUnitLabel(unit: string): string {
    return unit ? unit : '';
  }

  private formatAxisValue(value: number): string {
    return `${Math.round(value)}`;
  }

  private formatPointValue(value: number): string {
    return `${Math.round(value)}`;
  }

  private getXAxisItemWidth(): number {
    return this.chartWidth / 7;
  }

  private getLabelX(index: number): number {
    const safeWidth = Math.max(this.chartWidth, this.chartPadding * 2 + 1);
    const usableWidth = safeWidth - this.chartPadding * 2;
    const gap = usableWidth / 6;
    const x = this.chartPadding + gap * index;
    return x - 15;
  }

  private getMaxValue(data?: number[]): number {
    if (!Array.isArray(data) || data.length === 0) {
      return 1;
    }
    const max = Math.max(...data);
    return max > 0 ? max : 1;
  }

  private buildLinePoints(data?: number[]): ChartPoint[] {
    const safeData = Array.isArray(data) ? data : [];
    const max = this.getMaxValue(safeData);
    const safeWidth = Math.max(this.chartWidth, this.chartPadding * 2 + 1);
    const safeHeight = Math.max(this.chartHeight, this.chartPadding * 2 + 1);
    const usableWidth = safeWidth - this.chartPadding * 2;
    const usableHeight = safeHeight - this.chartPadding * 2;
    const gap = safeData.length > 1 ? usableWidth / (safeData.length - 1) : 0;
    return safeData.map((value: number, index: number) => {
      const safeValue = this.safeNumber(value);
      const ratio = max > 0 ? Math.min(Math.max(safeValue / max, 0), 1) : 0;
      const x = this.chartPadding + gap * index;
      const y = safeHeight - this.chartPadding - ratio * usableHeight;
      return new ChartPoint(x, y);
    });
  }

  private buildLinePath(points: ChartPoint[]): string {
    if (points.length === 0) return '';
    return points
      .map((point: ChartPoint, index: number) => {
        const command = index === 0 ? 'M' : 'L';
        return `${command} ${point.x} ${point.y}`;
      })
      .join(' ');
  }

  private normalizeWeekData(data: number[]): number[] {
    return Array.isArray(data) ? data : new Array(7).fill(0);
  }

  private getMetricPoints(data: number[]): ChartPoint[] {
    return this.buildLinePoints(this.normalizeWeekData(data));
  }

  private getMetricPath(data: number[]): string {
    return this.buildLinePath(this.getMetricPoints(data));
  }

  private getYAxisTicks(data: number[]): ChartTick[] {
    const safeData = this.normalizeWeekData(data);
    const max = this.getMaxValue(safeData);
    const ticks: ChartTick[] = [];
    const tickCount = 3;
    for (let i = 0; i < tickCount; i += 1) {
      const ratio = i / (tickCount - 1);
      const value = max * (1 - ratio);
      ticks.push(new ChartTick(value, ratio));
    }
    return ticks;
  }

  private getTickY(ratio: number): number {
    const safeHeight = Math.max(this.chartHeight, this.chartPadding * 2 + 1);
    const usableHeight = safeHeight - this.chartPadding * 2;
    return this.chartPadding + ratio * usableHeight;
  }

  private getMetricPointValues(data: number[]): ChartPointValue[] {
    const safeData = this.normalizeWeekData(data);
    const points = this.buildLinePoints(safeData);
    return points.map((point: ChartPoint, index: number) => {
      const value = safeData[index] ?? 0;
      return new ChartPointValue(point, value);
    });
  }

  private getMetricLabelPoints(data: number[], labels?: string[]): ChartLabelPoint[] {
    const safeLabels = Array.isArray(labels) && labels.length === 7
      ? labels
      : ['-', '-', '-', '-', '-', '-', '-'];
    const points = this.buildLinePoints(this.normalizeWeekData(data));
    return safeLabels.map((label: string, index: number) => {
      const point = points[index] ?? new ChartPoint(this.chartPadding, this.chartHeight - this.chartPadding);
      return new ChartLabelPoint(label, point);
    });
  }

  private goBack() {
    router.back();
  }

  @Builder
  buildMetricCard(title: string, color: string, data: number[], unit: string) {
    HealthCard({
      title: title,
      cardBackgroundColor: AppColors.WHITE,
      iconColor: color
    }) {
      Column({ space: 12 }) {
        Row({ space: 8 }) {
          Stack() {
            if (this.formatUnitLabel(unit)) {
              Text(this.formatUnitLabel(unit))
                .fontSize(10)
                .fontColor(AppColors.GRAY_500)
                .position({ x: 0, y: 0 })
            }

            ForEach(this.getYAxisTicks(data), (tick: ChartTick) => {
              Text(this.formatAxisValue(tick.value))
                .fontSize(10)
                .fontColor(AppColors.GRAY_500)
                .position({ x: 0, y: this.getTickY(tick.ratio) - 6 })
            })
          }
          .width(this.yAxisWidth)
          .height(this.chartHeight)

          Stack() {
            Row()
              .width('100%')
              .height(1)
              .backgroundColor(AppColors.GRAY_200)
              .position({ x: 0, y: this.chartHeight - this.chartPadding })

            if (this.getMetricPath(data)) {
              Shape() {
                Path()
                  .commands(this.getMetricPath(data))
                  .stroke(color)
                  .strokeWidth(2)
                  .fill(Color.Transparent)
              }
            }

            ForEach(this.getMetricPoints(data), (point: ChartPoint) => {
              Circle({ width: 6, height: 6 })
                .fill(color)
                .position({ x: point.x - 3, y: point.y - 3 })
            })

            ForEach(this.getMetricPointValues(data), (item: ChartPointValue) => {
              Text(this.formatPointValue(item.value))
                .fontSize(10)
                .fontColor(AppColors.GRAY_700)
                .width(36)
                .textAlign(TextAlign.Center)
                .position({ x: item.point.x - 18, y: item.point.y - 20 })
            })

            ForEach(this.getMetricLabelPoints(data, this.labels), (item: ChartLabelPoint) => {
              Text(item.label)
                .fontSize(10)
                .fontColor(AppColors.BLACK)
                .width(40)
                .textAlign(TextAlign.Center)
                .position({ x: item.point.x - 20, y: this.chartHeight + 6 })
            })
          }
          .width(this.chartWidth)
          .height(this.chartHeight + 28)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
    }
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.GRAY_50)

      Scroll() {
        Column({ space: 16 }) {
          Row({ space: 12 }) {
            Button('返回')
              .height(32)
              .fontSize(12)
              .fontColor(AppColors.PRIMARY)
              .backgroundColor(AppColors.WHITE)
              .border({ width: 1, color: AppColors.GRAY_200 })
              .borderRadius(AppSizes.BUTTON_RADIUS)
              .padding({ left: 12, right: 12 })
              .onClick(() => this.goBack())

            Column({ space: 4 }) {
              Text('一周健康概览')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.GRAY_900)

              if (this.dateRange) {
                Text(this.dateRange)
                  .fontSize(12)
                  .fontColor(AppColors.GRAY_600)
              }
            }
            .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 24 })

          Column() {
            this.buildMetricCard('饮水趋势', AppColors.WATER_COLOR, this.waterData, '毫升')
          }
          .margin({ left: 16, right: 16 })

          Column() {
            this.buildMetricCard('步数趋势', AppColors.STEPS_COLOR, this.stepsData, '步')
          }
          .margin({ left: 16, right: 16 })

          Column() {
            this.buildMetricCard('心率趋势', AppColors.HEART_COLOR, this.heartData, 'bpm')
          }
          .margin({ left: 16, right: 16 })

          Column() {
            this.buildMetricCard('卡路里趋势', AppColors.CALORIES_COLOR, this.caloriesData, 'kcal')
          }
          .margin({ left: 16, right: 16, bottom: 24 })
        }
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
  }
}
