import 'package:shared_preferences/shared_preferences.dart';

/// Token 持久化（单例）：shared_preferences 存储 access/refresh
/// 启动时在 main() 调 init() 预加载，之后可同步取用（路由守卫需要同步访问）
class TokenStore {
  TokenStore._();
  static final TokenStore instance = TokenStore._();

  SharedPreferences? _prefs;
  String? _access;
  String? _refresh;
  String? _nickname;
  String? _avatarUrl;
  String? _serverUrl;   // 后端服务器地址（用户在登录页输入，如 https://nas.com:6535）

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _access = _prefs!.getString('sgj_access');
    _refresh = _prefs!.getString('sgj_refresh');
    _nickname = _prefs!.getString('sgj_nickname');
    _avatarUrl = _prefs!.getString('sgj_avatar');
    _serverUrl = _prefs!.getString('sgj_server');
  }

  String? get access => _access;
  String? get refresh => _refresh;
  String? get nickname => _nickname;
  String? get avatarUrl => _avatarUrl;
  /// 后端服务器地址（不带尾斜杠），登录页输入后持久化
  String? get serverUrl => _serverUrl;
  bool get isAuthed => _access != null;

  Future<void> setTokens(String access, String refresh) async {
    _access = access;
    _refresh = refresh;
    await _prefs?.setString('sgj_access', access);
    await _prefs?.setString('sgj_refresh', refresh);
  }

  Future<void> setServerUrl(String url) async {
    _serverUrl = url;
    await _prefs?.setString('sgj_server', url);
  }

  Future<void> setProfile({String? nickname, String? avatarUrl}) async {
    if (nickname != null) {
      _nickname = nickname;
      await _prefs?.setString('sgj_nickname', nickname);
    }
    if (avatarUrl != null) {
      _avatarUrl = avatarUrl;
      await _prefs?.setString('sgj_avatar', avatarUrl);
    }
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    _nickname = null;
    _avatarUrl = null;
    await _prefs?.remove('sgj_access');
    await _prefs?.remove('sgj_refresh');
    await _prefs?.remove('sgj_nickname');
    await _prefs?.remove('sgj_avatar');
    // 注意：clear 只清登录态，不清服务器地址（换账号不应清后端地址）
  }
}
