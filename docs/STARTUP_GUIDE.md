# QuickPM 启动指南 (iOS & Web)

本文档用于记录 QuickPM 项目在本地 Mac 电脑上的启动流程，包含 iOS 模拟器预览和 Web 预览两种方式。

## 📱 iOS 模拟器预览 (本地开发)

由于 iOS 模拟器需要 Xcode 环境和 Cocoapods 依赖支持（已配置完成），启动时需要确保模拟器已打开。

### **一键启动命令**
把下面这两行复制到终端运行即可：

```bash
open -a Simulator
flutter run
```

### **详细步骤**
1. **打开模拟器**：
   在终端输入 `open -a Simulator`，或者直接在 Mac 的 Launchpad 里找到 "Simulator" 图标点击打开。
   *(等待几秒，直到看到 iPhone 屏幕画面)*

2. **运行 App**：
   在终端输入：
   ```bash
   flutter run
   ```
   *(如果需要指定 Gemini Key，请使用带参数的命令，见下文)*

---

## 🔑 关于 Gemini API Key (重要)

目前项目通过**命令行参数**注入 API Key。如果你发现 AI 功能无法使用（提示 API Key 无效），请使用带 Key 的启动命令：

```bash
flutter run --dart-define=GEMINI_API_KEY=你的_Gemini_API_Key
```

**建议**：为了省去每次输入的麻烦，建议按照之前的对话，创建一个 `lib/core/secrets.dart` 并将 Key 写入其中。

---

## 🌐 Web 网页预览

如果你想在浏览器中查看效果，运行：

```bash
flutter run -d chrome --web-port 3000 --dart-define=GEMINI_API_KEY=你的_Gemini_API_Key
```

---

## 常见问题排查

**Q: 终端提示 `No supported devices found`？**
A: 你的模拟器没打开，或者没连接上。
1. 运行 `open -a Simulator` 确保看到手机画面。
2. 运行 `flutter devices` 查看是否识别到了 iPhone。

**Q: 启动时卡在 `Running pod install...` 很久？**
A: 第一次编译或者安装依赖会比较慢（可能需要几分钟），请耐心等待。只要不报错红字就没问题。

**Q: 报错 `CocoaPods not installed`？**
A: 环境配置可能丢了，运行以下命令修复：
```bash
export PATH="$HOME/.gem/ruby/4.0.0/bin:$PATH"
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
source ~/.zshrc
```
