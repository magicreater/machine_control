/**
 * 定时刷新管理器
 */
export class TimerManager {
  private static instance: TimerManager | null = null;
  private timers: Map<string, number> = new Map();
  private intervals: Map<string, number> = new Map();

  private constructor() { }

  static getInstance(): TimerManager {
    if (!TimerManager.instance) {
      TimerManager.instance = new TimerManager();
    }
    return TimerManager.instance;
  }

  /**
   * 启动定时任务
   * @param key 任务标识
   * @param callback 回调函数
   * @param interval 间隔时间（毫秒）
   * @param immediate 是否立即执行一次
   */
  startTimer(key: string, callback: () => void, interval: number, immediate: boolean = true): void {
    // 如果已存在同名定时器，先停止
    this.stopTimer(key);

    if (immediate) {
      callback();
    }

    const timerId = setInterval(() => {
      callback();
    }, interval);

    this.timers.set(key, timerId);
    this.intervals.set(key, interval);
    console.info(`Timer started: ${key}, interval: ${interval}ms`);
  }

  /**
   * 停止定时任务
   * @param key 任务标识
   */
  stopTimer(key: string): void {
    const timerId = this.timers.get(key);
    if (timerId !== undefined) {
      clearInterval(timerId);
      this.timers.delete(key);
      this.intervals.delete(key);
      console.info(`Timer stopped: ${key}`);
    }
  }

  /**
   * 停止所有定时任务
   */
  stopAllTimers(): void {
    this.timers.forEach((timerId, key) => {
      clearInterval(timerId);
      console.info(`Timer stopped: ${key}`);
    });
    this.timers.clear();
    this.intervals.clear();
  }

  /**
   * 检查定时任务是否存在
   */
  hasTimer(key: string): boolean {
    return this.timers.has(key);
  }

  /**
   * 获取定时任务间隔
   */
  getInterval(key: string): number {
    return this.intervals.get(key) || 0;
  }

  /**
   * 更新定时任务间隔
   */
  updateInterval(key: string, callback: () => void, newInterval: number): void {
    if (this.hasTimer(key)) {
      this.startTimer(key, callback, newInterval, false);
    }
  }
}
