# ClipSync iOS 键盘

主 App 前台收录文本后，通过 `syncKeyboardTexts` 原子写入 App Group 中的 `keyboard-texts.json`。键盘读取最近 200 条文本快照，支持全部、文本和收藏分类；点击卡片调用 `textDocumentProxy.insertText`，不读取宿主聊天内容、不自动发送、不写入剪贴板。

## 启用

先打开主 App 保存文本，然后在 iOS 设置 → 通用 → 键盘 → 键盘 → 添加新键盘中选择 ClipSync。在聊天输入框长按地球图标切换到 ClipSync。安全输入框或禁止第三方键盘的 App 不会显示此键盘。

键盘仅只读共享容器，`RequestsOpenAccess` 为 false。首版不包含键盘搜索、图片或文件插入。

## 真机签名

Runner 和 ClipSyncKeyboard 两个 target 必须属于同一开发团队，并在开发者账号注册、为两者启用同一 App Group：`group.com.lefu.xinxx.clipsync`。仓库已配置两个 target 的 entitlements；真机 provisioning profile 还需支持该 App Group。

扩展 Bundle ID 为 `com.lefu.xinxx.ClipSyncKeyboard`，依附于目前主 App 的 `com.lefu.xinxx`。更换主 App Bundle ID 时应同步修改扩展 ID、App Group entitlement，以及 Swift 中的共享组标识。

发布时保持扩展的 MARKETING_VERSION / CURRENT_PROJECT_VERSION 与主 App 版本一致。
