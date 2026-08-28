import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'token_store.dart';

/// API 异常（后端 Result.code != 0 时抛出）
class ApiException implements Exception {
  final int code;
  final String message;
  ApiException(this.code, this.message);
  @override
  String toString() => '[$code] $message';
}

/// 登录态失效原因（登录页据此展示提示）
enum AuthFailureReason {
  tokenExpired,       // 登录态过期且刷新失败
  serverUnreachable,  // 连不上后端服务器（地址变更 / 后端停机 / 断网）
}

/// 鉴权失效回调（由 router 注入，避免循环依赖）
typedef OnAuthFailed = void Function(AuthFailureReason reason);

/// 后端地址在登录页由用户输入（如 https://nas.com:6535），持久化后运行时动态生效。
/// Web 预览默认走同源代理（preview_server.py :8889），真机默认连本机 docker 后端。
class ApiClient {
  ApiClient._();

  /// 默认服务器地址：web 预览用同源代理（规避 CORS），真机/模拟器用本机后端
  static String get defaultServerUrl =>
      kIsWeb ? 'http://127.0.0.1:8889' : 'http://localhost:8080';

  /// 后端服务器地址（不带尾斜杠、不带 /api/v1）
  static String serverUrl = defaultServerUrl;

  static Dio? _dio;
  static Dio get dio {
    _dio ??= _build();
    return _dio!;
  }

  /// 完整 API 基地址 = serverUrl + /api/v1
  static String get apiBase => '$serverUrl/api/v1/';

  /// 鉴权彻底失效时的跳转回调（app_router 启动时注入）
  static OnAuthFailed? onAuthFailed;

  /// 判定是否"连不上服务器"：TCP 连接失败/超时、DNS 解析失败、TLS 握手失败。
  /// 区别于有 HTTP 响应的业务错误（401/500 等）——地址写错、后端没起、断网都属于此类。
  /// 注意 receiveTimeout（服务器已连通但响应慢）不算，避免误清登录态。
  static bool isServerUnreachable(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.unknown:
        final cause = e.error;
        return cause is SocketException || cause is HandshakeException;
      default:
        return false;
    }
  }

  /// 启动时调用：从 TokenStore 加载已存的服务器地址并构造 dio
  static void init() {
    final saved = TokenStore.instance.serverUrl;
    if (saved != null && saved.isNotEmpty) {
      serverUrl = saved;
    } else {
      serverUrl = defaultServerUrl;
    }
    _dio = _build();
  }

  /// 探测地址可达性：2 秒短超时（独立于全局 30 秒连接超时，自动回退讲究快）。
  /// 任意 HTTP 响应（含 401/403/500）都算可达——只关心"这台机器在不在"，不关心业务。
  static Future<bool> probe(String url) async {
    try {
      final d = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 3),
        validateStatus: (_) => true,
      ));
      _tolerateSelfSigned(d);
      await d.getUri(Uri.parse('$url/actuator/health'));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 从已配置的局域网/公网地址里选出可达的一条并切换生效。
  /// 启动时异步调用（不阻塞首帧），登录提交与 App 回到前台时触发。
  /// 双地址时**局域网优先**（两条都通选局域网）：出门探测不到局域网自动走公网，
  /// 回家打开 App 即自动切回局域网，不必等公网失败；都探测不通则保持现状
  /// （由请求失败的故障转移兜底）。
  static Future<void> selectActive() async {
    final lan = TokenStore.instance.lanUrl;
    final pub = TokenStore.instance.pubUrl;
    if (lan == null && pub == null) return;
    // Web 预览没有"家里/外面"的网络差异（跨域探测也不可靠），直接用第一个地址
    if (kIsWeb) {
      final pick = lan ?? pub!;
      if (serverUrl != pick) await switchActive(pick);
      return;
    }
    if (lan == null) {
      if (serverUrl != pub) await switchActive(pub!);
      return;
    }
    if (pub == null) {
      if (serverUrl != lan) await switchActive(lan);
      return;
    }
    if (await probe(lan)) {
      if (serverUrl != lan) await switchActive(lan);
    } else if (await probe(pub)) {
      if (serverUrl != pub) await switchActive(pub);
    }
  }

  static Future<bool>? _failoverFuture;

  /// 当前地址连不上时，切到另一条路（局域网↔公网自动回退）。
  /// 并发失败的多个请求共享同一次探测，不会各自重复探测、也不会切到不同地址。
  /// 返回 true 表示已切换生效，调用方（拦截器）可无缝重放原请求。
  static Future<bool> tryFailover() {
    return _failoverFuture ??= _doFailover().whenComplete(() => _failoverFuture = null);
  }

  static Future<bool> _doFailover() async {
    if (kIsWeb) return false; // web 跨域探测不可靠，不做自动切换
    final other = TokenStore.instance.otherAddress;
    if (other == null || other == serverUrl) return false;
    if (!await probe(other)) return false;
    await switchActive(other);
    return true;
  }

  /// 切换当前生效地址：更新内存 + dio baseUrl + 持久化（含"上次用的哪条路"标记）
  static Future<void> switchActive(String url) async {
    final u = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    serverUrl = u;
    if (_dio != null) {
      _dio!.options.baseUrl = '$u/api/v1/';
    }
    await TokenStore.instance.setActive(u);
  }

  static Dio _build() {
    final d = Dio(BaseOptions(
      baseUrl: apiBase,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      validateStatus: (_) => true,  // 所有状态码都走正常流程，由 unwrap 解析业务错误码
    ));
    _tolerateSelfSigned(d);
    d.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => print('[DIO] $o'),
    ));
    d.interceptors.add(AuthInterceptor());
    return d;
  }

  /// 自签证书兼容：信任所有 SSL 证书（仅用于自托管 NAS 场景）
  static void _tolerateSelfSigned(Dio d) {
    if (!kIsWeb) {
      (d.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }
  }

  /// 无拦截器的裸 dio（仅自签证书兼容）：401 刷新成功后重放原请求用。
  /// 不能用裸 `Dio()`——自签 https 下重放会握手失败。
  static Dio _plainDio() {
    final d = Dio();
    _tolerateSelfSigned(d);
    return d;
  }

  /// 把后端返回的相对图片路径（如 /uploads/xxx.png）拼成完整 URL
  static String assetUrl(String path) {
    if (path.startsWith('http')) return path;
    return '$serverUrl$path';
  }

  /// 统一解包 Result<T>：code==0 取 data，否则抛 ApiException
  static T unwrap<T>(Response r, T Function(Map<String, dynamic> json) fromJson) {
    final body = r.data;
    if (body is! Map) throw ApiException(-1, '响应格式异常');
    final code = body['code'] as int?;
    if (code != 0) throw ApiException(code ?? -1, body['message']?.toString() ?? '错误');
    final data = body['data'];
    if (data == null) return null as T;
    return fromJson(data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{});
  }

  /// 列表解包
  static List<T> unwrapList<T>(Response r, T Function(Map<String, dynamic> json) fromJson) {
    final body = r.data;
    if (body is! Map) throw ApiException(-1, '响应格式异常');
    final code = body['code'] as int?;
    if (code != 0) throw ApiException(code ?? -1, body['message']?.toString() ?? '错误');
    final list = body['data'];
    if (list is! List) return [];
    return list.map((e) => fromJson(Map<String, dynamic>.from(e))).toList();
  }
}

/// 鉴权拦截器：注入 Token；401 → 静默刷新 → 重放原请求
class AuthInterceptor extends Interceptor {
  bool _refreshing = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final access = TokenStore.instance.access;
    final isAuthEndpoint = options.path.startsWith('auth/') &&
        (options.path.contains('register') ||
            options.path.contains('login') ||
            options.path.contains('refresh'));
    if (access != null && !isAuthEndpoint) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final resp = err.response;
    // 连不上服务器：先试另一条路（局域网↔公网自动回退，不要求登录态），
    // 切换成功就无缝重放原请求（出门/回家网络切换无感）；两条路都不通时，
    // 已登录 → 清登录态踢回登录页（让用户改地址后重新登录）；
    // 未登录（登录页试地址）→ 交给页面自己的 catch 展示错误。
    if (ApiClient.isServerUnreachable(err)) {
      final switched = await ApiClient.tryFailover();
      if (switched) {
        try {
          // 重放必须指向新地址：捕获的 RequestOptions 还带着旧 baseUrl
          err.requestOptions.baseUrl = ApiClient.apiBase;
          final retry = await ApiClient._plainDio().fetch(err.requestOptions);
          handler.resolve(retry);
        } catch (_) {
          handler.next(err);  // 重放又失败 → 按原错误交给页面处理，下次请求再兜底
        }
        return;
      }
      if (TokenStore.instance.isAuthed) {
        await TokenStore.instance.clear();
        ApiClient.onAuthFailed?.call(AuthFailureReason.serverUnreachable);
      }
      handler.next(err);
      return;
    }
    final is401 = resp?.statusCode == 401;
    final hasRefresh = TokenStore.instance.refresh != null;
    if (is401 && hasRefresh && !_refreshing && !_isAuthPath(err.requestOptions.path)) {
      _refreshing = true;
      try {
        final newAccess = await _refresh();
        _refreshing = false;
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        // 刷新期间若发生了地址故障转移，重放要跟到新地址
        err.requestOptions.baseUrl = ApiClient.apiBase;
        final retry = await ApiClient._plainDio().fetch(err.requestOptions);
        handler.resolve(retry);
        return;
      } catch (e) {
        _refreshing = false;
        await TokenStore.instance.clear();
        ApiClient.onAuthFailed?.call(
            e is DioException && ApiClient.isServerUnreachable(e)
                ? AuthFailureReason.serverUnreachable
                : AuthFailureReason.tokenExpired);
      }
    }
    handler.next(err);
  }

  Future<String> _refresh() async {
    // 走主 dio（带自签证书兼容与统一超时）；onRequest 对 auth/ 路径不附加 token，
    // _refreshing 期间再收到 401 也不会递归刷新
    final r = await ApiClient.dio.post('auth/refresh',
        data: {'refreshToken': TokenStore.instance.refresh});
    final body = r.data;
    if (body is Map && body['code'] == 0) {
      final data = body['data'];
      await TokenStore.instance.setTokens(data['accessToken'], data['refreshToken']);
      return data['accessToken'] as String;
    }
    throw ApiException(40100, '刷新失败');
  }

  bool _isAuthPath(String path) => path.startsWith('auth/');
}
