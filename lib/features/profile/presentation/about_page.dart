import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../feed/presentation/feed_provider.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('关于 Reado'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(context, isDark),
            // ... (rest of the sections remain same, will rely on original code for middle parts,
            // but since I'm replacing the whole class structure in partial view, I must be careful)
            // Wait, I should not replace the whole build method if I can avoid it.
            // But I need to change the class signature.
            const SizedBox(height: 32),
            _buildSection(
              context,
              isDark,
              title: '1. 关于内容导入',
              items: [
                _buildSubItem(
                  '批量导入',
                  '手机端无法批量导入。我们建议用户前往电脑端进行批量操作，以获得更流畅的体验。',
                ),
                _buildSubItem(
                  '网页链接解析',
                  '可以放一些无需登录即可查看的链接，例如 YouTube 或其他公开网页。先点击“解析”按钮，确认解析成功后，再点击“AI 拆解”。',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              isDark,
              title: '2. 关于 AI 拆解功能',
              items: [
                _buildSubItem(
                  '文字玩法',
                  '除了通过 Markdown 方式（如使用井号分隔）直接导入文字外，还可以输入简短的问题，比如“AI 是什么”。点击“AI 拆解”后，系统会将问题拆解为多维度的知识卡。',
                ),
                _buildSubItem(
                  '囤囤鼠 AI',
                  '在阅读时，您可以随时与 AI 对话，并将对话内容中想要保存的部分整理起来。',
                ),
                _buildSubItem(
                  '笔记整理',
                  '您可以长按多选，批量选中与 AI 聊天的内容，一键将其整理成知识点笔记。',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              isDark,
              title: '3. 碎片化阅读体验',
              items: [
                _buildSubItem(
                  '沉浸式滑动',
                  '针对“不想重度学习”的心理，我们将每一个拆分出的知识点控制在较短的篇幅，降低阅读压力。',
                ),
                _buildSubItem(
                  '全屏学习',
                  '类似短视频的上下滑体验，非常适合在地铁或躺在床上等碎片化时间使用。',
                ),
                _buildSubItem(
                  '无需筛选',
                  '基于内容的信任，您不需要再去费力挑选，直接沉浸在全屏展开的知识中，上下滑动即可快速切换。',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              isDark,
              title: '4. 积分与内测说明',
              items: [
                _buildSubItem(
                  '计费规则',
                  '为了保障 AI 生成质量，【AI 智能拆解】将消耗 10-40 积分（视内容长度而定）。为了回馈内测用户，目前【AI 对话】以及【文件解析】功能暂不消耗积分。',
                ),
                _buildSubItem(
                  '如何获取积分',
                  '新用户注册即赠送 200 积分。此外，您可以通过分享您喜欢的知识库内容来免费赚取积分奖励。',
                ),
                _buildSubItem(
                  '支付与充值',
                  'Reado 目前处于公测/内测阶段，所有的 AI 资源均由我们免费提供信用额度。目前暂无任何支付入口，请勿相信任何付费充值信息。',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              isDark,
              title: '5. 如何像 App 一样使用',
              items: [
                _buildSubItem(
                  'iOS (iPhone/iPad)',
                  '在 Safari 浏览器中点击底部的【分享】按钮，向上滑动找到并点击【添加至主屏幕】，Reado 就会像 App 原生图标一样出现在你的桌面。',
                ),
                _buildSubItem(
                  'Android (安卓)',
                  '使用 Chrome 或主流浏览器打开，点击右上角【三个点】菜单，选择【安装应用】或【添加到主屏幕】。',
                ),
                _buildSubItem(
                  'PWA 优势',
                  '添加到主屏幕后，Reado 将拥有独立的沉浸式全屏界面，且加载速度更快，不会由于浏览器刷新而丢失上下文信息。',
                ),
              ],
            ),
            const SizedBox(height: 64),
            GestureDetector(
              onLongPress: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⚡️ 管理员模式：正在重置所有官方数据...')),
                );
                try {
                  await ref
                      .read(feedProvider.notifier)
                      .seedDatabase(force: true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ 官方数据已重置为最新版本 (STAR + Guide)'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ 失败: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Center(
                child: Text(
                  'Reado 2026 Inc',
                  style: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black12,
                    fontSize: 12,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFFFF8A65).withOpacity(0.15), Colors.transparent]
              : [const Color(0xFFFF8A65).withOpacity(0.1), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A65).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome,
                color: Color(0xFFFF8A65), size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Reado AI',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '让知识拆解变得像刷动态一样简单',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, bool isDark,
      {required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF8A65),
          ),
        ),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }

  Widget _buildSubItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $title',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
