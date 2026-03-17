import { router, promptAction } from '@kit.ArkUI';
import { DeviceModel, DeviceDao, DeviceStatus } from 'datastore';
import { AuthManager, TimerManager, Constants } from 'utils';
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
  // 统计
  @State private totalCount: number = 0;
  @State private workingCount: number = 0;
  @State private standbyCount: number = 0;
  @State private lockedCount: number = 0;

  private tabController: TabsController = new TabsController();

  aboutToAppear(): void {
    this.loadDevices();
    this.startAutoRefresh();
  }

  aboutToDisappear(): void {
    TimerManager.getInstance().stopTimer('main_refresh');
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
    this.workingCount = devices.filter(d => d.status === DeviceStatus.WORKING && !d.isLocked).length;
    this.standbyCount = devices.filter(d => d.status === DeviceStatus.STANDBY && !d.isLocked).length;
    this.lockedCount = devices.filter(d => d.isLocked).length;
  }

  private startAutoRefresh(): void {
    TimerManager.getInstance().startTimer(
      'main_refresh',
      () => this.loadDevices(),
      Constants.REFRESH_INTERVAL,
      false
    );
  }

  private getFilteredDevices(): DeviceModel[] {
    let filtered = this.devices;

    if (this.filterStatus >= 0) {
      if (this.filterStatus === 3) {
        filtered = filtered.filter(d => d.isLocked);
      } else {
        filtered = filtered.filter(d => d.status === this.filterStatus && !d.isLocked);
      }
    }

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

  private handleLogout(): void {
    AuthManager.getInstance().logout();
    TimerManager.getInstance().stopAllTimers();
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  build() {
    Stack() {
      Column() {
        Tabs({ barPosition: BarPosition.End, controller: this.tabController }) {
          // 监控页
          TabContent() {
            this.monitorTab()
          }
          .tabBar(this.tabBarItem('📊', '监控', 0))

          // 地图页
          TabContent() {
            MapPage()
          }
          .tabBar(this.tabBarItem('🗺️', '地图', 1))

          // 我的页
          TabContent() {
            this.profileTab()
          }
          .tabBar(this.tabBarItem('👤', '我的', 2))
        }
        .barMode(BarMode.Fixed)
        .barBackgroundColor(AppColors.BG_SECONDARY)
        .onChange((index) => {
          this.currentTabIndex = index;
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.BG_PRIMARY)

      LoadingOverlay({ isLoading: this.isLoading, message: '加载中...' })
    }
  }

  @Builder
  private tabBarItem(icon: string, label: string, index: number) {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(24)

      Text(label)
        .fontSize(AppTypography.SIZE_SMALL)
        .fontColor(this.currentTabIndex === index ? AppColors.PRIMARY : AppColors.TEXT_TERTIARY)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  private monitorTab() {
    Column() {
      // 页面标题
      Row() {
        Text('设备监控')
          .fontSize(AppTypography.SIZE_HEADLINE)
          .fontWeight(AppTypography.WEIGHT_BOLD)
          .fontColor(AppColors.TEXT_PRIMARY)

        Row() {
          Text('🔄')
            .fontSize(20)
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(AppColors.BG_TERTIARY)
        .borderRadius(20)
        .onClick(() => {
          this.isRefreshing = true;
          this.loadDevices();
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })

      // 统计卡片
      Scroll() {
        Row({ space: 8 }) {
          StatCard({ title: '总数', value: this.totalCount.toString(), icon: '🏭', accentColor: AppColors.PRIMARY })
            .width(100)
          StatCard({ title: '工作中', value: this.workingCount.toString(), icon: '⚡', accentColor: AppColors.SUCCESS })
            .width(100)
          StatCard({ title: '待机', value: this.standbyCount.toString(), icon: '⏸️', accentColor: AppColors.WARNING })
            .width(100)
          StatCard({ title: '锁定', value: this.lockedCount.toString(), icon: '🔒', accentColor: AppColors.DANGER })
            .width(100)
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)

      // 搜索框
      Row() {
        Text('🔍')
          .fontSize(18)
          .margin({ left: 12 })

        TextInput({ placeholder: '搜索设备', text: this.searchText })
          .layoutWeight(1)
          .height(44)
          .backgroundColor('transparent')
          .placeholderColor(AppColors.TEXT_TERTIARY)
          .fontColor(AppColors.TEXT_PRIMARY)
          .onChange((value) => {
            this.searchText = value;
          })
      }
      .width('calc(100% - 32vp)')
      .margin({ left: 16, right: 16, top: 12 })
      .backgroundColor(AppColors.BG_SECONDARY)
      .borderRadius(12)
      .border({ width: 1, color: AppColors.BORDER })

      // 筛选
      Scroll() {
        Row({ space: 8 }) {
          this.filterChip('全部', -1)
          this.filterChip('工作中', DeviceStatus.WORKING)
          this.filterChip('待机', DeviceStatus.STANDBY)
          this.filterChip('离线', DeviceStatus.OFFLINE)
          this.filterChip('已锁定', 3)
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)

      // 设备列表
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
        .padding({ left: 16, right: 16, bottom: 16 })
        .edgeEffect(EdgeEffect.Spring)
      }
      .onRefreshing(() => {
        this.loadDevices();
      })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
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
  private profileTab() {
    Column() {
      // 用户信息
      Column({ space: 16 }) {
        Row() {
          Text('👤')
            .fontSize(48)
        }
        .width(80)
        .height(80)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(AppColors.PRIMARY + '20')
        .borderRadius(40)

        Text(AuthManager.getInstance().getCurrentUsername())
          .fontSize(AppTypography.SIZE_TITLE)
          .fontWeight(AppTypography.WEIGHT_BOLD)
          .fontColor(AppColors.TEXT_PRIMARY)

        Text(AuthManager.getInstance().canLockDevice() ? '管理员' : '普通用户')
          .fontSize(AppTypography.SIZE_CAPTION)
          .fontColor(AuthManager.getInstance().canLockDevice() ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(AuthManager.getInstance().canLockDevice() ? AppColors.PRIMARY + '20' : AppColors.BG_TERTIARY)
          .borderRadius(12)
      }
      .width('100%')
      .padding(32)
      .alignItems(HorizontalAlign.Center)

      // 功能列表
      Column({ space: 1 }) {
        this.menuItem('📱', '关于应用', () => { })
        this.menuItem('⚙️', '设置', () => { })
        this.menuItem('🔄', '刷新间隔', () => { })
      }
      .width('100%')
      .margin({ top: 16 })
      .backgroundColor(AppColors.BG_SECONDARY)
      .borderRadius(12)
      .margin({ left: 16, right: 16 })

      // 退出按钮
      Column() {
        Text('退出登录')
          .fontSize(AppTypography.SIZE_BODY)
          .fontColor(AppColors.DANGER)
          .width('100%')
          .height(52)
          .textAlign(TextAlign.Center)
          .backgroundColor(AppColors.BG_SECONDARY)
          .borderRadius(12)
          .onClick(() => this.handleLogout())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 32 })

      Blank()
    }
    .width('100%')
    .height('100%')
    .padding({ top: 60 })
  }

  @Builder
  private menuItem(icon: string, label: string, onClick: () => void) {
    Row() {
      Row({ space: 12 }) {
        Text(icon)
          .fontSize(20)
        Text(label)
          .fontSize(AppTypography.SIZE_BODY)
          .fontColor(AppColors.TEXT_PRIMARY)
      }

      Text('→')
        .fontSize(16)
        .fontColor(AppColors.TEXT_TERTIARY)
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.SpaceBetween)
    .onClick(onClick)
  }
}
