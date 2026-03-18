# 正式发布前置清单

当前项目已经具备调试签名链路，可生成并安装测试用 `.hap` 包，但还不具备正式发布包所需的发布签名材料。

## 当前已具备

- 应用工程可正常构建并生成调试签名包
- 当前包名：`com.example.machine_control`
- 当前构建配置位于 `build-profile.json5`
- 当前 `default` 签名配置使用的是本机调试签名材料和 `debugKey`

## 正式发布仍需提供

- 与 `com.example.machine_control` 绑定的正式应用主体
- 正式发布证书材料：
  - 发布 `.p12`
  - 发布 `.cer`
  - 发布 `.p7b` / Profile
- 对应签名密码与别名
- 如果走 AppGallery Connect 分发：
  - 可访问的应用项目
  - 发布权限或协作者权限

## 后续接入位点

- 在 `build-profile.json5` 中新增独立的 `release` signingConfig
- `release` 配置必须引用正式发布材料
- `release` 构建不得复用当前 `debugKey`
- release 包构建完成后，需重新验证：
  - 签名类型
  - 安装行为
  - 真机启动
  - 登录与管理员功能

## 本轮交付说明

- 本轮仅产出“干净的调试测试包”
- 本轮不输出“正式发布包已完成”的结论
