import { mapCommon, map, MapComponent } from "@kit.MapKit";
import { geoLocationManager } from "@kit.LocationKit";
import { promptAction } from "@kit.ArkUI";
import { DeviceModel, DeviceDao, DeviceStatus } from "datastore";
import { TimerManager, Constants } from "utils";
import { AppColors, AppTypography, LoadingOverlay } from "uikit";

/**
 * 地图页面 - 显示所有设备位置
 */
@Component
export struct MapPage {
  @State private devices: DeviceModel[] = [];
  @State private isLoading: boolean = true;
  @State private selectedDevice: DeviceModel | null = null;
  @State private showDeviceInfo: boolean = false;
  @State private mapController: map.MapComponentController | undefined = undefined;
  @State private hasShownLoadError: boolean = false;
  private mapOptions?: mapCommon.MapOptions;

  aboutToAppear(): void {
    this.initMapOptions();
    this.loadDevices();
    this.startAutoRefresh();
  }

  aboutToDisappear(): void {
    TimerManager.getInstance().stopTimer("map_refresh");
  }

  private initMapOptions(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: Constants.MAP_DEFAULT_CENTER_LAT,
          longitude: Constants.MAP_DEFAULT_CENTER_LNG,
        },
        zoom: Constants.MAP_DEFAULT_ZOOM,
      },
    };
  }

  private onMapReady(controller: map.MapComponentController): void {
    this.mapController = controller;
    this.addDeviceMarkers();
  }

  private async loadDevices(): Promise<void> {
    try {
      this.devices = await DeviceDao.getInstance().getAllDevices();
      if (this.mapController) {
        this.addDeviceMarkers();
      }
      this.hasShownLoadError = false;
    } catch (error) {
      console.error("Failed to load devices:", error);
      if (!this.hasShownLoadError) {
        promptAction.showToast({ message: "加载地图数据失败，请检查后端服务", duration: 2000 });
        this.hasShownLoadError = true;
      }
    } finally {
      this.isLoading = false;
    }
  }

  private startAutoRefresh(): void {
    TimerManager.getInstance().startTimer(
      "map_refresh",
      () => this.loadDevices(),
      Constants.REFRESH_INTERVAL,
      false,
    );
  }

  private addDeviceMarkers(): void {
    if (!this.mapController) return;

    // 注意：实际Map Kit API可能需要调整
    // 这里展示概念性实现
    this.devices.forEach((device) => {
      try {
        let markerOptions: mapCommon.MarkerOptions = {
          position: {
            latitude: device.latitude,
            longitude: device.longitude,
          },
          title: device.name,
          snippet: device.address,
          clickable: true,
        };
        this.mapController?.addMarker(markerOptions);
      } catch (error) {
        console.error("Failed to add marker:", error);
      }
    });
  }

  private getStatusColor(device: DeviceModel): string {
    if (device.isLocked) return AppColors.DANGER;
    switch (device.status) {
      case DeviceStatus.WORKING:
        return AppColors.SUCCESS;
      case DeviceStatus.STANDBY:
        return AppColors.WARNING;
      default:
        return AppColors.TEXT_TERTIARY;
    }
  }

  build() {
    Stack() {
      Column() {
        // 顶部状态栏
        Row() {
          Text("设备分布地图")
            .fontSize(AppTypography.SIZE_TITLE)
            .fontWeight(AppTypography.WEIGHT_BOLD)
            .fontColor(AppColors.TEXT_PRIMARY)
          Row({ space: 16 }) {
            // 图例
            this.legendItem("工作中", AppColors.SUCCESS)
            this.legendItem("待机", AppColors.WARNING)
            this.legendItem("离线/锁定", AppColors.DANGER)
          }
        }
        .width("100%")
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor(AppColors.BG_SECONDARY)
        .justifyContent(FlexAlign.SpaceBetween)

        // 地图区域
        Stack() {
          if (this.mapOptions) {
            MapComponent({
              mapOptions: this.mapOptions,
              mapCallback: (err, controller) => {
                if (!err && controller) {
                  this.onMapReady(controller);
                }
              },
            })
              .width("100%")
              .height("100%");
          }

          // 设备信息浮窗
          if (this.showDeviceInfo && this.selectedDevice) {
            this.deviceInfoCard();
          }

          // 刷新按钮
          Column() {
            Row() {
              Text("🔄").fontSize(24)
            }
            .width(48)
            .height(48)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(AppColors.BG_SECONDARY)
            .borderRadius(24)
            .shadow({
              radius: 12,
              color: AppColors.SHADOW_COLOR,
              offsetX: 0,
              offsetY: 4,
            })
            .onClick(() => {
              this.isLoading = true;
              this.loadDevices();
            })
          }
          .position({ x: "85%", y: "80%" })
        }.layoutWeight(1)
      }
      .width("100%")
      .height("100%")
      .backgroundColor(AppColors.BG_PRIMARY)
      LoadingOverlay({ isLoading: this.isLoading, message: "加载地图..." })
    };
  }

  @Builder
  private legendItem(text: string, color: string) {
    Row({ space: 4 }) {
      Circle()
        .width(8)
        .height(8)
        .fill(color)
      Text(text)
        .fontSize(AppTypography.SIZE_SMALL)
        .fontColor(AppColors.TEXT_SECONDARY)
    };
  }

  @Builder
  private deviceInfoCard() {
    Column({ space: 8 }) {
      Row() {
        Text(this.selectedDevice!.name)
          .fontSize(AppTypography.SIZE_SUBTITLE)
          .fontWeight(AppTypography.WEIGHT_MEDIUM)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text("✕")
          .fontSize(20)
          .fontColor(AppColors.TEXT_TERTIARY)
          .onClick(() => {
            this.showDeviceInfo = false;
            this.selectedDevice = null;
          })
      }
      .width("100%")
      .justifyContent(FlexAlign.SpaceBetween)
      Text(this.selectedDevice!.address)
        .fontSize(AppTypography.SIZE_CAPTION)
        .fontColor(AppColors.TEXT_SECONDARY)
        .maxLines(2)
      Row() {
        Text(`工作数量: ${this.selectedDevice!.workCount}`)
          .fontSize(AppTypography.SIZE_CAPTION)
          .fontColor(AppColors.PRIMARY)
        Text(this.selectedDevice!.getStatusText())
          .fontSize(AppTypography.SIZE_SMALL)
          .fontColor(this.getStatusColor(this.selectedDevice!))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.getStatusColor(this.selectedDevice!) + "20")
          .borderRadius(10)
      }
      .width("100%")
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width("90%")
    .padding(16)
    .backgroundColor(AppColors.BG_SECONDARY)
    .borderRadius(12)
    .border({ width: 1, color: AppColors.BORDER })
    .shadow({
      radius: 16,
      color: AppColors.SHADOW_COLOR,
      offsetX: 0,
      offsetY: 8,
    })
    .position({ x: "5%", y: "70%" });
  }
}
