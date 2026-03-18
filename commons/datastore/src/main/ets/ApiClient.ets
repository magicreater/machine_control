import { http } from '@kit.NetworkKit';
import { ApiConfig } from './ApiConfig';
import { buildApiBaseUrl } from './ApiHelpers';

interface ApiErrorBody {
  message?: string;
}

interface ApiHeaders {
  'Content-Type': string;
  Authorization?: string;
}

interface ApiRequestOptions {
  method: http.RequestMethod;
  connectTimeout: number;
  readTimeout: number;
  header: ApiHeaders;
  expectDataType: http.HttpDataType;
  extraData: string;
}

export class ApiClient {
  private static instance: ApiClient | null = null;
  private readonly baseUrl: string = buildApiBaseUrl(ApiConfig.DEFAULT_HOST, ApiConfig.DEFAULT_PORT);
  private authToken: string = '';

  private constructor() { }

  static getInstance(): ApiClient {
    if (!ApiClient.instance) {
      ApiClient.instance = new ApiClient();
    }
    return ApiClient.instance;
  }

  async get<T>(path: string): Promise<T> {
    return this.request<T>(path, http.RequestMethod.GET);
  }

  async post<T>(path: string, payload: Object): Promise<T> {
    return this.request<T>(path, http.RequestMethod.POST, payload);
  }

  async put<T>(path: string, payload: Object): Promise<T> {
    return this.request<T>(path, http.RequestMethod.PUT, payload);
  }

  setAuthToken(token: string): void {
    this.authToken = token;
  }

  clearAuthToken(): void {
    this.authToken = '';
  }

  private async request<T>(path: string, method: http.RequestMethod, payload?: Object): Promise<T> {
    const request = http.createHttp();
    const headers: ApiHeaders = {
      'Content-Type': 'application/json'
    };
    if (this.authToken && method !== http.RequestMethod.GET && path !== '/auth/login') {
      headers.Authorization = `Bearer ${this.authToken}`;
    }
    const options: ApiRequestOptions = {
      method: method,
      connectTimeout: ApiConfig.CONNECT_TIMEOUT_MS,
      readTimeout: ApiConfig.READ_TIMEOUT_MS,
      header: headers,
      expectDataType: http.HttpDataType.STRING,
      extraData: payload ? JSON.stringify(payload) : ''
    };

    try {
      const response = await request.request(`${this.baseUrl}${path}`, options);

      const rawBody: string = typeof response.result === 'string'
        ? response.result
        : JSON.stringify(response.result);

      if (response.responseCode >= 200 && response.responseCode < 300) {
        return rawBody ? JSON.parse(rawBody) as T : JSON.parse('{}') as T;
      }

      throw new Error(this.extractErrorMessage(rawBody));
    } catch (error) {
      if (error instanceof Error) {
        throw new Error(error.message);
      }
      throw new Error('网络请求失败，请检查后端服务和地址配置');
    } finally {
      request.destroy();
    }
  }

  private extractErrorMessage(rawBody: string): string {
    if (!rawBody) {
      return '请求失败，请稍后重试';
    }

    try {
      const body = JSON.parse(rawBody) as ApiErrorBody;
      return body.message || '请求失败，请稍后重试';
    } catch (_error) {
      return '请求失败，请稍后重试';
    }
  }
}
