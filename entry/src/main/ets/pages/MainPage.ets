import { router, promptAction } from '@kit.ArkUI';
import { DeviceModel, DeviceDao, DeviceStatus, UserDao } from 'datastore';
import { AuthManager, TimerManager, Constants, DeviceRefreshCoordinator, DeviceRefreshEvent } from 'utils';
import { AppColors, AppTypography, DeviceCard, StatCard, LoadingOverlay } from 'uikit';
import { MapPage } from 'map';

/**
 * 主页面 - 底部导航
 */
@Entry
@Component
struct MainPage {
  @State private currentTabIndex: number = 0;
  @State private devices: DeviceModel[] = [];
  @State private isLoading: boolean = true;
  @State private isRefreshing: boolean = false;
  @State private filterStatus: number = -1;
  @State private searchText: string = '';
  @State private hasShownLoadError: boolean = false;
  @State private totalCount: number = 0;
  @State private workingCount: number = 0;
  @State private standbyCount: number = 0;
  @State private lockedCount: number = 0;

  private tabController: TabsController = new TabsController();
  private readonly refreshListenerKey: string = 'main_page_device_refresh';
  private lastHandledRefreshVersion: number = 0;

  aboutToAppear(): void {
    this.subscribeToRefreshEvents();
    const hasPendingRefresh = this.syncPendingDeviceRefresh();
    if (!hasPendingRefresh) {
      void this.loadDevices();
    }
    this.startAutoRefresh();
  }

  aboutToDisappear(): void {
    TimerManager.getInstance().stopTimer('main_refresh');
    DeviceRefreshCoordinator.getInstance().unsubscribe(this.refreshListenerKey);
  }

  private async loadDevices(): Promise<void> {
    try {
      const allDevices = await DeviceDao.getInstance().getAllDevices();
      this.devices = allDevices;
      this.updateStats(allDevices);
      this.hasShownLoadError = false;
    } catch (error) {
      console.error('Failed to load devices:', error);
      if (!this.hasShownLoadError) {
        promptAction.showToast({ message: '加载设备失败，请检查后端服务', duration: 2000 });
        this.hasShownLoadError = true;
      }
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }

  private updateStats(devices: DeviceModel[]): void {
    this.totalCount = devices.length;
    this.workingCount = devices.filter((device: DeviceModel) => device.status === DeviceStatus.WORKING && !device.isLocked).length;
    this.standbyCount = devices.filter((device: DeviceModel) => device.status === DeviceStatus.STANDBY && !device.isLocked).length;
    this.lockedCount = devices.filter((device: DeviceModel) => device.isLocked).length;
  }

  private startAutoRefresh(): void {
    TimerManager.getInstance().startTimer(
      'main_refresh',
      () => this.loadDevices(),
      Constants.REFRESH_INTERVAL,
      false
    );
  }

  private subscribeToRefreshEvents(): void {
    DeviceRefreshCoordinator.getInstance().subscribe(this.refreshListenerKey, (event: DeviceRefreshEvent) => {
      void this.handleDeviceRefreshEvent(event);
    });
  }

  private syncPendingDeviceRefresh(): boolean {
    const latestVersion = DeviceRefreshCoordinator.getInstance().getVersion();
    if (latestVersion <= this.lastHandledRefreshVersion) {
      return false;
    }

    this.lastHandledRefreshVersion = latestVersion;
    this.isRefreshing = true;
    void this.loadDevices();
    return true;
  }

  private async handleDeviceRefreshEvent(event: DeviceRefreshEvent): Promise<void> {
    if (event.version <= this.lastHandledRefreshVersion) {
      return;
    }

    this.lastHandledRefreshVersion = event.version;
    this.isRefreshing = true;
    await this.loadDevices();
  }

  private getFilteredDevices(): DeviceModel[] {
    let filtered = this.devices;

    if (this.filterStatus >= 0) {
      if (this.filterStatus === 3) {
        filtered = filtered.filter((device: DeviceModel) => device.isLocked);
      } else {
        filtered = filtered.filter((device: DeviceModel) => device.status === this.filterStatus && !device.isLocked);
      }
    }

    const keyword = this.searchText.trim().toLowerCase();
    if (keyword) {
      filtered = filtered.filter((device: DeviceModel) =>
        device.name.toLowerCase().includes(keyword) ||
        device.address.toLowerCase().includes(keyword) ||
        device.id.toLowerCase().includes(keyword)
      );
    }

    return filtered;
  }

  private isAdmin(): boolean {
    return AuthManager.getInstance().canLockDevice();
  }

  private navigateToDetail(device: DeviceModel): void {
    router.pushUrl({
      url: 'pages/DeviceDetailPage',
      params: { deviceId: device.id }
    });
  }

  private navigateToCreateDevice(): void {
    router.pushUrl({ url: 'pages/CreateDevicePage' });
  }

  private handleLogout(): void {
    UserDao.getInstance().clearSession();
    AuthManager.getInstance().logout();
    TimerManager.getInstance().stopAllTimers();
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  build() {
    Stack() {
      Column() {
        Tabs({ barPosition: BarPosition.End, controller: this.tabController }) {
          TabContent() {
            this.monitorTab()
          }
          .tabBar(this.tabBarItem('监', '监控', 0))

          TabContent() {
            MapPage()
          }
          .tabBar(this.tabBarItem('图', '地图', 1))

          TabContent() {
            this.profileTab()
          }
          .tabBar(this.tabBarItem('我', '我的', 2))
        }
        .barMode(BarMode.Fixed)
        .barBackgroundColor(AppColors.BG_SECONDARY)
        .onChange((index: number) => {
          this.currentTabIndex = index;
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BG_PRIMARY)

      LoadingOverlay({ isLoading: this.isLoading, message: '正在同步设备数据' })
    }
  }

  @Builder
  private tabBarItem(icon: string, label: string, index: number) {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(14)
        .fontWeight(AppTypography.WEIGHT_BOLD)
        .fontColor(this.currentTabIndex === index ? AppColors.PRIMARY : AppColors.TEXT_TERTIARY)
        .width(26)
        .height(26)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.currentTabIndex === index ? AppColors.PRIMARY + '12' : 'transparent')
        .borderRadius(13)

      Text(label)
        .fontSize(AppTypography.SIZE_SMALL)
        .fontColor(this.currentTabIndex === index ? AppColors.PRIMARY : AppColors.TEXT_TERTIARY)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  private monitorTab() {
    Column({ space: 12 }) {
      Column({ space: 16 }) {
        Row() {
          Column({ space: 6 }) {
            Text('设备管理')
              .fontSize(AppTypography.SIZE_HEADLINE)
              .fontWeight(AppTypography.WEIGHT_BOLD)
              .fontColor(AppColors.TEXT_PRIMARY)

            Text('查看设备状态，搜索设备，并由管理员新增设备。')
              .fontSize(AppTypography.SIZE_CAPTION)
              .fontColor(AppColors.TEXT_SECONDARY)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Row({ space: 8 }) {
            this.actionChip('刷新', false, () => {
              this.isRefreshing = true;
              void this.loadDevices();
            })

            if (this.isAdmin()) {
              this.actionChip('新增设备', true, () => this.navigateToCreateDevice())
            }
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Row({ space: 10 }) {
          StatCard({ title: '设备总数', value: this.totalCount.toString(), icon: 'ALL', accentColor: AppColors.PRIMARY })
            .layoutWeight(1)
          StatCard({ title: '运行中', value: this.workingCount.toString(), icon: 'RUN', accentColor: AppColors.SUCCESS })
            .layoutWeight(1)
        }
        .width('100%')

        Row({ space: 10 }) {
          StatCard({ title: '待机', value: this.standbyCount.toString(), icon: 'STB', accentColor: AppColors.WARNING })
            .layoutWeight(1)
          StatCard({ title: '已锁定', value: this.lockedCount.toString(), icon: 'LCK', accentColor: AppColors.DANGER })
            .layoutWeight(1)
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 18 })

      Column({ space: 12 }) {
        Row({ space: 10 }) {
          Text('搜索')
            .fontSize(AppTypography.SIZE_CAPTION)
            .fontColor(AppColors.TEXT_TERTIARY)

          TextInput({ placeholder: '搜索设备编号或位置', text: this.searchText })
            .layoutWeight(1)
            .height(44)
            .backgroundColor('transparent')
            .placeholderColor(AppColors.TEXT_TERTIARY)
            .fontColor(AppColors.TEXT_PRIMARY)
            .fontSize(AppTypography.SIZE_BODY)
            .caretColor(AppColors.PRIMARY)
            .onChange((value: string) => {
              this.searchText = value;
            })
        }
        .width('100%')
        .padding({ left: 14, right: 14 })
        .backgroundColor(AppColors.BG_SECONDARY)
        .borderRadius(16)
        .border({ width: 1, color: AppColors.BORDER })

        Scroll() {
          Row({ space: 8 }) {
            this.filterChip('全部', -1)
            this.filterChip('运行中', DeviceStatus.WORKING)
            this.filterChip('待机', DeviceStatus.STANDBY)
            this.filterChip('离线', DeviceStatus.OFFLINE)
            this.filterChip('已锁定', 3)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

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
          }, (device: DeviceModel) => device.id + device.updatedAt)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, bottom: 20 })
        .edgeEffect(EdgeEffect.Spring)
      }
      .onRefreshing(() => {
        void this.loadDevices();
      })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private actionChip(label: string, isPrimary: boolean, onClick: () => void) {
    Text(label)
      .fontSize(AppTypography.SIZE_CAPTION)
      .fontWeight(AppTypography.WEIGHT_MEDIUM)
      .fontColor(isPrimary ? AppColors.TEXT_ON_PRIMARY : AppColors.TEXT_PRIMARY)
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .backgroundColor(isPrimary ? AppColors.PRIMARY : AppColors.BG_SECONDARY)
      .borderRadius(16)
      .border({ width: isPrimary ? 0 : 1, color: AppColors.BORDER })
      .onClick(onClick)
  }

  @Builder
  private filterChip(label: string, status: number) {
    Text(label)
      .fontSize(AppTypography.SIZE_CAPTION)
      .fontColor(this.filterStatus === status ? AppColors.TEXT_ON_PRIMARY : AppColors.TEXT_SECONDARY)
      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      .backgroundColor(this.filterStatus === status ? AppColors.PRIMARY : AppColors.BG_SECONDARY)
      .borderRadius(999)
      .border({ width: this.filterStatus === status ? 0 : 1, color: AppColors.BORDER })
      .onClick(() => {
        this.filterStatus = status;
      })
  }

  @Builder
  private profileTab() {
    Column({ space: 16 }) {
      Column({ space: 16 }) {
        Row() {
          Text(AuthManager.getInstance().getCurrentUsername().slice(0, 1).toUpperCase() || 'U')
            .fontSize(AppTypography.SIZE_TITLE)
            .fontWeight(AppTypography.WEIGHT_BOLD)
            .fontColor(AppColors.TEXT_ON_PRIMARY)
        }
        .width(72)
        .height(72)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(AppColors.PRIMARY)
        .borderRadius(36)

        Text(AuthManager.getInstance().getCurrentUsername())
          .fontSize(AppTypography.SIZE_TITLE)
          .fontWeight(AppTypography.WEIGHT_BOLD)
          .fontColor(AppColors.TEXT_PRIMARY)

        Text(this.isAdmin() ? '管理员账号' : '普通账号')
          .fontSize(AppTypography.SIZE_CAPTION)
          .fontColor(this.isAdmin() ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(this.isAdmin() ? AppColors.PRIMARY + '12' : AppColors.BG_TERTIARY)
          .borderRadius(999)
      }
      .width('100%')
      .padding(24)
      .backgroundColor(AppColors.BG_SECONDARY)
      .borderRadius(24)
      .border({ width: 1, color: AppColors.BORDER })
      .alignItems(HorizontalAlign.Center)

      Column({ space: 1 }) {
        this.menuItem('当前会话', this.isAdmin() ? '管理员写操作已启用' : '仅支持查看设备')
        this.menuItem('刷新频率', `${Constants.REFRESH_INTERVAL / 1000} 秒`)
      }
      .width('100%')
      .backgroundColor(AppColors.BG_SECONDARY)
      .borderRadius(20)
      .border({ width: 1, color: AppColors.BORDER })

      Text('退出登录')
        .fontSize(AppTypography.SIZE_BODY)
        .fontWeight(AppTypography.WEIGHT_MEDIUM)
        .fontColor(AppColors.DANGER)
        .width('100%')
        .height(52)
        .textAlign(TextAlign.Center)
        .backgroundColor(AppColors.BG_SECONDARY)
        .borderRadius(16)
        .border({ width: 1, color: AppColors.BORDER })
        .onClick(() => this.handleLogout())

      Blank()
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 32, bottom: 20 })
  }

  @Builder
  private menuItem(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(AppTypography.SIZE_BODY)
        .fontColor(AppColors.TEXT_PRIMARY)

      Text(value)
        .fontSize(AppTypography.SIZE_CAPTION)
        .fontColor(AppColors.TEXT_SECONDARY)
    }
    .width('100%')
    .height(54)
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.SpaceBetween)
  }
}
