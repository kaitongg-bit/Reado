# 小红书内容提取增强功能

## 📋 概述

QuickPM 现已支持通过 **XHS-Downloader** 项目增强小红书内容提取功能。

## 🎯 功能特性

- ✅ 提取小红书笔记标题、正文、作者信息
- ✅ 识别图片和视频内容
- ✅ 提取标签信息
- ✅ 无水印内容下载（需额外配置）
- ✅ 支持多种链接格式

## 🔧 部署方式

### 方案 1：本地部署（推荐开发测试）

#### 步骤 1：克隆 XHS-Downloader

```bash
cd ~/Desktop
git clone https://github.com/JoeanAmier/XHS-Downloader
cd XHS-Downloader
```

#### 步骤 2：安装依赖

```bash
pip install -r requirements.txt
```

#### 步骤 3：启动 API 服务

```bash
python main.py api
```

服务将在 `http://127.0.0.1:5556` 启动。

#### 步骤 4：验证服务

打开浏览器访问：
- API 文档：http://127.0.0.1:5556/docs
- 备用文档：http://127.0.0.1:5556/redoc

#### 步骤 5：在 QuickPM 中使用

1. 确保 XHS-Downloader API 服务正在运行
2. 打开 QuickPM 的 AddMaterialModal
3. 切换到"多模态 (AI)"标签
4. 粘贴小红书链接（支持格式见下方）
5. 点击"提取并生成知识卡片"

QuickPM 会自动检测并尝试使用 XHS-Downloader API，如果不可用则回退到 Jina Reader。

### 方案 2：云服务器部署（推荐生产环境）

#### 部署到云服务器

```bash
# SSH 登录服务器
ssh user@your-server.com

# 克隆并部署
git clone https://github.com/JoeanAmier/XHS-Downloader
cd XHS-Downloader
pip install -r requirements.txt

# 使用 systemd 或 supervisor 保持服务运行
nohup python main.py api &
```

#### 配置 QuickPM

在 QuickPM 设置中（待实现）：
- 设置自定义 API 地址：`http://your-server.com:5556/xhs/detail`

### 方案 3：Docker 部署

```bash
# 使用项目提供的 Docker 镜像
cd XHS-Downloader
docker-compose up -d
```

## 🔗 支持的链接格式

- `https://www.xiaohongshu.com/explore/作品ID?xsec_token=XXX`
- `https://www.xiaohongshu.com/discovery/item/作品ID?xsec_token=XXX`
- `https://www.xiaohongshu.com/user/profile/作者ID/作品ID?xsec_token=XXX`
- `https://xhslink.com/分享码`

## 🎬 工作流程

```
用户粘贴小红书链接
       ↓
QuickPM 检测链接类型
       ↓
   [小红书链接?]
       ↓ 是
尝试连接 XHS-Downloader API
       ↓
  [API 可用?]
   ↓        ↓
  是        否
   ↓        ↓
使用 API   使用 Jina Reader
提取内容   提取内容
   ↓        ↓
   └────┬───┘
        ↓
   提取成功的内容
        ↓
   传递给 Gemini AI
        ↓
   生成知识卡片
```

## ⚙️ 配置说明

### 默认配置

```dart
// lib/data/services/xiaohongshu_extractor.dart

static const String defaultApiUrl = 'http://127.0.0.1:5556/xhs/detail';
```

### 自定义配置（未来功能）

在 `settings.json` 或应用设置中：

```json
{
  "xiaohongshu": {
    "enabled": true,
    "api_url": "http://your-server.com:5556/xhs/detail",
    "timeout": 30
  }
}
```

## 🐛 故障排除

### 问题 1：API 连接失败

**症状**：提示"XHS-Downloader API 不可用"

**解决**：
1. 检查 API 服务是否运行：`ps aux | grep main.py`
2. 检查端口占用：`lsof -i:5556`
3. 访问 http://127.0.0.1:5556/docs 验证服务

### 问题 2：提取内容为空

**症状**：API 返回成功但内容为空

**解决**：
1. 检查小红书链接是否有效
2. 验证作品是否被删除或设置为私密
3. 查看 XHS-Downloader 日志

### 问题 3：Cookie 相关错误

**症状**：提示需要登录或 Cookie 失效

**解决**：
- XHS-Downloader v2.2+ 通常无需手动配置 Cookie
- 如遇问题，参考 [XHS-Downloader Cookie 配置文档](https://github.com/JoeanAmier/XHS-Downloader#-cookie)

## 📊 性能对比

| 方法 | 成功率 | 速度 | 内容完整性 |
|------|--------|------|-----------|
| XHS-Downloader API | 高 ~85% | 中等 (5-10s) | 高 ✅ |
| Jina Reader | 低 ~30% | 快 (2-5s) | 中等 |
| 手动复制粘贴 | 100% | 慢 | 取决于用户 |

## 🎉 最佳实践

1. **开发阶段**：使用本地 XHS-Downloader API
2. **个人使用**：保持本地 API 服务运行
3. **团队/生产**：部署到云服务器
4. **应急备选**：始终可以使用"文本导入"手动粘贴

## 📚 参考资源

- [XHS-Downloader GitHub](https://github.com/JoeanAmier/XHS-Downloader)
- [API 文档示例](http://127.0.0.1:5556/docs)
- [演示视频 (Bilibili)](https://www.bilibili.com/video/BV1Fcb3zWEjt/)

## ⚠️ 注意事项

1. XHS-Downloader 需要独立部署，不包含在 QuickPM 中
2. 使用时请遵守小红书服务条款
3. 建议仅用于个人学习目的
4. API 服务建议在本地网络中使用

## 🚀 下一步计划

- [ ] 在 QuickPM 设置中添加 API 地址配置
- [ ] 集成状态指示器（显示 API 是否可用）
- [ ] 支持批量链接提取
- [ ] 添加缓存机制减少 API 调用
