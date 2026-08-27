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

/// 鉴权失效回调（由 router 注入，避免循环依赖）
typedef OnAuthFailed = void Function();

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

  /// 登录页输入新地址后调用：更新内存 + 持久化 + 切换 dio baseUrl
  static Future<void> setServerUrl(String url) async {
    final u = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    serverUrl = u;
    if (_dio != null) {
      _dio!.options.baseUrl = '$u/api/v1/';
    }
    await TokenStore.instance.setServerUrl(u);
  }

  static Dio _build() {
    final d = Dio(BaseOptions(
      baseUrl: apiBase,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      validateStatus: (_) => true,  // 所有状态码都走正常流程，由 unwrap 解析业务错误码
    ));
    // 自签证书兼容：信任所有 SSL 证书（仅用于自托管 NAS 场景）
    if (!kIsWeb) {
      (d.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }
    d.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => print('[DIO] $o'),
    ));
    d.interceptors.add(AuthInterceptor());
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
    final is401 = resp?.statusCode == 401;
    final hasRefresh = TokenStore.instance.refresh != null;
    if (is401 && hasRefresh && !_refreshing && !_isAuthPath(err.requestOptions.path)) {
      _refreshing = true;
      try {
        final newAccess = await _refresh();
        _refreshing = false;
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        final retry = await Dio().fetch(err.requestOptions);
        handler.resolve(retry);
        return;
      } catch (_) {
        _refreshing = false;
        await TokenStore.instance.clear();
        ApiClient.onAuthFailed?.call();
      }
    }
    handler.next(err);
  }

  Future<String> _refresh() async {
    final r = await Dio(BaseOptions(baseUrl: ApiClient.apiBase))
        .post('auth/refresh', data: {'refreshToken': TokenStore.instance.refresh});
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
