/**
 * 应用常量
 */

// 应用颜色
export class AppColors {
  // 主色调
  static readonly PRIMARY = '#4A90E2';
  static readonly PRIMARY_LIGHT = '#7BB4F0';
  static readonly PRIMARY_DARK = '#2C6CB0';
  
  // 辅助色
  static readonly SECONDARY = '#FF6B6B';
  static readonly SUCCESS = '#4CAF50';
  static readonly WARNING = '#FFC107';
  static readonly INFO = '#2196F3';
  static readonly ERROR = '#F44336';
  
  // 中性色
  static readonly WHITE = '#FFFFFF';
  static readonly BLACK = '#000000';
  // 透明色（#AARRGGBB）
  static readonly BLACK_10 = '#1A000000';
  static readonly GRAY_50 = '#FAFAFA';
  static readonly GRAY_100 = '#F5F5F5';
  static readonly GRAY_200 = '#EEEEEE';
  static readonly GRAY_300 = '#E0E0E0';
  static readonly GRAY_400 = '#BDBDBD';
  static readonly GRAY_500 = '#9E9E9E';
  static readonly GRAY_600 = '#757575';
  static readonly GRAY_700 = '#616161';
  static readonly GRAY_800 = '#424242';
  static readonly GRAY_900 = '#212121';
  
  // 健康数据颜色
  static readonly STEPS_COLOR = '#4A90E2';
  static readonly WATER_COLOR = '#2196F3';
  static readonly SLEEP_COLOR = '#9C27B0';
  static readonly HEART_COLOR = '#FF6B6B';
  static readonly CALORIES_COLOR = '#FF9800';
  
  // 渐变背景
  static readonly GRADIENT_START = '#667eea';
  static readonly GRADIENT_END = '#764ba2';
  static readonly GRADIENT_DARK_START = '#1a1a2e';
  static readonly GRADIENT_DARK_END = '#16213e';
}

// 应用尺寸
export class AppSizes {
  static readonly CARD_RADIUS = 16;
  static readonly CARD_PADDING = 16;
  static readonly CARD_MARGIN = 12;
  static readonly BUTTON_RADIUS = 8;
  static readonly ICON_SIZE = 24;
  static readonly AVATAR_SIZE = 60;
  static readonly CHART_HEIGHT = 120;
}

// 动画持续时间
export class AnimationDurations {
  static readonly FAST = 200;
  static readonly NORMAL = 300;
  static readonly SLOW = 500;
}

// 存储键
export class StorageKeys {
  static readonly USER_DATA = 'harmonycare_user_data';
  static readonly HEALTH_DATA = 'harmonycare_health_data';
  static readonly SETTINGS = 'harmonycare_settings';
}

// 默认值
export class DefaultValues {
  static readonly DEFAULT_STEP_GOAL = 10000;
  static readonly DEFAULT_WATER_GOAL = 2000;
  static readonly DEFAULT_SLEEP_GOAL = 8;
  static readonly DEFAULT_CALORIE_GOAL = 500;
  
  static readonly DEFAULT_STEPS = 6543;
  static readonly DEFAULT_WATER = 1250;
  static readonly DEFAULT_SLEEP = 7.5;
  static readonly DEFAULT_HEART_RATE = 72;
  static readonly DEFAULT_CALORIES = 450;
}