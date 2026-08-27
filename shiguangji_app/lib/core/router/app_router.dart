import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../network/token_store.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../../features/auth/login_page.dart';
import '../../features/recipe/home_page.dart';
import '../../features/recipe/search_page.dart';
import '../../features/recipe/category_page.dart';
import '../../features/recipe/detail_page.dart';
import '../../features/recipe/edit_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/profile/favorites_page.dart';
import '../../features/profile/families_page.dart';

/// 全部页面需登录（未登录强制锁在登录页，服务器地址在登录页输入）
final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final path = state.matchedLocation;
    final authed = TokenStore.instance.isAuthed;
    // 未登录且不在登录页 → 强制去登录页（带 from 参数，登录后回跳）
    if (!authed && path != '/login') {
      final from = Uri.encodeQueryComponent(path);
      final existing = state.uri.queryParameters['from'];
      return '/login?from=${existing ?? from}';
    }
    // 已登录又访问登录页 → 回首页
    if (path == '/login' && authed) return '/';
    return null;
  },
  routes: [
    // 三个 Tab 页（首页 / 新增 / 个人）共享玻璃胶囊 TabBar
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (c, s) => const HomePage()),
        GoRoute(path: '/recipe/edit', builder: (c, s) => const EditPage()),
        GoRoute(path: '/profile', builder: (c, s) => const ProfilePage()),
      ],
    ),
    GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
    GoRoute(path: '/search', builder: (c, s) => const SearchPage()),
    GoRoute(path: '/category/:id', builder: (c, s) => CategoryPage(
      categoryId: s.pathParameters['id']!,
    )),
    GoRoute(path: '/recipe/:id', builder: (c, s) => DetailPage(
      recipeId: s.pathParameters['id']!,
    )),
    GoRoute(path: '/recipe/:id/edit', builder: (c, s) => EditPage(recipeId: s.pathParameters['id']!)),
    GoRoute(path: '/favorites', builder: (c, s) => const FavoritesPage()),
    GoRoute(path: '/families', builder: (c, s) => const FamiliesPage()),
  ],
);

/// 玻璃胶囊 TabBar（首页 / 新增 / 个人）
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _TabSpec('/', Icons.home_rounded, '首页'),
    _TabSpec('/recipe/edit', Icons.add_rounded, '新增'),
    _TabSpec('/profile', Icons.person_rounded, '个人'),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      // body 延伸到屏幕底（含 TabBar 区域）：页面渐变填满整屏，
      // 玻璃胶囊的 backdrop-blur 才有内容可透，也不会露出黑边
      extendBody: true,
      // 给内容多预留一个胶囊 TabBar 的高度，滚动到底时不被遮挡
      body: MediaQuery(
        data: mq.copyWith(
          padding: mq.padding.copyWith(bottom: mq.padding.bottom + 84),
        ),
        child: child,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: GlassCard(
            radius: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            blur: false,   // 底下是持续动画的极光晕，开真·模糊会每帧重算，得不偿失
            child: Row(
              children: _tabs.map((t) {
                final active = loc == t.path || (t.path != '/' && loc.startsWith(t.path));
                return Expanded(
                  child: _GlassTab(item: t, active: active, onTap: () => context.go(t.path)),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  final String path;
  final IconData icon;
  final String label;
  const _TabSpec(this.path, this.icon, this.label);
}

class _GlassTab extends StatelessWidget {
  const _GlassTab({required this.item, required this.active, required this.onTap});
  final _TabSpec item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: active
              ? const [BoxShadow(color: AppColors.shadowChip, blurRadius: 14, offset: Offset(0, 4))]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 22,
                color: active ? Colors.white : AppColors.text2),
            const SizedBox(height: 2),
            Text(item.label,
                style: TextStyle(
                  fontSize: 11,
                  color: active ? Colors.white : AppColors.text2,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }
}
