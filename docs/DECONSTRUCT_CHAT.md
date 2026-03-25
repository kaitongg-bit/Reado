# 对话式 AI 拆解（Deconstruct Chat）

## 定位

- **主入口**：主页「AI 拆解」→ 路由 **`/deconstruct-chat`**（`lib/features/lab/presentation/deconstruct_chat_page.dart`）。
- **非向量 RAG**：本页是 **对话式编排**（Gemini JSON 编排回复 + 本地解析/扣费/提交），**不是**向量检索生成。
- **与任务中心**：提交成功后调用与弹窗相同的 `submitJobAndForget` + `feedProvider.observeJob`；用户可到 **`/task-center`** 看进度。

## 代码结构

| 组件 | 路径 |
|------|------|
| 对话页 UI | `lib/features/lab/presentation/deconstruct_chat_page.dart` |
| 路由 `extra` | `lib/features/lab/deconstruct/deconstruct_chat_route_args.dart` |
| 解析 / 耗时文案 / 扣费提交 | `lib/features/lab/deconstruct/deconstruct_flow_service.dart` |
| 知识库选择弹窗（兜底） | `lib/features/lab/deconstruct/deconstruct_module_picker.dart` |
| 对话编排（自然语言选库/风格/确认；人设 **囤囤鼠**） | `lib/features/lab/deconstruct/deconstruct_chat_orchestrator.dart` |
| 兜底表单（选库、风格、粘贴/链接/文件） | `lib/features/lab/deconstruct/deconstruct_fallback_form_sheet.dart` |
| 弹窗内扣费确认 + 风格 | `deconstruct_generation_confirm_dialog.dart`、`deconstruct_ai_mode_selector.dart`（**对话页不再使用确认弹窗**） |
| 对话文案（中英） | `lib/l10n/deconstruct_chat_strings.dart` |
| 旧高级弹窗（仍保留） | `lib/features/lab/presentation/add_material_modal.dart`（与上列组件共享选择器与确认弹窗） |

## 状态与安全

- **扣费前**：对话内先展示 **积分/耗时**（解析成功后客户端追加 `creditsFooter`）；**同一回合解析完成后不会提交**；用户下一轮用自然语言确认后，模型输出 `request_submit: true` 才调用 `submitDeconstructJob`。仍保留 **积分不足** 时的对话框。
- **教程**：`tutorialStep` / `isTutorialMode` 与 `onboarding_provider` 一致。

## 次要入口

- **模块详情**、**Feed** 内「添加内容」：`context.push('/deconstruct-chat', extra: DeconstructChatRouteArgs(targetModuleId: …))`。

## 演进（可选）

若需要「更像 RAG」：可把知识库标题列表、最近任务摘要等 **拼进 system 提示** 做轻量上下文；真 RAG 再引入向量索引。
