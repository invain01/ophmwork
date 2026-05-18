/**
 * 日历页面
 * 用于选择查看健康数据的日期
 */
import router from '@ohos.router';
import { AppColors, AppSizes } from '../utils/Constants';
import { StorageService } from '../utils/StorageService';

interface CalendarDay {
  day: number;
  month: number;
  year: number;
  isToday: boolean;
  isSelected: boolean;
  isCurrentMonth: boolean;
  hasData: boolean;
}

@Entry
@Component
struct CalendarPage {
  // 当前显示的年份和月份
  @State currentYear: number = new Date().getFullYear();
  @State currentMonth: number = new Date().getMonth();
  
  // 选中的日期
  @State selectedDate: Date = new Date();
  
  // 日历数据
  @State calendarDays: CalendarDay[] = [];

  // 有数据的日期键
  @State healthDataDateKeys: string[] = [];
  
  // 星期标签
  private weekDays: string[] = ['日', '一', '二', '三', '四', '五', '六'];
  
  // 月份名称
  private monthNames: string[] = [
    '一月', '二月', '三月', '四月', '五月', '六月',
    '七月', '八月', '九月', '十月', '十一月', '十二月'
  ];

  async aboutToAppear() {
    await this.refreshHealthDataDates();
    await this.loadSelectedDate();
    this.generateCalendar();
  }

  /**
   * 加载已选择的日期
   */
  async loadSelectedDate() {
    const savedDate = await StorageService.getInstance().getSelectedDate();
    if (savedDate) {
      this.selectedDate = new Date(savedDate);
      this.currentYear = this.selectedDate.getFullYear();
      this.currentMonth = this.selectedDate.getMonth();
    }
  }

  /**
   * 刷新有数据的日期列表
   */
  async refreshHealthDataDates() {
    const dates = await StorageService.getInstance().getAllHealthDataDates();
    this.healthDataDateKeys = dates.map((date) => this.formatDateKey(date));
  }

  /**
   * 生成日历数据
   */
  generateCalendar() {
    const days: CalendarDay[] = [];
    const today = new Date();
    const todayYear = today.getFullYear();
    const todayMonth = today.getMonth();
    const todayDay = today.getDate();
    
    // 获取当前月份的第一天
    const firstDayOfMonth = new Date(this.currentYear, this.currentMonth, 1);
    // 获取当前月份的最后一天
    const lastDayOfMonth = new Date(this.currentYear, this.currentMonth + 1, 0);
    // 获取第一天是星期几 (0 = 星期日, 6 = 星期六)
    const firstDayOfWeek = firstDayOfMonth.getDay();
    // 获取上个月的最后一天
    const lastDayOfPrevMonth = new Date(this.currentYear, this.currentMonth, 0).getDate();
    
    // 添加上个月的日期
    for (let i = firstDayOfWeek - 1; i >= 0; i--) {
      const day = lastDayOfPrevMonth - i;
      days.push({
        day,
        month: this.currentMonth - 1 < 0 ? 11 : this.currentMonth - 1,
        year: this.currentMonth === 0 ? this.currentYear - 1 : this.currentYear,
        isToday: false,
        isSelected: false,
        isCurrentMonth: false,
        hasData: false
      });
    }
    
    // 添加当前月份的日期
    const totalDaysInMonth = lastDayOfMonth.getDate();
    for (let day = 1; day <= totalDaysInMonth; day++) {
      const isToday = 
        this.currentYear === todayYear && 
        this.currentMonth === todayMonth && 
        day === todayDay;
      
      const isSelected = 
        this.selectedDate.getFullYear() === this.currentYear &&
        this.selectedDate.getMonth() === this.currentMonth &&
        this.selectedDate.getDate() === day;
      
      const dateKey = this.formatDateKey(new Date(this.currentYear, this.currentMonth, day));
      const hasData = this.healthDataDateKeys.indexOf(dateKey) >= 0;
      
      days.push({
        day,
        month: this.currentMonth,
        year: this.currentYear,
        isToday,
        isSelected,
        isCurrentMonth: true,
        hasData
      });
    }
    
    // 添加下个月的日期，直到填满6行
    const totalCells = 42; // 6行 * 7列
    const nextMonthDays = totalCells - days.length;
    for (let day = 1; day <= nextMonthDays; day++) {
      days.push({
        day,
        month: this.currentMonth + 1 > 11 ? 0 : this.currentMonth + 1,
        year: this.currentMonth === 11 ? this.currentYear + 1 : this.currentYear,
        isToday: false,
        isSelected: false,
        isCurrentMonth: false,
        hasData: false
      });
    }
    
    this.calendarDays = days;
  }

  /**
   * 选择日期
   */
  async selectDay(day: CalendarDay) {
    if (!day.isCurrentMonth) {
      // 如果点击的是非当前月份的日期，切换到对应的月份
      this.currentYear = day.year;
      this.currentMonth = day.month;
      this.generateCalendar();
      return;
    }
    
    // 更新选中的日期
    this.selectedDate = new Date(day.year, day.month, day.day);
    
    // 保存选中的日期到持久化存储
    await StorageService.getInstance().saveSelectedDate(this.selectedDate.toISOString());
    
    // 重新生成日历以更新选中状态
    this.generateCalendar();
    
    // 返回首页并传递选中的日期
    router.back({
      url: 'pages/Index',
      params: { selectedDate: this.selectedDate.toISOString() }
    });
  }

  /**
   * 确认选择
   */
  async confirmSelection() {
    await StorageService.getInstance().saveSelectedDate(this.selectedDate.toISOString());
    router.back({
      url: 'pages/Index',
      params: { selectedDate: this.selectedDate.toISOString() }
    });
  }

  /**
   * 切换到上个月
   */
  prevMonth() {
    if (this.currentMonth === 0) {
      this.currentMonth = 11;
      this.currentYear--;
    } else {
      this.currentMonth--;
    }
    this.generateCalendar();
  }

  /**
   * 切换到下个月
   */
  nextMonth() {
    if (this.currentMonth === 11) {
      this.currentMonth = 0;
      this.currentYear++;
    } else {
      this.currentMonth++;
    }
    this.generateCalendar();
  }

  /**
   * 返回到今天
   */
  goToToday() {
    const today = new Date();
    this.currentYear = today.getFullYear();
    this.currentMonth = today.getMonth();
    this.selectedDate = today;
    this.generateCalendar();
  }

  /**
   * 返回到首页
   */
  backToHome() {
    router.back();
  }

  /**
   * 格式化日期显示
   */
  formatSelectedDate(): string {
    const year = this.selectedDate.getFullYear();
    const month = this.selectedDate.getMonth() + 1;
    const day = this.selectedDate.getDate();
    return `${year}年${month}月${day}日`;
  }

  /**
   * 生成与存储一致的日期键
   */
  private formatDateKey(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /**
   * 构建月份导航栏
   */
  @Builder
  buildMonthNav() {
    Row({ space: 16 }) {
      // 上个月按钮
      Button('<')
        .width(40)
        .height(40)
        .fontSize(18)
        .fontColor(AppColors.PRIMARY)
        .backgroundColor(AppColors.WHITE)
        .border({ width: 1, color: AppColors.GRAY_200 })
        .borderRadius(20)
        .onClick(() => this.prevMonth())
      
      // 月份显示
      Column({ space: 4 }) {
        Text(`${this.currentYear}年 ${this.monthNames[this.currentMonth]}`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.GRAY_900)
        
        Text('当前选中: ' + this.formatSelectedDate())
          .fontSize(12)
          .fontColor(AppColors.GRAY_600)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      // 下个月按钮
      Button('>')
        .width(40)
        .height(40)
        .fontSize(18)
        .fontColor(AppColors.PRIMARY)
        .backgroundColor(AppColors.WHITE)
        .border({ width: 1, color: AppColors.GRAY_200 })
        .borderRadius(20)
        .onClick(() => this.nextMonth())
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(AppColors.WHITE)
  }

  /**
   * 构建星期标签行
   */
  @Builder
  buildWeekDays() {
    Row() {
      ForEach(this.weekDays, (day: string) => {
        Text(day)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.GRAY_600)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .padding({ top: 8, bottom: 8 })
      })
    }
    .width('100%')
    .backgroundColor(AppColors.GRAY_50)
  }

  /**
   * 构建日历网格
   */
  @Builder
  buildCalendarGrid() {
    Grid() {
      ForEach(this.calendarDays, (day: CalendarDay, index: number) => {
        GridItem() {
          this.buildDayCell(day)
        }
      })
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
    .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
    .columnsGap(1)
    .rowsGap(1)
    .width('100%')
    .height(300)
    .padding(8)
  }

  /**
   * 构建单个日期单元格
   */
  @Builder
  buildDayCell(day: CalendarDay) {
    Column({ space: 2 }) {
      // 日期数字
      Text(day.day.toString())
        .fontSize(16)
        .fontWeight(day.isSelected ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.getDayTextColor(day))
        .textAlign(TextAlign.Center)
      
      // 数据点指示器
      if (day.hasData && day.isCurrentMonth) {
        Circle()
          .width(4)
          .height(4)
          .fill(AppColors.PRIMARY)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getDayBackgroundColor(day))
    .borderRadius(4)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => this.selectDay(day))
  }

  /**
   * 获取日期文本颜色
   */
  private getDayTextColor(day: CalendarDay): ResourceColor {
    if (!day.isCurrentMonth) {
      return AppColors.GRAY_400;
    }
    if (day.isToday) {
      return AppColors.WHITE;
    }
    if (day.isSelected) {
      return AppColors.WHITE;
    }
    return AppColors.GRAY_800;
  }

  /**
   * 获取日期背景颜色
   */
  private getDayBackgroundColor(day: CalendarDay): ResourceColor {
    if (day.isToday) {
      return AppColors.PRIMARY;
    }
    if (day.isSelected) {
      return AppColors.SUCCESS;
    }
    if (!day.isCurrentMonth) {
      return AppColors.GRAY_100;
    }
    return AppColors.WHITE;
  }

  /**
   * 构建操作按钮
   */
  @Builder
  buildActionButtons() {
    Row({ space: 12 }) {
      Button('返回今天')
        .layoutWeight(1)
        .height(40)
        .fontSize(14)
        .fontColor(AppColors.PRIMARY)
        .backgroundColor(AppColors.WHITE)
        .border({ width: 1, color: AppColors.PRIMARY })
        .borderRadius(AppSizes.BUTTON_RADIUS)
        .onClick(() => this.goToToday())
      
      Button('确认选择')
        .layoutWeight(1)
        .height(40)
        .fontSize(14)
        .fontColor(AppColors.WHITE)
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius(AppSizes.BUTTON_RADIUS)
        .onClick(() => this.confirmSelection())
      
      Button('取消')
        .layoutWeight(1)
        .height(40)
        .fontSize(14)
        .fontColor(AppColors.GRAY_600)
        .backgroundColor(AppColors.GRAY_100)
        .borderRadius(AppSizes.BUTTON_RADIUS)
        .onClick(() => this.backToHome())
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  build() {
    Column({ space: 0 }) {
      // 顶部导航栏
      Row({ space: 12 }) {
        Image('back')
          .width(24)
          .height(24)
          .objectFit(ImageFit.Contain)
          .fillColor(AppColors.GRAY_700)
          .onClick(() => this.backToHome())
        
        Text('选择日期')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.GRAY_900)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(AppColors.WHITE)
      .border({ width: 1, color: AppColors.GRAY_200, style: BorderStyle.Solid })
      
      // 月份导航
      this.buildMonthNav()
      
      // 星期标签
      this.buildWeekDays()
      
      // 日历网格
      this.buildCalendarGrid()
      
      // 操作按钮
      this.buildActionButtons()
      
      // 说明文字
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Circle()
            .width(8)
            .height(8)
            .fill(AppColors.PRIMARY)
          
          Text('有数据')
            .fontSize(12)
            .fontColor(AppColors.GRAY_600)
        }
        
        Row({ space: 8 }) {
          Circle()
            .width(8)
            .height(8)
            .fill(AppColors.SUCCESS)
          
          Text('已选中')
            .fontSize(12)
            .fontColor(AppColors.GRAY_600)
        }
        
        Row({ space: 8 }) {
          Circle()
            .width(8)
            .height(8)
            .fill(AppColors.PRIMARY)
            .opacity(0.5)
          
          Text('今天')
            .fontSize(12)
            .fontColor(AppColors.GRAY_600)
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor(AppColors.GRAY_50)
      .borderRadius(AppSizes.CARD_RADIUS)
      .margin({ left: 16, right: 16, bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}