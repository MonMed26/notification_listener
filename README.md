# nl

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# 通知监听器 - 功能更新日志

## 卡片大小配置功能

### 功能描述
现在用户可以在设置页面调整大型通知卡片的显示大小，使其更符合个人阅读偏好。

### 具体变更
1. 在设置页面添加了卡片大小设置区域，包含：
   - 直观的滑块控件（范围：0.7-1.3，默认：1.0）
   - 实时预览效果展示
   - 大小标签（小、标准、大）

2. 新增功能实现：
   - 创建了 `SettingsService` 类用于存储和获取卡片大小设置
   - 修改了 `NotificationCard` 组件，添加了大小缩放功能
   - 在通知列表页面应用了用户设置的卡片大小

### 使用指南
1. 进入应用设置页面
2. 在"卡片大小设置"区域，拖动滑块调整大型卡片的显示大小
3. 通过预览区域实时查看调整效果
4. 设置会自动保存，并在通知列表中立即生效

### 技术细节
- 使用 `SharedPreferences` 存储用户设置的卡片大小
- 缩放比例为 0.7-1.3 之间，允许用户根据自己的阅读习惯进行调整
- 应用在所有使用大型卡片样式的界面
