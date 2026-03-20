# Microsoft Clarity 接入说明（Reado / Flutter Web）

## 你已做的

在 [Clarity](https://clarity.microsoft.com) 创建了项目，对应你的线上域名（例如 Firebase Hosting 的网址）。

## 你要做的（2 分钟）

1. 打开 **Clarity 控制台** → 选中你的项目 → **Setup（设置）**。
2. 页面会有一段安装代码，里面有一串 **Project ID**（在 `https://www.clarity.ms/tag/xxxxxxxx` 里，`xxxxxxxx` 就是 ID）。
3. 打开本仓库里的 **`web/index.html`**，找到：
   ```text
   "YOUR_CLARITY_PROJECT_ID"
   ```
   整段替换成你的真实 ID，例如：
   ```text
   "abcd1234ef"
   ```
   （保留引号，只改中间内容。）

4. 重新构建并部署 Web：
   ```bash
   flutter build web
   firebase deploy --only hosting
   ```
   （按你平时的部署命令来即可。）

5. 部署后用 **真实域名** 打开站点，在 Clarity 里等几分钟到几十分钟，就会出现会话与热图数据。

## 为什么没用 npm 的 `@microsoft/clarity`？

那个包是给 **Webpack / Vite 等前端工程** 在 JS 里 `import` 用的。  
Flutter Web 最终是 `index.html` + `flutter_bootstrap.js`，**在 `index.html` 里放官方脚本** 和 npm 包效果一样，也更省事。

## 邀请老板

Clarity 项目 → **Settings → Team**（或成员）→ 输入老板邮箱邀请即可。

## 隐私提示

Clarity 会录制页面交互。若页面有敏感输入框，可在 Clarity 后台配置 **Masking**，或在文档里说明使用了分析工具。
