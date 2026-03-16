/**
 * 日志工具类
 */
export class Logger {
  private static readonly TAG: string = '[MachineControl]';

  static debug(message: string, ...args: Object[]): void {
    console.debug(`${Logger.TAG} ${message}`, ...args);
  }

  static info(message: string, ...args: Object[]): void {
    console.info(`${Logger.TAG} ${message}`, ...args);
  }

  static warn(message: string, ...args: Object[]): void {
    console.warn(`${Logger.TAG} ${message}`, ...args);
  }

  static error(message: string, ...args: Object[]): void {
    console.error(`${Logger.TAG} ${message}`, ...args);
  }
}
