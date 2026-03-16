import { router } from '@kit.ArkUI';
import { DeviceModel, DeviceDao, DeviceStatus } from 'datastore';
import { TimerManager, Constants, AuthManager } from 'utils';
import { AppColors, AppTypography, DeviceCard, StatCard, LoadingOverlay } from 'uikit';

/**
 * 设备列表页面
 */
@Component
export struct DeviceListPage {
  @State private devices: DeviceModel[] = [];
  @State private isLoading: boolean = true;
  @State private isRefreshing: boolean = false;
  @State private filterStatus: number = -1; // -1: 全部
  @State private searchText: string = '';
  // 统计数据
  @State private totalCount: number = 0;
  @State private workingCount: number = 0;
  @State private standbyCount: number = 0;
  @State private lockedCount: number = 0;

  aboutToAppear(): void {
    this.loadDevices();
    this.startAutoRefresh();
  }

  aboutToDisappear(): void {
    TimerManager.getInstance().stopTimer('device_list_refresh');
  }

  private async loadDevices(): Promise<void> {
    try {
      const allDevices = await DeviceDao.getInstance().getAllDevices();
      this.devices = allDevices;
      this.updateStatistics(allDevices);
    } catch (error) {
      console.error('Failed to load devices:', error);
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }

  private updateStatistics(devices: DeviceModel[]): void {
    this.totalCount = devices.length;
    this.workingCount = devices.filter(d => d.status === DeviceStatus.WORKING && !d.isLocked).length;
    this.standbyCount = devices.filter(d => d.status === DeviceStatus.STANDBY && !d.isLocked).length;
    this.lockedCount = devices.filter(d => d.isLocked).length;
  }

  private startAutoRefresh(): void {
    TimerManager.getInstance().startTimer(
      'device_list_refresh',
      () => this.loadDevices(),
      Constants.REFRESH_INTERVAL,
      false
    );
  }

  private getFilteredDevices(): DeviceModel[] {
    let filtered = this.devices;

    // 状态筛选
    if (this.filterStatus >= 0) {
      if (this.filterStatus === 3) {
        // 锁定状态
        filtered = filtered.filter(d => d.isLocked);
      } else {
        filtered = filtered.filter(d => d.status === this.filterStatus && !d.isLocked);
      }
    }

    // 搜索筛选
    if (this.searchText) {
      const keyword = this.searchText.toLowerCase();
      filtered = filtered.filter(d =>
      d.name.toLowerCase().includes(keyword) ||
      d.address.toLowerCase().includes(keyword) ||
      d.id.toLowerCase().includes(keyword)
      );
    }

    return filtered;
  }

  private navigateToDetail(device: DeviceModel): void {
    router.pushUrl({
      url: 'pages/DeviceDetailPage',
      params: { deviceId: device.id }
    });
  }

  build() {
    Stack() {
      Column() {
        // 顶部统计卡片
        this.statsSection()

        // 搜索和筛选
        this.filterSection()

        // 设备列表
        this.deviceListSection()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BG_PRIMARY)

      LoadingOverlay({ isLoading: this.isLoading, message: '加载设备...' })
    }
  }

  @Builder
  private statsSection() {
    Row({ space: 12 }) {
      StatCard({
        title: '设备总数',
        value: this.totalCount.toString(),
        icon: '🏭',
        accentColor: AppColors.PRIMARY
      })
        .layoutWeight(1)

      StatCard({
        title: '工作中',
        value: this.workingCount.toString(),
        icon: '⚡',
        accentColor: AppColors.SUCCESS
      })
        .layoutWeight(1)

      StatCard({
        title: '待机',
        value: this.standbyCount.toString(),
        icon: '⏸️',
        accentColor: AppColors.WARNING
      })
        .layoutWeight(1)

      StatCard({
        title: '已锁定',
        value: this.lockedCount.toString(),
        icon: '🔒',
        accentColor: AppColors.DANGER
      })
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 8 })
  }

  @Builder
  private filterSection() {
    Column({ space: 12 }) {
      // 搜索框
      Row() {
        Text('🔍')
          .fontSize(18)
          .margin({ left: 12 })

        TextInput({ placeholder: '搜索设备名称、地址或ID', text: this.searchText })
          .layoutWeight(1)
          .height(44)
          .backgroundColor('transparent')
          .placeholderColor(AppColors.TEXT_TERTIARY)
          .fontColor(AppColors.TEXT_PRIMARY)
          .fontSize(AppTypography.SIZE_BODY)
          .onChange((value) => {
            this.searchText = value;
          })
      }
      .width('100%')
      .backgroundColor(AppColors.BG_SECONDARY)
      .borderRadius(12)
      .border({ width: 1, color: AppColors.BORDER })

      // 筛选标签
      Row({ space: 8 }) {
        this.filterChip('全部', -1)
        this.filterChip('工作中', DeviceStatus.WORKING)
        this.filterChip('待机', DeviceStatus.STANDBY)
        this.filterChip('离线', DeviceStatus.OFFLINE)
        this.filterChip('已锁定', 3)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  private filterChip(label: string, status: number) {
    Text(label)
      .fontSize(AppTypography.SIZE_CAPTION)
      .fontColor(this.filterStatus === status ? AppColors.TEXT_ON_PRIMARY : AppColors.TEXT_SECONDARY)
      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      .backgroundColor(this.filterStatus === status ? AppColors.PRIMARY : AppColors.BG_TERTIARY)
      .borderRadius(16)
      .onClick(() => {
        this.filterStatus = status;
      })
  }

  @Builder
  private deviceListSection() {
    Refresh({ refreshing: $$this.isRefreshing }) {
      List({ space: 12 }) {
        ForEach(this.getFilteredDevices(), (device: DeviceModel) => {
          ListItem() {
            DeviceCard({
              deviceId: device.id,
              deviceName: device.name,
              address: device.address,
              status: device.status,
              workCount: device.workCount,
              isLocked: device.isLocked,
              onCardClick: () => this.navigateToDetail(device)
            })
          }
        }, (device: DeviceModel) => device.id)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 8, bottom: 16 })
      .edgeEffect(EdgeEffect.Spring)
      .listDirection(Axis.Vertical)
    }
    .onRefreshing(() => {
      this.loadDevices();
    })
    .layoutWeight(1)
  }
}
