# 解决 iOS 网页版 Google 登录问题指南

您遇到的 "Value error" 或者是登录没反应，通常是因为以下两个原因之一：

## 1. 访问方式不正确（最常见）
**现象**：您是否是通过 IP 地址访问网页？（例如 `http://192.168.1.5:8080`）
**原因**：Google 安全策略**禁止**使用私有 IP 地址进行 OAuth 登录。
**解决方法**：
- **本地调试**：必须使用 `localhost`（但手机无法访问电脑的 localhost）。
- **手机测试**：
  1. 使用内网穿透工具（如 ngrok）生成一个 `https://xxxx.ngrok-free.app` 的域名。
  2. 或者将代码部署到 Vercel / Firebase Hosting，使用正式域名访问。

## 2. 域名未授权
**现象**：您已经有了域名（例如 `reado-app.com` 或 `reado.web.app`），但依然报错。
**原因**：该域名未在 Google Cloud Console 中注册为“已授权的 JavaScript 来源”。
**解决方法**：
1. 访问 [Google Cloud Console](https://console.cloud.google.com/apis/credentials)。
2. 选择您的项目（`reado-c8d21`）。
3. 找到 **Web client (auto created by Google Service)** 或类似的 OAuth 2.0 Client ID。
4. 在 **Authorized JavaScript origins**（已获授权的 JavaScript 来源）中，添加您的完整域名（包含 `https://` 和端口号，如果是 443 可省略）。
   - 例如：`https://reado.web.app`
   - 或者本地测试用的：`http://localhost:5000`

## 3. 代码已修复（自动重试）
我已经修改了 `lib/core/services/auth_service.dart`，增加了以下功能：
- **自动回退**：如果在 iOS 浏览器中“弹窗登录”被拦截或失败，代码会自动切换到“重定向登录”（Redirect Mode）。
- **结果检查**：在登录页初始化时，自动检查是否有重定向回来的登录结果。

### 接下来您需要做：
1. **重新打包/部署**您的网页版。
2. 确保使用 **域名** 而不是 IP 地址访问。
3. 如果是在 Safari 中，留意地址栏是否显示“已拦截弹窗”，不过新的代码应该能自动绕过这个问题。
