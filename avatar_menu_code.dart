// 完整的头像菜单代码
// 复制这段代码，替换 home_tab.dart 第 44-67 行的内容

              // 1. Top Bar: Title & Avatar Menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'QuickPM',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton(
                    offset: const Offset(0, 50),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey
                          : Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: ListTile(
                          leading: const Icon(Icons.person, size: 20),
                          title: const Text('个人主页'),
                          contentPadding: EdgeInsets.zero,
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('个人主页功能开发中...')),
                            );
                          },
                        ),
                      ),
                      PopupMenuItem(
                        child: ListTile(
                          leading: const Icon(Icons.settings, size: 20),
                          title: const Text('设置'),
                          contentPadding: EdgeInsets.zero,
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('设置功能开发中...')),
                            );
                          },
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        child: Consumer(
                          builder: (context, ref, _) {
                            final isDark = ref.watch(themeProvider) != ThemeMode.light;
                            return ListTile(
                              leading: Icon(
                                isDark ? Icons.light_mode : Icons.dark_mode,
                                size: 20,
                              ),
                              title: Text(isDark ? '浅色模式' : '深色模式'),
                              contentPadding: EdgeInsets.zero,
                              onTap: () {
                                ref.read(themeProvider.notifier).setTheme(
                                      isDark ? ThemeMode.light : ThemeMode.dark,
                                    );
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
