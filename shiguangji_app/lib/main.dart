import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/network/api_client.dart';
import 'core/network/token_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenStore.instance.init();   // 启动时加载持久化的 Token + 服务器地址
  ApiClient.init();                   // 按已存的服务器地址构造 dio
  ApiClient.onAuthFailed = () => appRouter.go('/login');   // 注入 401 失效跳转
  runApp(const ProviderScope(child: ShiguangjiApp()));
}

class ShiguangjiApp extends StatelessWidget {
  const ShiguangjiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '食光记',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      routerConfig: appRouter,
      builder: (context, child) => GestureDetector(
        // 点击空白处收起键盘
        onTap: () => FocusScope.of(context).unfocus(),
        child: child,
      ),
    );
  }
}
