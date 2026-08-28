import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/token_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/providers.dart';
import '../../shared/models.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _register = false;
  final _nick = TextEditingController();
  // 双地址：默认填充已存的局域网/公网地址；都没有时局域网填平台默认地址（web→同源代理，真机→本机后端）
  final _lan = TextEditingController(text: TokenStore.instance.lanUrl ?? ApiClient.defaultServerUrl);
  final _pub = TextEditingController(text: TokenStore.instance.pubUrl ?? '');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _u.dispose();
    _p.dispose();
    _nick.dispose();
    _lan.dispose();
    _pub.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final lan = _lan.text.trim();
    final pub = _pub.text.trim();
    final u = _u.text.trim(), p = _p.text;
    if (lan.isEmpty && pub.isEmpty) {
      setState(() => _error = '请至少填写一个服务器地址');
      return;
    }
    if (u.isEmpty || p.isEmpty) {
      setState(() => _error = '请输入用户名和密码');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      // 保存双地址并探测选路（家里通局域网/外面通公网），再发登录请求
      await TokenStore.instance.setAddresses(lan: lan, pub: pub);
      await ApiClient.selectActive();
      final auth = ref.read(authRepoProvider);
      TokenVO t;
      if (_register) {
        if (_nick.text.trim().isEmpty) {
          setState(() { _loading = false; _error = '请输入昵称'; });
          return;
        }
        t = await auth.register(u, p, _nick.text.trim());
      } else {
        t = await auth.login(u, p);
      }
      await TokenStore.instance.setTokens(t.accessToken, t.refreshToken);
      await TokenStore.instance.setProfile(nickname: t.nickname, avatarUrl: t.avatarUrl);
      ref.invalidate(profileProvider);
      ref.invalidate(favoritesProvider);
      final from = GoRouterState.of(context).uri.queryParameters['from'];
      if (mounted) context.go(from ?? '/');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } on DioException catch (e) {
      setState(() => _error = '无法连接服务器：${e.message ?? '网络错误'}，请检查地址');
    } catch (e) {
      setState(() => _error = '网络错误，请检查服务器地址与网络');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 被动踢回登录页的原因（连不上服务器 / 登录过期），据此展示提示横幅
    final kickReason = GoRouterState.of(context).uri.queryParameters['reason'];
    return GradientBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo 玻璃盒
              Center(
                child: GlassCard(
                  radius: 28,
                  padding: const EdgeInsets.all(24),
                  blur: false,
                  child: Column(
                    children: const [
                      Icon(Icons.restaurant_menu_rounded, size: 44, color: AppColors.orange),
                      SizedBox(height: 6),
                      Text('食光记', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text1)),
                      SizedBox(height: 2),
                      Text('记录每一道家的味道', style: TextStyle(fontSize: 12, color: AppColors.text2, letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
              if (kickReason != null) ...[
                const SizedBox(height: 20),
                _KickBanner(reason: kickReason),
              ],
              const SizedBox(height: 36),
              // 局域网地址（家里 WiFi 直连 NAS）
              TextField(
                controller: _lan,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  hintText: '局域网地址（如 http://192.168.1.111:8080）',
                  prefixIcon: Icon(Icons.wifi_rounded, color: AppColors.text2),
                ),
                style: const TextStyle(color: AppColors.text1, fontSize: 14),
              ),
              const SizedBox(height: 12),
              // 公网地址（出门在外走公网访问）
              TextField(
                controller: _pub,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  hintText: '公网地址（如 https://nas.com:6535，选填）',
                  prefixIcon: Icon(Icons.public_rounded, color: AppColors.text2),
                ),
                style: const TextStyle(color: AppColors.text1, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('两个都填时自动选择能连通的那个，回家走局域网、出门走公网',
                    style: TextStyle(fontSize: 10, color: AppColors.text2)),
              ),
              const SizedBox(height: 12),
              // 用户名
              TextField(
                controller: _u,
                decoration: const InputDecoration(hintText: '用户名', prefixIcon: Icon(Icons.person_outline, color: AppColors.text2)),
                style: const TextStyle(color: AppColors.text1),
              ),
              const SizedBox(height: 12),
              // 密码
              TextField(
                controller: _p,
                obscureText: true,
                decoration: const InputDecoration(hintText: '密码', prefixIcon: Icon(Icons.lock_outline, color: AppColors.text2)),
                style: const TextStyle(color: AppColors.text1),
              ),
              if (_register) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _nick,
                  decoration: const InputDecoration(hintText: '昵称', prefixIcon: Icon(Icons.badge_outlined, color: AppColors.text2)),
                  style: const TextStyle(color: AppColors.text1),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppColors.heart, fontSize: 12)),
              ],
              const SizedBox(height: 22),
              // 渐变登录按钮
              _GradientButton(
                label: _register ? '注册并登录' : '登录',
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() { _register = !_register; _error = null; }),
                child: Text(_register ? '已有账号？去登录' : '没有账号？去注册',
                    style: const TextStyle(color: AppColors.blueBright, fontSize: 13)),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text('登录即同意《用户协议》与《隐私政策》',
                    style: TextStyle(fontSize: 11, color: AppColors.text2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 被动踢回登录页的原因提示横幅（server=连不上服务器 / auth=登录过期）
class _KickBanner extends StatelessWidget {
  const _KickBanner({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    final serverDown = reason == 'server';
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      blur: false,
      child: Row(
        children: [
          Icon(serverDown ? Icons.cloud_off_rounded : Icons.hourglass_bottom_rounded,
              size: 18, color: serverDown ? AppColors.heart : AppColors.orange),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              serverDown
                  ? '无法连接服务器，请在下方修改服务器地址后重新登录'
                  : '登录已过期，请重新登录',
              style: const TextStyle(fontSize: 12, color: AppColors.text1, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onPressed, this.loading = false});
  final String label;
  final VoidCallback onPressed;
  final bool loading;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: loading ? null : onPressed,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: [AppColors.publishGradA, AppColors.publishGradB]),
            boxShadow: const [BoxShadow(color: AppColors.shadowChip, blurRadius: 16, offset: Offset(0, 6))],
          ),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );
}
