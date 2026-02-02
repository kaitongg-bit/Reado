import 'package:flutter/material.dart';
import '../../data/database/database_factory.dart';
import '../../data/database/database_interface.dart';
import '../../data/database/region_detector.dart';

/// 数据库架构测试页面
/// 用于验证新的数据库抽象层，不影响主应用
class DatabaseTestPage extends StatefulWidget {
  const DatabaseTestPage({Key? key}) : super(key: key);

  @override
  State<DatabaseTestPage> createState() => _DatabaseTestPageState();
}

class _DatabaseTestPageState extends State<DatabaseTestPage> {
  DatabaseInterface? _database;
  String? _detectedRegion;
  String? _currentUserId;
  bool _isLoading = false;
  String _statusMessage = '点击按钮开始测试';
  final List<String> _logs = [];

  void _log(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toString().split('.')[0]}: $message');
    });
    debugPrint('🧪 TEST: $message');
  }

  // Test 1: 检测地区
  Future<void> _testRegionDetection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '正在检测地区...';
    });

    try {
      _log('开始地区检测...');
      final isChina = await RegionDetector.isChina();
      final region = isChina ? '中国大陆' : '海外';

      setState(() {
        _detectedRegion = region;
        _statusMessage = '✅ 检测完成: $region';
      });
      _log('✅ 地区检测成功: $region');
      _log('📍 预期: 海外 (你在美国)');
    } catch (e) {
      setState(() {
        _statusMessage = '❌ 检测失败: $e';
      });
      _log('❌ 地区检测失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Test 2: 初始化数据库
  Future<void> _testDatabaseInit() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '正在初始化数据库...';
    });

    try {
      _log('开始初始化数据库...');
      final db = await DatabaseFactory.create();

      setState(() {
        _database = db;
        _statusMessage = '✅ 数据库初始化成功';
      });
      _log('✅ 数据库创建成功');
      _log('📦 实现类型: ${db.runtimeType}');
      _log('📍 预期: FirebaseDatabaseImpl');
    } catch (e) {
      setState(() {
        _statusMessage = '❌ 初始化失败: $e';
      });
      _log('❌ 数据库初始化失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Test 3: 获取当前用户
  Future<void> _testGetCurrentUser() async {
    if (_database == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先初始化数据库')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '正在获取用户信息...';
    });

    try {
      _log('获取当前用户 ID...');
      final userId = _database!.getCurrentUserId();

      setState(() {
        _currentUserId = userId;
        _statusMessage = userId != null
            ? '✅ 用户已登录: ${userId.substring(0, 8)}...'
            : '⚠️ 用户未登录';
      });
      _log('用户状态: ${userId != null ? "已登录" : "未登录"}');
      if (userId != null) {
        _log('用户 ID: $userId');
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ 获取用户失败: $e';
      });
      _log('❌ 获取用户失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Test 4: 测试数据读取
  Future<void> _testDataFetch() async {
    if (_database == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先初始化数据库')),
      );
      return;
    }

    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '正在测试数据读取...';
    });

    try {
      _log('测试获取用户模块...');
      final modules = await _database!.fetchUserModules(_currentUserId!);

      setState(() {
        _statusMessage = '✅ 成功读取 ${modules.length} 个模块';
      });
      _log('✅ 成功获取 ${modules.length} 个模块');
      for (var module in modules.take(3)) {
        _log('  - ${module.title}');
      }
    } catch (e) {
      setState(() {
        _statusMessage = '⚠️ 数据读取测试: $e';
      });
      _log('⚠️ 数据读取: $e');
      _log('💡 这是正常的，可能是因为接口方法还未完全实现');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Test 5: 强制切换地区测试
  Future<void> _testRegionSwitch(bool toChina) async {
    setState(() {
      _isLoading = true;
      _statusMessage = '正在切换地区...';
    });

    try {
      _log(toChina ? '模拟切换到国内...' : '恢复自动检测...');
      await RegionDetector.setUserRegionOverride(toChina ? 'cn' : null);

      // 重新检测
      final isChina = await RegionDetector.isChina();
      final region = isChina ? '中国大陆' : '海外';

      setState(() {
        _detectedRegion = region;
        _database = null; // 清除旧数据库实例
        _statusMessage = '✅ 已切换到: $region (需要重新初始化数据库)';
      });
      _log('✅ 地区设置已更新: $region');
      _log('⚠️ 请重新点击"初始化数据库"');
    } catch (e) {
      setState(() {
        _statusMessage = '❌ 切换失败: $e';
      });
      _log('❌ 地区切换失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 运行所有测试
  Future<void> _runAllTests() async {
    _log('🚀 开始运行完整测试流程...');
    await _testRegionDetection();
    await Future.delayed(const Duration(milliseconds: 500));
    await _testDatabaseInit();
    await Future.delayed(const Duration(milliseconds: 500));
    await _testGetCurrentUser();
    _log('✅ 测试流程完成');
  }

  Widget _buildTestButton({
    required String label,
    required VoidCallback onPressed,
    Color? color,
    IconData? icon,
  }) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon ?? Icons.play_arrow),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 数据库架构测试'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                _logs.clear();
                _statusMessage = '日志已清空';
              });
            },
            tooltip: '清空日志',
          ),
        ],
      ),
      body: Column(
        children: [
          // 状态显示区
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_detectedRegion != null) Text('🌍 地区: $_detectedRegion'),
                if (_database != null) Text('📦 数据库: ${_database.runtimeType}'),
                if (_currentUserId != null)
                  Text('👤 用户: ${_currentUserId!.substring(0, 12)}...'),
              ],
            ),
          ),

          // 测试按钮区
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '基础测试',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildTestButton(
                  label: '1️⃣ 检测地区',
                  icon: Icons.location_searching,
                  onPressed: _testRegionDetection,
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  label: '2️⃣ 初始化数据库',
                  icon: Icons.storage,
                  onPressed: _testDatabaseInit,
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  label: '3️⃣ 获取当前用户',
                  icon: Icons.person,
                  onPressed: _testGetCurrentUser,
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  label: '4️⃣ 测试数据读取',
                  icon: Icons.download,
                  onPressed: _testDataFetch,
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  label: '🧨 暴力写入测试 (Direct)',
                  icon: Icons.dangerous,
                  color: Colors.redAccent,
                  onPressed: () async {
                    setState(() {
                      _statusMessage = '正在尝试写入...';
                      _isLoading = true;
                    });
                    _log('🧨 开始暴力写入测试...');
                    try {
                      final docRef = FirebaseFirestore.instance
                          .collection('test')
                          .doc('manual_test');
                      _log('⏳ 正在发送请求...');
                      await docRef.set({
                        'time': DateTime.now().toIso8601String(),
                        'msg': 'Manual write from Test Page',
                      }).timeout(const Duration(seconds: 10)); // 加个超时

                      _log('✅ 写入成功！网络是通的！');
                      setState(() => _statusMessage = '✅ 写入成功');
                    } catch (e) {
                      _log('❌ 写入失败: $e');
                      setState(() => _statusMessage = '❌ 写入失败: $e');
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  '高级测试',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildTestButton(
                  label: '🚀 运行完整流程',
                  icon: Icons.auto_awesome,
                  color: Colors.green,
                  onPressed: _runAllTests,
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  label: '🇨🇳 模拟切换到国内',
                  icon: Icons.swap_horiz,
                  color: Colors.orange,
                  onPressed: () => _testRegionSwitch(true),
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  label: '🌏 恢复自动检测',
                  icon: Icons.restore,
                  onPressed: () => _testRegionSwitch(false),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  '📝 测试日志',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _logs.isEmpty
                      ? const Center(
                          child: Text(
                            '暂无日志',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                _logs[index],
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
