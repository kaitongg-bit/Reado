# 独立开发者常见做法：Contact / Terms / Privacy

## 大家一般怎么做

1. **弹窗（本项目）**  
   用户协议、隐私政策通过 **`LegalPopups`** 以 **Dialog** 展示（官网底部入口），**未登录也可打开**（应用商店审核、信任感）。  
   **联系我们**与 **设置里「联系我们」为同一套表单**，提交到 Firestore **`feedback`** 集合，便于在控制台查看；**不再单独做「支持」入口**（与联系重复）。

2. **联系 / 反馈**  
   - 客户端：`ContactFeedbackDialog`（`lib/features/feedback/presentation/contact_feedback_dialog.dart`），`FirestoreService.submitFeedback`。  
   - 可选字段 **`source`**：`landing`（官网底栏）、`profile`（设置页），便于区分入口。  
   - 未登录用户也可提交；建议在表单「联系方式」中填写邮箱/微信以便回复。  
   - 若仍需要对外展示邮箱（商店、官网文案），可保留 **`lib/core/constants/support_contact_constants.dart`**。

3. **Terms & Privacy**  
   - 早期用 **简短自写模板**（服务范围、内测免责声明、用户内容、AI 免责、数据与第三方、儿童条款等）即可。  
   - 融资金额大或出海合规要求高时，再请 **律师** 基于模板润色。  
   - 文末保留「**不构成法律意见**」类提示（应用内已有一句摘要 Disclaimer）。

4. **与「关于 / 功能说明」分工**  
   - **关于页**（`/profile/about`）：产品介绍、怎么用、积分说明。  
   - **联系 / 条款 / 隐私**：合规与信任；官网底部通过弹窗打开。

## 本仓库对应文件

| 能力 | 入口 | 实现 |
|------|------|------|
| 联系我们（写 Firestore） | 官网底栏「联系我们」、设置 → 联系我们 | `LegalPopups.showContactFeedbackDialog` / `ContactFeedbackDialog`；`submitFeedback` 见 `lib/data/services/firestore_service.dart` |
| 用户协议 | 官网底部 Terms | `LegalPopups.showTermsDialog` |
| 隐私政策 | 官网底部 Privacy | `LegalPopups.showPrivacyDialog` |
| 条款与隐私文案 | — | `lib/l10n/legal_support_strings.dart` |

**安全规则**：`firestore.rules` 中 `match /feedback/{docId}` 允许 **create**（含未登录），**禁止客户端 read/update/delete**；部署：`firebase deploy --only firestore:rules`（若使用命名库 `reado`，与项目现有规则文件一致即可）。

路由白名单不再包含已删除的法律独立页路径。
