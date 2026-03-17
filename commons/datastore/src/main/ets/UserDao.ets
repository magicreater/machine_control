import { UserModel, UserRole } from './models/UserModel';
import { ApiClient } from './ApiClient';
import { mapUserDtoToModel, UserDto } from './ApiHelpers';

interface LoginPayload {
    username: string;
    password: string;
}

/**
 * 用户数据访问对象
 */
export class UserDao {
    private static instance: UserDao | null = null;

    private constructor() { }

    static getInstance(): UserDao {
        if (!UserDao.instance) {
            UserDao.instance = new UserDao();
        }
        return UserDao.instance;
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
            const dto = await ApiClient.getInstance().post<UserDto>('/auth/login', payload);
            return mapUserDtoToModel(dto);
        } catch (error) {
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
    async createUser(username: string, password: string, role: UserRole): Promise<boolean> {
        return false;
    }

    /**
     * 获取所有用户
     */
    async getAllUsers(): Promise<UserModel[]> {
        return [];
    }
}
