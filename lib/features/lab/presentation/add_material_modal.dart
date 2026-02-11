import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../models/feed_item.dart';
import '../../../../data/services/content_extraction_service.dart';
import '../../feed/presentation/feed_provider.dart';
import '../providers/batch_import_provider.dart';
import '../../../../core/providers/credit_provider.dart';
import '../../../../core/providers/ai_settings_provider.dart';
import '../../../../core/router/router_provider.dart';

import '../../onboarding/providers/onboarding_provider.dart';
import '../../home/presentation/module_provider.dart';
import '../../../../models/knowledge_module.dart'; // Import KnowledgeModule
import 'widgets/tutorial_pulse.dart';

class AddMaterialModal extends ConsumerStatefulWidget {
  final String? targetModuleId;
  final bool isTutorialMode; // New parameter

  const AddMaterialModal({
    super.key,
    this.targetModuleId,
    this.isTutorialMode = false,
  });

  @override
  ConsumerState<AddMaterialModal> createState() => _AddMaterialModalState();
}

class _AddMaterialModalState extends ConsumerState<AddMaterialModal>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  late TabController _tabController; // Critical for tutorial control

  bool _isGenerating = false;
  bool _isExtractingUrl = false;

  ExtractionResult? _extractionResult; // 存储提取结果
  List<FeedItem>? _generatedItems;
  String? _error;
  String? _urlError;

  String? _pickedFileName; // New: For storing picked file name
  PlatformFile? _pickedFile; // Holds the actual file object

  // 流式生成状态
  String? _streamingStatus; // 当前状态消息
  int? _totalCards; // 总卡片数
  int? _currentCardIndex; // 当前生成的卡片索引

  // Tutorial State
  bool _tutorialStep1Complete = false;

  // Knowledge Base Selection State
  String? _selectedModuleId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize with target module if provided
    _selectedModuleId = widget.targetModuleId;

    if (widget.isTutorialMode) {
      _initTutorialStats();
    }

    // Attempt to auto-select default if none provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedModuleId == null) {
        _autoSelectDefaultModule();
      }
    });
  }

  void _autoSelectDefaultModule() {
    final moduleState = ref.read(moduleProvider);
    final allModules = [...moduleState.custom, ...moduleState.officials];
    if (allModules.isNotEmpty) {
      // Try to find "默认知识库" or just take the first one
      try {
        final defaultMod = allModules.firstWhere((m) => m.title == '默认知识库',
            orElse: () => allModules.first);
        setState(() {
          _selectedModuleId = defaultMod.id;
        });
      } catch (_) {
        if (allModules.isNotEmpty) {
          setState(() {
            _selectedModuleId = allModules.first.id;
          });
        }
      }
    }
  }

  void _initTutorialStats() {
    // 1. Select a random interesting topic
    final examples = [
      '# 美颜滤镜是如何工作的？\n\n美颜相机的核心技术其实是计算机视觉（Computer Vision）。\n\n1. 人脸检测：首先，算法需要在图像中找到人脸的位置（Face Detection）。通常使用基于深度学习的模型，如 MTCNN 或 RetinaFace，能快速定位五官的 68 个或 106 个关键点。\n\n2. 磨皮（Skin Smoothing）：定位到皮肤区域后，使用“双边滤波”（Bilateral Filter）或“导向滤波”算法。这些算法能模糊皮肤的细节（如痘印、毛孔），但同时保留边缘信息（如五官轮廓），避免整张脸变得模糊不清。\n\n3. 瘦脸大眼：利用三角剖分（Delaunay Triangulation）将人脸网格化，然后对特定的网格顶点进行位移（Warping）。例如，将眼睛周围的网格向外拉伸实现“大眼”，将下巴两侧的网格向内收缩实现“瘦脸”。',
      '# 为什么抖音知道你喜欢看什么？\n\n这背后的核心是“推荐系统”（Recommendation System）。\n\n1. 用户画像（User Profiling）：系统会记录你的每一个行为——停留时长、点赞、评论、转发，甚至是你哪怕快速划过的动作。这些数据被贴上成千上万个标签：喜欢猫咪、并在深夜活跃、偏好快节奏剪辑等。\n\n2. 协同过滤（Collaborative Filtering）：\n- 基于用户：既然你和隔壁老王都喜欢看“科技评测”，那老王刚点赞的“AI 教程”大概率你也喜欢。\n- 基于物品：既然喜欢看“Python入门”，那你可能对“数据分析”也感兴趣。\n\n3. 探索与利用（E&E）：系统不会只给你推你喜欢的（利用），偶尔会塞一些新领域的视频（探索），以免你陷入“信息茧房”感到无聊。',
      '# 什么是“第一性原理”？\n\n第一性原理（First Principles）是一种思维方式，最早由亚里士多德提出，后来被伊隆·马斯克带火。\n\n它的核心是：\n不要用“类比”去思考（“别人怎么做，我也怎么做”），而是要回归到事物最基本的条件（“本质是什么”），然后从头开始推演。\n\n举个例子：\n大家都觉得电动车电池太贵，大概 600 美元/千瓦时。类比思维会说：“电池一直都这么贵，没法降。”\n\n但第一性原理会问：\n1. 电池是由什么组成的？（钴、镍、铝、碳、聚合物...）\n2. 这些材料在伦敦金属交易所买可以多便宜？（大概 80 美元/千瓦时）\n\n结论：电池之所以贵，不是材料贵，而是组合方式（制造技术）太落后。只要改进制造流程，成本就能大幅下降。'
    ];
    // Simple random pick based on time to vary it slightly
    final index = DateTime.now().millisecondsSinceEpoch % examples.length;
    _textController.text = examples[index];

    // 2. Pre-select Default KB (Logic handled in generation step mostly, keeping UI clean)
  }

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // --- Legacy / Helper Wrappers ---

  /// Opens a dialog to select a module, and updates _selectedModuleId
  Future<void> _showModuleSelectionDialog() async {
    try {
      final moduleState = ref.read(moduleProvider);
      final allModules = [...moduleState.custom, ...moduleState.officials];

      // Ensure default placeholder if empty
      if (allModules.isEmpty) {
        // ... default creation logic ...
      }

      final selected = await showDialog<String>(
          context: context,
          builder: (context) {
            String? tempId = _selectedModuleId ??
                (allModules.isNotEmpty ? allModules.first.id : null);
            return StatefulBuilder(builder: (context, setState) {
              return AlertDialog(
                  title: const Text('选择知识库'),
                  content: SizedBox(
                      width: double.maxFinite,
                      height: 300,
                      child: Column(children: [
                        const Text('请选择存储位置：',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 12),
                        Expanded(
                            child: ListView.separated(
                                itemCount: allModules.length,
                                separatorBuilder: (ctx, i) =>
                                    const Divider(height: 1),
                                itemBuilder: (ctx, i) {
                                  final mod = allModules[i];
                                  final isSelected = mod.id == tempId;
                                  return InkWell(
                                      onTap: () =>
                                          setState(() => tempId = mod.id),
                                      child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 8),
                                          decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Theme.of(context)
                                                      .primaryColor
                                                      .withOpacity(0.1)
                                                  : null,
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: Row(children: [
                                            Icon(
                                                mod.isOfficial
                                                    ? Icons.verified
                                                    : Icons.folder,
                                                color: isSelected
                                                    ? Theme.of(context)
                                                        .primaryColor
                                                    : Colors.grey,
                                                size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                                child: Text(mod.title,
                                                    style: TextStyle(
                                                        fontWeight: isSelected
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                        color: isSelected
                                                            ? Theme.of(context)
                                                                .primaryColor
                                                            : null))),
                                            if (isSelected)
                                              const Icon(Icons.check,
                                                  color: Colors.green, size: 18)
                                          ])));
                                }))
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, tempId),
                        child: const Text('确定')),
                  ]);
            });
          });

      if (selected != null) {
        setState(() {
          _selectedModuleId = selected;
        });
      }
    } catch (e) {
      print('Error in selection dialog: $e');
    }
  }

  Widget _buildKbSelector(bool isDark) {
    final moduleState = ref.watch(moduleProvider);
    final allModules = [...moduleState.custom, ...moduleState.officials];

    String displayTitle = '点击选择知识库';
    if (_selectedModuleId != null) {
      final mod = allModules.firstWhere((m) => m.id == _selectedModuleId,
          orElse: () => KnowledgeModule(
              id: '?',
              title: '未知知识库',
              ownerId: '',
              isOfficial: false,
              cardCount: 0,
              description: ''));
      if (mod.id != '?') {
        displayTitle = mod.title;
      } else if (_selectedModuleId == 'unknown_default') {
        displayTitle = '默认知识库';
      }
    }

    final borderColor = isDark ? Colors.white12 : Colors.grey.withOpacity(0.2);
    final bgColor =
        isDarkFactory(isDark) ? Colors.white.withOpacity(0.05) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: _showModuleSelectionDialog,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.save_alt,
                  size: 18,
                  color: isDark ? Colors.grey[400] : Colors.grey[600]),
              const SizedBox(width: 8),
              Text('存储至: ',
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600])),
              Expanded(
                child: Text(
                  displayTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFee8f4b)
                        : const Color(0xFFF97316), // Orange accent
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 18,
                  color: isDark ? Colors.grey[600] : Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  bool isDarkFactory(bool isDark) => isDark; // Helper

  /// AI 智能拆解 - 文本模式
  Future<void> _generate() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // --- TUTORIAL LOGIC FOR STEP 1 ---
    if (widget.isTutorialMode && !_tutorialStep1Complete) {
      if (mounted) {
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('🎉 文本拆解任务已提交！后台正在处理...'),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ));

        setState(() {
          _tutorialStep1Complete = true; // Mark step 1 done
        });

        // Auto-switch to next tab after a short delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _tabController.animateTo(1);
            // Pre-fill URL
            _urlController.text =
                'https://example.com/flutter-architecture-guide';
            // Show hint dialog or toast
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('👇 下一步：试试解析这个链接 (消耗 0 积分)'),
              backgroundColor: Colors.blueAccent,
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ));
          }
        });
      }
      return; // STOP HERE for tutorial
    }
    // ---------------------------------

    final charCount = text.length;
    final credits =
        ContentExtractionService.calculateRequiredCredits(charCount);
    // ... rest of normal logic ...

    // For normal flow, verify credits etc.
    final estTime = _calculateEstimatedTime(charCount);
    final confirm =
        await _showGenerationConfirmDialog(credits, estTime, charCount);
    if (confirm != true) return;

    try {
      setState(() {
        _isGenerating = true;
        _streamingStatus = '正在提交任务...';
      });

      // Use centralized helper to resolve the actual moduleId (ensuring we respect _selectedModuleId)
      final resolvedModuleId = await _ensureTargetModuleId();
      if (resolvedModuleId == null)
        return; // User cancelled if dialog was shown

      final canUse =
          await ref.read(creditProvider.notifier).useAI(amount: credits);
      if (!canUse) {
        if (mounted) _showInsufficientCreditsDialog();
        return;
      }

      final jobId = await ContentExtractionService.submitJobAndForget(
        text,
        moduleId: resolvedModuleId,
        mode: ref.read(aiSettingsProvider).mode,
      );

      ref.read(feedProvider.notifier).observeJob(jobId);

      if (mounted) {
        Navigator.of(context).pop();
        _showTaskSubmittedSnackbar();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isGenerating = false;
        _streamingStatus = null;
      });
    }
  }

  void _showTaskSubmittedSnackbar() {
    // ... existing implementation ...
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;
    final router = ref.read(routerProvider);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('任务已提交！AI 正在后台生成，完成后自动保存'),
            ),
          ],
        ),
        backgroundColor: Colors.green[800],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '查看进度',
          textColor: Colors.white,
          onPressed: () {
            router.push('/task-center');
          },
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'md', 'txt'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 10 * 1024 * 1024) {
          throw Exception('文件大小不能超过 10MB');
        }

        setState(() {
          _pickedFile = file;
          _pickedFileName = file.name;
          _urlController.clear();
          _error = null;
          _urlError = null;
          _extractionResult = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '选择文件失败: ${e.toString()}';
      });
    }
  }

  /// 2. 统一解析入口 (URL 或 File)
  Future<void> _performParse() async {
    // --- TUTORIAL MOCK PARSE ---
    if (widget.isTutorialMode && _urlController.text.isNotEmpty) {
      setState(() {
        _isExtractingUrl = true;
      });
      await Future.delayed(const Duration(seconds: 2)); // Fake delay

      if (mounted) {
        setState(() {
          _isExtractingUrl = false;
          _extractionResult = ExtractionResult(
            content:
                'Flutter 架构指南\n\nFlutter 是一个跨平台的 UI 框架...\n(这是一段模拟的解析内容，仅供演示)',
            title: 'Flutter 架构指南 (演示)',
            sourceUrl: _urlController.text,
            sourceType: SourceType.url,
          );
        });
      }
      return;
    }
    // ---------------------------

    try {
      if (_urlController.text.isEmpty && _pickedFile == null) {
        throw Exception('请先上传文件或粘贴链接');
      }

      setState(() {
        _isExtractingUrl = true;
        _error = null;
      });

      ExtractionResult? result;
      if (_pickedFile != null) {
        // ... existing file parse ...
        final bytes = _pickedFile!.bytes;
        if (bytes == null) throw Exception('无法读取文件内容');
        result = await ContentExtractionService.extractContentFromFile(bytes,
            filename: _pickedFile!.name);
      } else {
        final url = _urlController.text.trim();
        if (!url.startsWith('http')) throw Exception('请输入有效的 http/https 链接');
        result = await ContentExtractionService.extractFromUrl(url);
      }

      if (!mounted) return;

      setState(() {
        _extractionResult = result;
        _isExtractingUrl = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isExtractingUrl = false;
      });
    }
  }

  /// 开始 AI 生成（流式版本） - Multimodal
  /// Helper to ensure a target module ID is selected if not provided via widget
  Future<String?> _ensureTargetModuleId() async {
    try {
      // 0. Use manually selected module if available (Upfront Selector)
      if (_selectedModuleId != null && _selectedModuleId!.isNotEmpty) {
        return _selectedModuleId;
      }

      // 1. If in tutorial mode, force the first available custom module (usually "默认知识库")
      if (widget.isTutorialMode) {
        final moduleState = ref.read(moduleProvider);
        if (moduleState.custom.isNotEmpty) {
          return moduleState.custom.first.id;
        }
      }

      // 2. If widget has a target (Navigation context), use it
      if (widget.targetModuleId != null && widget.targetModuleId!.isNotEmpty) {
        return widget.targetModuleId;
      }

      // 2. Fetch available modules
      final moduleState = ref.read(moduleProvider);
      final allModules = [...moduleState.custom, ...moduleState.officials];

      // Ensure default module exists in list if possible
      if (allModules.isEmpty) {
        try {
          // Fallback to creating a temporary default one for display
          allModules.add(KnowledgeModule(
            id: 'unknown_default',
            title: '默认知识库',
            description: '系统默认',
            ownerId: FirebaseAuth.instance.currentUser?.uid ?? '',
            isOfficial: false,
            cardCount: 0,
          ));
        } catch (e) {
          print('Error creating default module placeholder: $e');
        }
      }

      if (!mounted) return null;

      // 3. Show Selection Dialog
      return await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          String? tempSelectedId;
          if (allModules.isNotEmpty) {
            tempSelectedId = allModules.first.id;
            try {
              final defaultMod = allModules.firstWhere(
                  (m) => m.title == '默认知识库',
                  orElse: () => allModules.first);
              tempSelectedId = defaultMod.id;
            } catch (e) {
              // Ignore
            }
          }

          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: const Text('选择目标知识库'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300, // Fixed height for scrolling
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('请选择存储拆解结果的知识库：',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: allModules.isEmpty
                          ? const Center(child: Text('暂无知识库'))
                          : ListView.separated(
                              itemCount: allModules.length,
                              separatorBuilder: (ctx, i) =>
                                  const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final module = allModules[i];
                                final isSelected = module.id == tempSelectedId;
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      tempSelectedId = module.id;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.1)
                                          : null,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          module.isOfficial
                                              ? Icons.verified
                                              : Icons.folder,
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                module.title,
                                                style: TextStyle(
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  color: isSelected
                                                      ? Theme.of(context)
                                                          .primaryColor
                                                      : null,
                                                ),
                                              ),
                                              if (module.description.isNotEmpty)
                                                Text(
                                                  module.description,
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                )
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check_circle,
                                              color: Colors.green, size: 20),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null), // Cancel
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(tempSelectedId),
                  child: const Text('确定'),
                ),
              ],
            );
          });
        },
      );
    } catch (e) {
      print('Error in _ensureTargetModuleId: $e');
      return null;
    }
  }

  Future<void> _startGeneration() async {
    if (_extractionResult == null) return;

    try {
      // 1. Determine Target Module ID via Centralized Helper
      final targetId = await _ensureTargetModuleId();
      if (targetId == null) return; // User cancelled or failed to resolve

      // 2. Calculate Credits & Confirm
      final charCount = _extractionResult!.content.length;
      final credits =
          ContentExtractionService.calculateRequiredCredits(charCount);
      final estTime = _calculateEstimatedTime(charCount);

      // Show Confirmation Dialog (Unless explicitly skipped or decided otherwise)
      if (!widget.isTutorialMode) {
        if (!mounted) return;
        final confirm =
            await _showGenerationConfirmDialog(credits, estTime, charCount);
        if (confirm != true) return;
      }

      // 3. Submit Job
      setState(() {
        _isGenerating = true;
        _streamingStatus = '正在提交任务...';
      });

      // Check Balance
      final canUse =
          await ref.read(creditProvider.notifier).useAI(amount: credits);
      if (!canUse) {
        if (mounted) _showInsufficientCreditsDialog(); // or snackbar
        setState(() {
          _streamingStatus = null;
          _isGenerating = false;
        });
        return;
      }

      // Submit
      final jobId = await ContentExtractionService.submitJobAndForget(
        _extractionResult!.content,
        moduleId: targetId,
        mode: ref.read(aiSettingsProvider).mode,
      );

      ref.read(feedProvider.notifier).observeJob(jobId);

      // Handle Tutorial Completion
      if (widget.isTutorialMode) {
        await ref.read(onboardingProvider.notifier).completeTutorial();
        await ref
            .read(onboardingProvider.notifier)
            .setHighlightTaskCenter(true);
      } else if (widget.targetModuleId == null) {
        // If regular home page flow, also highlight task center as a hint?
        // Maybe checking task center is good practice.
        // Let's enable highlight for regular flow too if from Home Page
        await ref
            .read(onboardingProvider.notifier)
            .setHighlightTaskCenter(true);
      }

      if (mounted) {
        Navigator.of(context).pop();

        // Show Success Feedback
        if (widget.targetModuleId == null || widget.isTutorialMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ 任务已提交！请前往任务中心查看进度'),
              backgroundColor: Colors.green[700],
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: '前往',
                textColor: Colors.white,
                onPressed: () {
                  ref
                      .read(onboardingProvider.notifier)
                      .setHighlightTaskCenter(false);
                  // Navigation handled by user clicking button
                },
              ),
            ),
          );
        } else {
          _showTaskSubmittedSnackbar();
        }
      }
    } catch (e) {
      print('Error in _startGeneration: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isGenerating = false;
        _streamingStatus = null;
      });
    }
  }

  // ... _parseLocally, _parseTextToItems, _saveAll ...
  void _parseLocally() {
    if (_textController.text.trim().isEmpty) return;
    _parseTextToItems(_textController.text);
  }

  void _parseTextToItems(String text, {String? title}) {
    // ... same as before
    final List<FeedItem> items = [];
    String finalTitle = title ?? 'Untitled';
    if (title == null) {
      if (_pickedFileName != null) {
        finalTitle = _pickedFileName!;
      } else {
        final firstLine = text.trim().split('\n').first;
        finalTitle = firstLine.length > 30
            ? '${firstLine.substring(0, 30)}...'
            : firstLine;
      }
    }
    final int readingTime = (text.length / 400).ceil();
    final int safeReadingTime = readingTime < 1 ? 1 : readingTime;

    items.add(FeedItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      moduleId:
          _selectedModuleId ?? widget.targetModuleId ?? '', // Prefer selection
      title: finalTitle,
      pages: [OfficialPage(text)],
      category: 'Manual',
      difficulty: 'Normal', // Default
      readingTimeMinutes: safeReadingTime,
      masteryLevel: FeedItemMastery.unknown,
      isCustom: true,
    ));

    setState(() {
      _generatedItems = items;
    });
  }

  void _saveAll() async {
    // ... same as before
    if (_generatedItems == null) return;
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('用户未登录');

      // Ensure Target Module ID via Centralized Helper
      final targetId = await _ensureTargetModuleId();
      if (targetId == null) return; // Users cancelled

      final service = ref.read(dataServiceProvider);
      for (var item in _generatedItems!) {
        final itemToSave = item.copyWith(moduleId: targetId);
        await service.saveCustomFeedItem(itemToSave, currentUser.uid);
      }
      ref.read(feedProvider.notifier).addCustomItems(_generatedItems!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ 导入成功！知识卡片已添加到学习库'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Palette
    final bgColor = isDark ? const Color(0xFF212526) : const Color(0xFFF8FAFC);
    final textColor =
        isDark ? const Color(0xFFe6e8d1) : const Color(0xFF1E293B);
    final subTextColor = isDark
        ? const Color(0xFFe6e8d1).withOpacity(0.7)
        : const Color(0xFF64748B);
    final accentColor =
        isDark ? const Color(0xFFee8f4b) : const Color(0xFFFF8A65);
    final borderColor = isDark
        ? const Color(0xFF917439).withOpacity(0.3)
        : const Color(0xFFE2E8F0);

    final screenHeight = MediaQuery.of(context).size.height;
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;

    double dialogHeight;
    if (viewInsetsBottom > 0) {
      dialogHeight = (screenHeight - viewInsetsBottom - 32).clamp(300.0, 750.0);
    } else {
      dialogHeight = (screenHeight * 0.8).clamp(500.0, 750.0);
    }

    return WillPopScope(onWillPop: () async {
      // TUTORIAL GUARD
      if (widget.isTutorialMode && !_isGenerating) {
        // Allow close if generating just in case
        // Show dialog explaining they should finish
        await showDialog(
            context: context,
            builder: (c) => AlertDialog(
                  title: const Text('新手教程未完成'),
                  content:
                      const Text('建议完成教程以获得最佳体验。完成后将不再显示。\n\n(完成后可获得 0 积分特权)'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(c).pop(),
                        child: const Text('继续体验')),
                    TextButton(
                        onPressed: () {
                          Navigator.of(c).pop(); // Close alert
                          Navigator.of(context)
                              .pop(); // Close modal (Force quit)
                          ref
                              .read(onboardingProvider.notifier)
                              .completeTutorial(); // Mark as seen anyway so they aren't stuck forever
                        },
                        child: const Text('跳过教程',
                            style: TextStyle(color: Colors.grey)))
                  ],
                ));
        return false; // Prevent direct close unless they choose Skip
      }

      if (_isGenerating) {
        final shouldClose = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('正在生成中'),
            content: const Text('生成任务正在进行，退出将中断生成。确定要退出吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('继续生成'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('狠心退出', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        return shouldClose ?? false;
      }
      return true;
    }, child: LayoutBuilder(builder: (context, constraints) {
      final isDesktop = MediaQuery.of(context).size.width > 900;
      final modalWidth = isDesktop ? 1100.0 : 600.0;

      return Dialog(
        backgroundColor: bgColor,
        insetPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: viewInsetsBottom > 0 ? 10 : 24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: isDark
              ? BorderSide(color: borderColor, width: 1)
              : BorderSide.none,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: dialogHeight,
          constraints: BoxConstraints(
            maxWidth: modalWidth,
          ),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildInputUI(
                          textColor, subTextColor, accentColor, borderColor,
                          isDesktop: true),
                    ),
                    Container(width: 1, color: borderColor),
                    Expanded(
                      flex: 2,
                      child: _buildQueuePanel(isDark, borderColor, textColor,
                          subTextColor, accentColor),
                    ),
                  ],
                )
              : _buildInputUI(textColor, subTextColor, accentColor, borderColor,
                  isDesktop: false),
        ),
      );
    }));
  }

  Widget _buildInputUI(
      Color textColor, Color subTextColor, Color accentColor, Color borderColor,
      {required bool isDesktop}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF212526) : Colors.white;

    return Column(
      // Removed DefaultTabController
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    isDesktop ? '添加学习资料 (批量)' : '添加学习资料',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  if (widget.isTutorialMode)
                    Container(
                      margin: const EdgeInsets.only(left: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.orangeAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orangeAccent)),
                      child: const Text('新手引导模式',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold)),
                    )
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, color: subTextColor),
                onPressed: () async {
                  Navigator.of(context).maybePop(); // Triggers WillPopScope
                },
                style: IconButton.styleFrom(
                  backgroundColor:
                      isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ),

        // Tabs - USING CUSTOM CONTROLLER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isDark ? Border.all(color: borderColor) : null,
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: TabBar(
              controller: _tabController, // CUSTOM
              indicator: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              labelColor: isDark ? const Color(0xFF212526) : Colors.white,
              unselectedLabelColor: subTextColor,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: '文本导入'),
                Tab(text: '多模态 (AI)'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Content
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.only(
                bottomLeft: const Radius.circular(24),
                bottomRight:
                    isDesktop ? Radius.zero : const Radius.circular(24),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: const Radius.circular(24),
                bottomRight:
                    isDesktop ? Radius.zero : const Radius.circular(24),
              ),
              child: TabBarView(
                controller: _tabController, // CUSTOM
                children: [
                  _buildPlainTextTab(isDesktop: isDesktop),
                  _buildNotebookLMTab(isDesktop: isDesktop),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQueuePanel(bool isDark, Color borderColor, Color textColor,
      Color subTextColor, Color accentColor) {
    final batchState = ref.watch(batchImportProvider);
    final notifier = ref.read(batchImportProvider.notifier);
    final queue = batchState.queue;

    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : const Color(0xFFF1F5F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(Icons.playlist_add_check, color: accentColor),
                const SizedBox(width: 12),
                Text(
                  '批量处理队列 (${queue.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: queue.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 48, color: subTextColor.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('队列为空', style: TextStyle(color: subTextColor)),
                        Text('在左侧添加内容以开始处理',
                            style: TextStyle(
                                color: subTextColor.withOpacity(0.7),
                                fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: queue.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = queue[index];
                      return InkWell(
                        onTap: () {
                          // Allow inspecting status or result if needed?
                          // For now just ripple effect
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: item.status == BatchStatus.completed
                                    ? Colors.green.withOpacity(0.3)
                                    : borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    item.type == BatchType.url
                                        ? Icons.link
                                        : (item.type == BatchType.file
                                            ? Icons.description
                                            : Icons.text_fields),
                                    size: 16,
                                    color: item.status == BatchStatus.completed
                                        ? Colors.green
                                        : subTextColor,
                                  ),
                                  const SizedBox(width: 4),
                                  if (item.processingMode ==
                                      BatchProcessingMode.ai)
                                    Icon(Icons.auto_awesome,
                                        size: 12, color: accentColor)
                                  else
                                    Icon(Icons.save_alt,
                                        size: 12, color: subTextColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                        decoration:
                                            item.status == BatchStatus.completed
                                                ? TextDecoration.lineThrough
                                                : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.status == BatchStatus.pending)
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      onPressed: () =>
                                          notifier.removeFromQueue(item.id),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    )
                                  else if (item.status == BatchStatus.completed)
                                    const Icon(Icons.check_circle,
                                        color: Colors.green, size: 18)
                                  else if (item.status == BatchStatus.error)
                                    const Icon(Icons.error,
                                        color: Colors.red, size: 18),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: item.progress,
                                        backgroundColor:
                                            accentColor.withOpacity(0.1),
                                        valueColor:
                                            AlwaysStoppedAnimation(accentColor),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    item.statusMessage,
                                    style: TextStyle(
                                        fontSize: 12, color: subTextColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action
          if (queue.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status / Leave Button
                  if (batchState.isProcessing)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.green.withOpacity(0.3))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text('后台运行中，可安全离开',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      if (queue
                          .any((i) => i.status == BatchStatus.completed)) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: batchState.isProcessing
                                ? null
                                : () {
                                    notifier.clearCompleted();
                                  },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: subTextColor,
                              side: BorderSide(color: borderColor),
                            ),
                            child: const Text('清除已完成'),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: batchState.isProcessing
                              ? () {
                                  // Close modal
                                  Navigator.of(context).pop();
                                  _showTaskSubmittedSnackbar();
                                }
                              : (queue.every(
                                      (i) => i.status == BatchStatus.completed)
                                  ? null
                                  : () {
                                      notifier.startProcessing(
                                          widget.targetModuleId ?? 'custom');
                                    }),
                          icon: batchState.isProcessing
                              ? const Icon(Icons.exit_to_app)
                              : const Icon(Icons.play_arrow),
                          label: Text(batchState.isProcessing
                              ? '暂时离开 (后台继续)'
                              : (queue.every(
                                      (i) => i.status == BatchStatus.completed)
                                  ? '全部完成'
                                  : '开始批量处理')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: batchState.isProcessing
                                ? Theme.of(context).scaffoldBackgroundColor
                                : accentColor,
                            foregroundColor: batchState.isProcessing
                                ? textColor
                                : Colors.white,
                            elevation: 0,
                            side: batchState.isProcessing
                                ? BorderSide(color: borderColor)
                                : BorderSide.none,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            disabledBackgroundColor:
                                accentColor.withOpacity(0.5),
                            disabledForegroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlainTextTab({bool isDesktop = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Palette
    final cardBg = isDark ? const Color(0xFF212526) : Colors.white;
    final inputBg = isDark ? const Color(0xFF2d3233) : const Color(0xFFF8FAFC);
    final hintBg = isDark ? const Color(0xFF2d3233) : const Color(0xFFEFF6FF);
    final borderColor = isDark
        ? const Color(0xFF917439).withOpacity(0.3)
        : Colors.grey.withOpacity(0.2);
    final textColor =
        isDark ? const Color(0xFFe6e8d1) : const Color(0xFF334155);
    final secondaryTextColor = isDark
        ? const Color(0xFFe6e8d1).withOpacity(0.7)
        : const Color(0xFF64748B);
    final accentColor =
        isDark ? const Color(0xFFee8f4b) : const Color(0xFFFF8A65);

    final batchState = ref.watch(batchImportProvider);
    final hasQueueItems = batchState.queue.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 显示输入区域的条件：没有生成的items 且 不在生成中
          if (_generatedItems == null && !_isGenerating) ...[
            // Input State - 使用 ScrollView 包裹整个内容
            Expanded(
              child: Container(
                // 确保容器有背景色，避免透明造成的点击穿透问题
                color: Colors.transparent,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // 1. 文本输入框 (Fixed Height)
                      Container(
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: TextField(
                          controller: _textController,
                          maxLines: null,
                          expands: true,
                          style: TextStyle(
                              fontSize: 16, height: 1.5, color: textColor),
                          scrollPadding: const EdgeInsets.only(bottom: 150),
                          decoration: InputDecoration(
                            hintText:
                                '在此粘贴文章内容、笔记或网页文本...\n\n示例：\n# 什么是 Flutter\nFlutter 是 Google 开源的 UI 工具包...\n\n# 特点\n1. 跨平台\n2. 高性能...',
                            hintStyle: TextStyle(
                                color: secondaryTextColor.withOpacity(0.5)),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 2. 小贴士 (Moved Below)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hintBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline,
                                color: isDark
                                    ? accentColor
                                    : const Color(0xFF3B82F6),
                                size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style:
                                      TextStyle(fontSize: 12, color: textColor),
                                  children: [
                                    const TextSpan(
                                        text: '直接导模式的小贴士：',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const TextSpan(text: '使用 Markdown 标题 (如 '),
                                    TextSpan(
                                        text: '# 标题',
                                        style: TextStyle(
                                            fontFamily: 'monospace',
                                            color: isDark ? accentColor : null,
                                            backgroundColor: isDark
                                                ? Colors.transparent
                                                : const Color(0xFFDBEAFE))),
                                    const TextSpan(
                                        text:
                                            ') 可手动拆分卡片，无需消耗 AI 额度。若无标题，将默认使用第一句话作为标题。'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildKbSelector(isDark), // Added Selector
                      _buildAiDeconstructionSelector(ref, isDark),

                      // 底部留白，防止被键盘遮挡体验不好
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13))),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: hasQueueItems
                        ? () => _showQueueConflictMessage()
                        : (_isGenerating ? null : _parseLocally),
                    icon: const Icon(Icons.format_align_left),
                    label: const Text('直接导入'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      foregroundColor: secondaryTextColor,
                      backgroundColor: cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      if (isDesktop) ...[
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    if (_textController.text
                                        .trim()
                                        .isNotEmpty) {
                                      final text = _textController.text.trim();
                                      final title = text.length > 15
                                          ? '${text.substring(0, 15).replaceAll('\n', ' ')}...'
                                          : text;
                                      ref
                                          .read(batchImportProvider.notifier)
                                          .addItem(BatchType.text, text, title,
                                              mode: BatchProcessingMode.direct);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text('已直接加入队列')));
                                      _textController.clear();
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
                                    side: BorderSide(color: borderColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text('直接导队列',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    if (_textController.text
                                        .trim()
                                        .isNotEmpty) {
                                      final text = _textController.text.trim();
                                      final title = text.length > 15
                                          ? '${text.substring(0, 15).replaceAll('\n', ' ')}...'
                                          : text;
                                      ref
                                          .read(batchImportProvider.notifier)
                                          .addItem(BatchType.text, text, title,
                                              mode: BatchProcessingMode.ai);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text('已加入AI队列')));
                                      _textController.clear();
                                    }
                                  },
                                  icon:
                                      const Icon(Icons.auto_awesome, size: 14),
                                  label: const Text('AI队列',
                                      style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
                                    side: BorderSide(color: borderColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: TutorialPulse(
                          isActive:
                              widget.isTutorialMode && !_tutorialStep1Complete,
                          child: ElevatedButton.icon(
                            onPressed: hasQueueItems
                                ? () => _showQueueConflictMessage()
                                : (_isGenerating ? null : _generate),
                            icon: _isGenerating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.auto_awesome),
                            label:
                                Text(_isGenerating ? 'AI 智能解析中...' : 'AI 智能拆解'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              shadowColor: accentColor.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            // Review State (包括流式生成中的状态)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_isGenerating) ...[
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              _isGenerating
                                  ? (_streamingStatus ?? '正在生成...')
                                  : '已生成 ${_generatedItems?.length ?? 0} 个知识点',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (_isGenerating && _totalCards != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: LinearProgressIndicator(
                            value: (_currentCardIndex ?? 0) / _totalCards!,
                            backgroundColor: borderColor,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(accentColor),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!_isGenerating)
                  IconButton(
                    icon: Icon(Icons.refresh, color: secondaryTextColor),
                    onPressed: () {
                      setState(() {
                        _generatedItems = null;
                        _isGenerating = false;
                        _streamingStatus = null;
                        _totalCards = null;
                        _currentCardIndex = null;
                      });
                    },
                    tooltip: '重新编辑',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            Expanded(
              child: (_isGenerating &&
                      (_generatedItems == null || _generatedItems!.isEmpty))
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _streamingStatus ?? '正在连接 AI...',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'AI 正在阅读并分析您的内容\n第一张卡片通常需要 5-10 秒...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: secondaryTextColor.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: (_generatedItems?.length ?? 0) +
                          (_isGenerating ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        // 如果是最后一项且正在生成，显示加载条
                        if (_isGenerating &&
                            index == (_generatedItems?.length ?? 0)) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: borderColor.withOpacity(0.5),
                                  style: BorderStyle.solid),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: accentColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '正在生成下一张卡片...',
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final item = _generatedItems![index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              if (!isDark)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? accentColor.withValues(alpha: 0.2)
                                          : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('${index + 1}',
                                        style: TextStyle(
                                            color: isDark
                                                ? accentColor
                                                : const Color(0xFF3B82F6),
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Text(item.title,
                                          style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? borderColor.withOpacity(0.3)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(item.category,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: secondaryTextColor)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.black.withOpacity(0.2)
                                        : const Color(0xFFFFF7ED),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: isDark
                                            ? borderColor
                                            : const Color(0xFFFFEDD5)),
                                  ),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Icon(Icons.help_outline,
                                              size: 14,
                                              color: isDark
                                                  ? accentColor
                                                  : const Color(0xFFF97316)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                              child: Text(
                                                  '提问: ${(item.pages.first as OfficialPage).flashcardQuestion ?? "无"}',
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: isDark
                                                          ? accentColor
                                                          : const Color(
                                                              0xFF9A3412),
                                                      fontWeight:
                                                          FontWeight.w500)))
                                        ])
                                      ])),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isGenerating
                        ? null
                        : () {
                            setState(() {
                              _generatedItems = null;
                              _streamingStatus = null;
                              _totalCards = null;
                              _currentCardIndex = null;
                            });
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      foregroundColor: secondaryTextColor,
                    ),
                    child: const Text('返回修改'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        (_isGenerating || (_generatedItems?.isEmpty ?? true))
                            ? null
                            : _saveAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      disabledBackgroundColor: accentColor.withOpacity(0.5),
                    ),
                    child: Text(_isGenerating ? '生成中...' : '确认并保存'),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildNotebookLMTab({bool isDesktop = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Palette

    final inputBg =
        isDark ? const Color(0xFF2d3233) : Colors.white; // Input field bg
    final borderColor = isDark
        ? const Color(0xFF917439).withOpacity(0.3)
        : const Color(0xFFE2E8F0);
    final textColor =
        isDark ? const Color(0xFFe6e8d1) : const Color(0xFF1E293B);
    final secondaryTextColor = isDark
        ? const Color(0xFFe6e8d1).withOpacity(0.7)
        : const Color(0xFF64748B);
    final accentColor =
        isDark ? const Color(0xFFee8f4b) : const Color(0xFFFF8A65);

    final batchState = ref.watch(batchImportProvider);
    final hasQueueItems = batchState.queue.isNotEmpty;

    if (_generatedItems != null || _isGenerating) {
      // 统一使用文本导入的 Review State UI
      return _buildPlainTextTab(isDesktop: isDesktop);
    }

    // --- Main Layout: Inputs (Left) + Buttons (Right) ---
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // === LEFT COLUMN: Inputs & Info ===
                  Expanded(
                    child: Column(
                      children: [
                        // 1. File Input Box
                        InkWell(
                          onTap: () {
                            if (!_isParsing && !_isGenerating) _pickFile();
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _pickedFile != null
                                    ? const Color(0xFF10B981) // Green
                                    : borderColor,
                                width: _pickedFile != null ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _pickedFile != null
                                      ? Icons.description
                                      : Icons.upload_file,
                                  size: 32,
                                  color: _pickedFile != null
                                      ? const Color(0xFF10B981)
                                      : (isDark
                                          ? secondaryTextColor
                                          : const Color(0xFF94A3B8)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _pickedFileName ?? '支持PDF, Word, Markdown',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _pickedFile != null
                                        ? (isDark
                                            ? textColor
                                            : const Color(0xFF1E293B))
                                        : (isDark
                                            ? secondaryTextColor
                                            : const Color(0xFF94A3B8)),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_pickedFile != null) ...[
                                  const SizedBox(height: 4),
                                  const Text('已选择 (点击更换)',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.grey)),
                                ]
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 2. Link Input Box
                        TextField(
                          controller: _urlController,
                          style: TextStyle(fontSize: 15, color: textColor),
                          scrollPadding: const EdgeInsets.only(bottom: 100),
                          decoration: InputDecoration(
                            hintText: '支持大部分网页、YouTube等',
                            hintStyle: TextStyle(
                                color: secondaryTextColor.withOpacity(0.5)),
                            prefixIcon:
                                Icon(Icons.link, color: secondaryTextColor),
                            suffixIcon: _urlController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear,
                                        size: 18, color: secondaryTextColor),
                                    onPressed: () {
                                      _urlController.clear();
                                      setState(() => _urlError = null);
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                          onChanged: (_) {
                            if (_pickedFile != null) {
                              // Clear picked file if user types url
                              setState(() {
                                _pickedFile = null;
                                _pickedFileName = null;
                                _extractionResult = null;
                              });
                            }
                            setState(() => _urlError = null);
                          },
                        ),

                        const SizedBox(height: 12),
                        _buildKbSelector(isDark), // Added Selector
                        _buildAiDeconstructionSelector(ref, isDark),

                        // 3. Status / Info Area (Result or Error)
                        if (_error != null || _urlError != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error ?? _urlError!,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (_extractionResult != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4), // Green 50
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Color(0xFF10B981), size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _extractionResult!.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF065F46)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(left: 36),
                                  child: Text(
                                    '包含 ${_extractionResult!.content.length} 字符 · 预计耗时 ${_calculateEstimatedTime(_extractionResult!.content.length)}',
                                    style: const TextStyle(
                                        color: Color(0xFF047857), fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  // === RIGHT COLUMN: Buttons ===
                  SizedBox(
                    width: 120,
                    child: Column(
                      children: [
                        // Parse Button
                        if (isDesktop) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {
                                if (_pickedFile != null &&
                                    _pickedFile!.bytes != null) {
                                  ref
                                      .read(batchImportProvider.notifier)
                                      .addItem(
                                          BatchType.file,
                                          _pickedFile!.bytes!,
                                          _pickedFileName!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('文件已加入队列')));
                                  setState(() {
                                    _pickedFile = null;
                                    _pickedFileName = null;
                                  });
                                } else if (_urlController.text.isNotEmpty) {
                                  ref
                                      .read(batchImportProvider.notifier)
                                      .addItem(
                                          BatchType.url,
                                          _urlController.text.trim(),
                                          _urlController.text.trim());
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('链接已加入队列')));
                                  _urlController.clear();
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('加入队列'),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (hasQueueItems)
                                ? () => _showQueueConflictMessage()
                                : ((_isParsing || _isGenerating)
                                    ? null
                                    : _performParse),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF2d3233)
                                  : const Color(0xFFF1F5F9),
                              foregroundColor: isDark
                                  ? accentColor
                                  : const Color(0xFF1E293B),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: isDark
                                      ? BorderSide(color: borderColor)
                                      : BorderSide.none),
                              padding: EdgeInsets.zero,
                            ),
                            child: _isParsing
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: isDark ? accentColor : null))
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.auto_fix_high, size: 20),
                                      SizedBox(height: 4),
                                      Text('解析',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // AI Generation Button - Expanded to fill height
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: TutorialPulse(
                                      isActive: widget.isTutorialMode &&
                                          _tutorialStep1Complete &&
                                          _extractionResult != null,
                                      child: ElevatedButton(
                                        onPressed: _streamingStatus != null
                                            ? null
                                            : (hasQueueItems
                                                ? () =>
                                                    _showQueueConflictMessage()
                                                : (_extractionResult != null
                                                    ? _startGeneration
                                                    : null)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDark
                                              ? accentColor
                                              : const Color(0xFF1E293B),
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: isDark
                                              ? Colors.grey.withOpacity(0.1)
                                              : const Color(0xFFE2E8F0),
                                          disabledForegroundColor:
                                              const Color(0xFF94A3B8),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16)),
                                        ),
                                        child: _streamingStatus != null
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white))
                                            : Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.auto_awesome,
                                                      size: 28),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                      _streamingStatus ??
                                                          (_extractionResult !=
                                                                  null
                                                              ? '开始智能拆解 (${ContentExtractionService.calculateRequiredCredits(_extractionResult!.content.length)} 积分)'
                                                              : '等待解析...'),
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Direct Import Button (Secondary)
                                if (_extractionResult != null && !_isGenerating)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: TextButton(
                                        onPressed: () {
                                          _parseTextToItems(
                                              _extractionResult!.content);
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          foregroundColor: secondaryTextColor,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              side: BorderSide(
                                                  color: borderColor)),
                                        ),
                                        child: const Text('直接收藏 (不拆解)',
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Coming Soon
            Column(
              children: [
                Text(
                  '即将支持 / Coming Soon',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[400],
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildComingSoonChip('小红书', Icons.camera_alt),
                    _buildComingSoonChip('知乎', Icons.question_answer),
                    _buildComingSoonChip('微信公众号', Icons.rss_feed),
                    _buildComingSoonChip('Bilibili', Icons.tv),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Renaming getter to match new logic variable name if needed, but we used _isExtractingUrl in state
  bool get _isParsing => _isExtractingUrl; // Helper getter

  void _showQueueConflictMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.layers_clear, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('队列中已有待处理任务。请清空队列或使用批量模式。'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(24),
      ),
    );
  }

  String _calculateEstimatedTime(int length) {
    // 粗略估算：假设每 1000 字处理需要 5-8 秒 + 网络延迟
    // 简单公式：基础 3秒 + 每1000字 3秒
    final seconds = 3 + (length / 1000 * 3).round();
    if (seconds < 60) {
      return '$seconds 秒';
    } else {
      return '${(seconds / 60).toStringAsFixed(1)} 分钟';
    }
  }

  Future<bool?> _showGenerationConfirmDialog(
      int credits, String estTime, int charCount) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFee8f4b)),
            SizedBox(width: 12),
            Text('确认开始拆解？'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('系统已识别内容：约 $charCount 字'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('预计耗时：$estTime',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFee8f4b).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFFee8f4b).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Color(0xFFee8f4b), size: 20),
                  const SizedBox(width: 12),
                  const Text('本次将扣除：',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('$credits',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFee8f4b))),
                  const Text(' 积分'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('💡 提示：AI 解析内容是免费的，智能拆解将根据内容深度自动匹配最佳方案。',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 24),
            Consumer(builder: (context, ref, _) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return _buildAiDeconstructionSelector(ref, isDark);
            }),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.volunteer_activism_outlined,
                    size: 14, color: Colors.green[400]),
                const SizedBox(width: 8),
                Text('Reado 福利：AI 聊天、解析文件完全免费',
                    style: TextStyle(fontSize: 11, color: Colors.green[700])),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFee8f4b)),
            child: const Text('开始生成'),
          ),
        ],
      ),
    );
  }

  void _showInsufficientCreditsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(
          child: Icon(Icons.stars, color: Color(0xFFFFB300), size: 48),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('积分不足',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('执行 AI 解析或生成卡片需要 10 积分。您可以去分享知识库获取更多奖励！',
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('了解'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close modal
              // User will likely go to module detail or home to share
            },
            child: const Text('去分享奖励'),
          ),
        ],
      ),
    );
  }

  // New Minimal Chip for Coming Soon Sources
  Widget _buildAiDeconstructionSelector(WidgetRef ref, bool isDark) {
    final aiSettings = ref.watch(aiSettingsProvider);
    final accentColor = const Color(0xFFee8f4b);

    Widget _buildModeChip(AiDeconstructionMode mode, String label, String sub) {
      final isSelected = aiSettings.mode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => ref.read(aiSettingsProvider.notifier).setMode(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withOpacity(0.1)
                  : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : (isDark ? Colors.white12 : Colors.black12),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? accentColor
                          : (isDark ? Colors.white70 : Colors.black87),
                    )),
                const SizedBox(height: 2),
                Text(sub,
                    style: TextStyle(
                      fontSize: 9,
                      color: isDark ? Colors.grey : Colors.grey[600],
                    )),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('AI 拆解风格',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              )),
        ),
        Row(
          children: [
            _buildModeChip(AiDeconstructionMode.standard, '普通', '严谨全面'),
            const SizedBox(width: 8),
            _buildModeChip(AiDeconstructionMode.grandma, '老奶奶', '极其通俗'),
            const SizedBox(width: 8),
            _buildModeChip(AiDeconstructionMode.phd, '智障博士', '大白话'),
          ],
        ),
      ],
    );
  }

  Widget _buildComingSoonChip(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2d3233) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF917439).withOpacity(0.3)
        : const Color(0xFFF1F5F9);
    final textColor = isDark
        ? Colors.grey[400]
        : Colors.grey[400]; // Keep grey for disabled look

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
