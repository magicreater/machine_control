import { relationalStore } from '@kit.ArkData';
import { UserModel, UserModelOptions, UserRole } from './models/UserModel';
import { Database } from './Database';

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

    private getStore(): relationalStore.RdbStore {
        return Database.getInstance().getStore();
    }

    /**
     * 用户登录验证
     */
    async validateUser(username: string, password: string): Promise<UserModel | null> {
        const predicates = new relationalStore.RdbPredicates('users');
        predicates.equalTo('username', username);
        predicates.equalTo('password_hash', password); // 实际应用中应比对加密后的密码

        const result = await this.getStore().query(predicates);

        let user: UserModel | null = null;
        if (result.goToNextRow()) {
            user = this.resultToUser(result);
        }
        result.close();
        return user;
    }

    /**
     * 根据ID获取用户
     */
    async getUserById(id: string): Promise<UserModel | null> {
        const predicates = new relationalStore.RdbPredicates('users');
        predicates.equalTo('id', id);

        const result = await this.getStore().query(predicates);

        let user: UserModel | null = null;
        if (result.goToNextRow()) {
            user = this.resultToUser(result);
        }
        result.close();
        return user;
    }

    /**
     * 根据用户名获取用户
     */
    async getUserByUsername(username: string): Promise<UserModel | null> {
        const predicates = new relationalStore.RdbPredicates('users');
        predicates.equalTo('username', username);

        const result = await this.getStore().query(predicates);

        let user: UserModel | null = null;
        if (result.goToNextRow()) {
            user = this.resultToUser(result);
        }
        result.close();
        return user;
    }

    /**
     * 创建用户
     */
    async createUser(username: string, password: string, role: UserRole): Promise<boolean> {
        const values: relationalStore.ValuesBucket = {
            id: `USR${Date.now()}`,
            username: username,
            password_hash: password, // 实际应用中应加密
            role: role,
            created_at: Date.now()
        };

        const rowId = await this.getStore().insert('users', values);
        return rowId !== -1;
    }

    /**
     * 获取所有用户
     */
    async getAllUsers(): Promise<UserModel[]> {
        const predicates = new relationalStore.RdbPredicates('users');
        const result = await this.getStore().query(predicates);
        const users: UserModel[] = [];

        while (result.goToNextRow()) {
            users.push(this.resultToUser(result));
        }
        result.close();
        return users;
    }

    /**
     * 将查询结果转换为用户模型
     */
    private resultToUser(result: relationalStore.ResultSet): UserModel {
        const options: UserModelOptions = {
            id: result.getString(result.getColumnIndex('id')),
            username: result.getString(result.getColumnIndex('username')),
            passwordHash: result.getString(result.getColumnIndex('password_hash')),
            role: result.getString(result.getColumnIndex('role')) as UserRole,
            createdAt: result.getLong(result.getColumnIndex('created_at'))
        };
        return new UserModel(options);
    }
}
