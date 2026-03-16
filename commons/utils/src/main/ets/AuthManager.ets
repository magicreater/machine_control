import { UserModel, UserRole } from 'datastore';

/**
 * 认证状态管理器
 */
export class AuthManager {
  private static instance: AuthManager | null = null;
  private currentUser: UserModel | null = null;
  private isLoggedIn: boolean = false;

  private constructor() { }

  static getInstance(): AuthManager {
    if (!AuthManager.instance) {
      AuthManager.instance = new AuthManager();
    }
    return AuthManager.instance;
  }

  /**
   * 设置当前用户
   */
  setCurrentUser(user: UserModel): void {
    this.currentUser = user;
    this.isLoggedIn = true;
  }

  /**
   * 获取当前用户
   */
  getCurrentUser(): UserModel | null {
    return this.currentUser;
  }

  /**
   * 检查是否已登录
   */
  checkLoggedIn(): boolean {
    return this.isLoggedIn && this.currentUser !== null;
  }

  /**
   * 检查是否有锁定权限
   */
  canLockDevice(): boolean {
    return this.currentUser !== null && this.currentUser.role === UserRole.ADMIN;
  }

  /**
   * 获取当前用户名
   */
  getCurrentUsername(): string {
    return this.currentUser?.username || '';
  }

  /**
   * 获取当前用户角色
   */
  getCurrentRole(): UserRole {
    return this.currentUser?.role || UserRole.USER;
  }

  /**
   * 登出
   */
  logout(): void {
    this.currentUser = null;
    this.isLoggedIn = false;
  }
}
