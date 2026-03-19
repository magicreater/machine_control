import { DeviceModel, DeviceStatus } from './models/DeviceModel';
import { UserModel, UserRole } from './models/UserModel';

export interface UserDto {
  id: string;
  username: string;
  role: string;
  token?: string;
}

export interface DeviceDto {
  id: string;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  status: number;
  workCount: number;
  badCount: number;
  rottenCount: number;
  greenSkinCount: number;
  mechanicalDamageCount: number;
  sproutedCount: number;
  isLocked: boolean;
  lockedBy: string;
  lockedAt: number;
  updatedAt: number;
}

export function buildApiBaseUrl(host: string, port: number): string {
  return `http://${host}:${port}/api`;
}

export function mapUserDtoToModel(dto: UserDto): UserModel {
  return new UserModel({
    id: dto.id,
    username: dto.username,
    role: dto.role === UserRole.ADMIN ? UserRole.ADMIN : UserRole.USER,
    sessionToken: dto.token ?? ''
  });
}

export function mapDeviceDtoToModel(dto: DeviceDto): DeviceModel {
  return new DeviceModel({
    id: dto.id,
    name: dto.name,
    address: dto.address,
    latitude: dto.latitude,
    longitude: dto.longitude,
    status: dto.status as DeviceStatus,
    workCount: dto.workCount,
    badCount: dto.badCount,
    rottenCount: dto.rottenCount,
    greenSkinCount: dto.greenSkinCount,
    mechanicalDamageCount: dto.mechanicalDamageCount,
    sproutedCount: dto.sproutedCount,
    isLocked: dto.isLocked,
    lockedBy: dto.lockedBy,
    lockedAt: dto.lockedAt,
    updatedAt: dto.updatedAt
  });
}
