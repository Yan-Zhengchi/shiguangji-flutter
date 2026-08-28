import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/network/api_client.dart';
import 'core/network/token_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 亮色主题：状态栏深色图标、透明底
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  await TokenStore.instance.init();   // 启动时加载持久化的 Token + 服务器地址
  ApiClient.init();                   // 按已存的服务器地址构造 dio
  // 双地址自动选路（异步探测，不阻塞首帧）：局域网优先，
  // 探测发现该换路时静默切换；请求失败时拦截器还会再做故障转移兜底
  ApiClient.selectActive();
  // 从后台回到前台时重新选路：人在外走公网，回家打开 App 即自动切回局域网
  AppLifecycleListener(onResume: () => ApiClient.selectActive());
  ApiClient.onAuthFailed = (reason) {   // 注入登录态失效跳转（401 刷新失败 / 连不上服务器）
    // 登录页带 reason（展示提示）与 from（重登后回跳来源页）
    final current = appRouter.routeInformationProvider.value.uri.toString();
    final params = <String, String>{
      'reason': reason == AuthFailureReason.serverUnreachable ? 'server' : 'auth',
      if (current.isNotEmpty && !current.startsWith('/login')) 'from': current,
    };
    appRouter.go('/login?${Uri(queryParameters: params).query}');
  };
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
