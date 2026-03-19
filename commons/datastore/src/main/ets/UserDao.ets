import { UserModel, UserRole } from './models/UserModel';
import { ApiClient } from './ApiClient';
import { mapUserDtoToModel, UserDto } from './ApiHelpers';

interface LoginPayload {
  username: string;
  password: string;
}

interface CreateUserPayload {
  username: string;
  password: string;
  role: string;
}

export abstract class UserApiClientBase {
  abstract post<T>(path: string, payload: Object): Promise<T>;
  abstract setAuthToken(token: string): void;
  abstract clearAuthToken(): void;
}

class DefaultUserApiClient extends UserApiClientBase {
  private readonly apiClient: ApiClient;

  constructor(apiClient: ApiClient) {
    super();
    this.apiClient = apiClient;
  }

  post<T>(path: string, payload: Object): Promise<T> {
    return this.apiClient.post<T>(path, payload);
  }

  setAuthToken(token: string): void {
    this.apiClient.setAuthToken(token);
  }

  clearAuthToken(): void {
    this.apiClient.clearAuthToken();
  }
}

/**
 * 用户数据访问对象
 */
export class UserDao {
  private static instance: UserDao | null = null;
  private readonly apiClient: UserApiClientBase;

  private constructor(apiClient: UserApiClientBase) {
    this.apiClient = apiClient;
  }

  static getInstance(): UserDao {
    if (!UserDao.instance) {
      UserDao.instance = new UserDao(new DefaultUserApiClient(ApiClient.getInstance()));
    }
    return UserDao.instance;
  }

  static createForTesting(apiClient: UserApiClientBase): UserDao {
    return new UserDao(apiClient);
  }

  /**
   * 用户登录验证
   */
  async validateUser(username: string, password: string): Promise<UserModel | null> {
    const payload: LoginPayload = {
      username: username,
      password: password
    };
    try {
      const dto = await this.apiClient.post<UserDto>('/auth/login', payload);
      const user = mapUserDtoToModel(dto);
      this.apiClient.setAuthToken(user.sessionToken);
      return user;
    } catch (error) {
      this.apiClient.clearAuthToken();
      if (error instanceof Error && error.message === '用户名或密码错误') {
        return null;
      }
      if (error instanceof Error) {
        throw new Error(error.message);
      }
      throw new Error('登录失败，请检查后端服务');
    }
  }

  /**
   * 根据ID获取用户
   */
  async getUserById(id: string): Promise<UserModel | null> {
    return null;
  }

  /**
   * 根据用户名获取用户
   */
  async getUserByUsername(username: string): Promise<UserModel | null> {
    return null;
  }

  /**
   * 创建用户
   */
  async createUser(username: string, password: string, role: UserRole): Promise<UserModel> {
    const payload: CreateUserPayload = {
      username: username,
      password: password,
      role: role
    };

    try {
      const dto = await this.apiClient.post<UserDto>('/users', payload);
      return mapUserDtoToModel(dto);
    } catch (error) {
      if (error instanceof Error) {
        throw new Error(error.message);
      }
      throw new Error('新增用户失败，请稍后重试');
    }
  }

  /**
   * 获取所有用户
   */
  async getAllUsers(): Promise<UserModel[]> {
    return [];
  }

  clearSession(): void {
    this.apiClient.clearAuthToken();
  }
}
