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
  String? _lanUrl;      // 局域网地址（家里 WiFi 直连 NAS，如 http://192.168.1.111:8080）
  String? _pubUrl;      // 公网地址（外网访问，如 https://nas.com:6535）
  bool? _activeIsLan;   // 上次实际使用的地址（true=局域网 / false=公网 / null=未选择），启动时优先复用
  String? _serverUrl;   // 当前生效地址（内存缓存，切换地址时由 ApiClient 同步更新）

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _access = _prefs!.getString('sgj_access');
    _refresh = _prefs!.getString('sgj_refresh');
    _nickname = _prefs!.getString('sgj_nickname');
    _avatarUrl = _prefs!.getString('sgj_avatar');
    _lanUrl = _prefs!.getString('sgj_lan');
    _pubUrl = _prefs!.getString('sgj_pub');
    _activeIsLan = _prefs!.getBool('sgj_active_lan');
    _serverUrl = _prefs!.getString('sgj_server');
    // 旧版本只存单地址（sgj_server）：迁移到双地址字段。
    // 私网地址归局域网，其余（域名/公网 IP）归公网，sgj_server 继续充当"当前生效地址"
    if (_serverUrl != null && _lanUrl == null && _pubUrl == null) {
      if (isPrivateAddress(_serverUrl!)) {
        _lanUrl = _serverUrl;
        await _prefs!.setString('sgj_lan', _serverUrl!);
      } else {
        _pubUrl = _serverUrl;
        await _prefs!.setString('sgj_pub', _serverUrl!);
      }
    }
  }

  String? get access => _access;
  String? get refresh => _refresh;
  String? get nickname => _nickname;
  String? get avatarUrl => _avatarUrl;
  /// 后端服务器地址（不带尾斜杠），登录页输入后持久化
  String? get serverUrl => _serverUrl;
  String? get lanUrl => _lanUrl;
  String? get pubUrl => _pubUrl;
  bool? get activeIsLan => _activeIsLan;
  bool get isAuthed => _access != null;

  /// 除当前生效地址外的另一条路（故障转移目标），只配了一个地址时返回 null
  String? get otherAddress {
    if (_activeIsLan == true) return _pubUrl;
    if (_activeIsLan == false) return _lanUrl;
    // 未选择过：生效地址是哪个，另一个就是备选
    if (_serverUrl == _lanUrl) return _pubUrl;
    if (_serverUrl == _pubUrl) return _lanUrl;
    return null;
  }

  Future<void> setTokens(String access, String refresh) async {
    _access = access;
    _refresh = refresh;
    await _prefs?.setString('sgj_access', access);
    await _prefs?.setString('sgj_refresh', refresh);
  }

  /// 保存两个服务器地址（至少一个非空；空串视为清除该地址）
  Future<void> setAddresses({String? lan, String? pub}) async {
    _lanUrl = _normalize(lan);
    _pubUrl = _normalize(pub);
    if (_lanUrl != null) {
      await _prefs?.setString('sgj_lan', _lanUrl!);
    } else {
      await _prefs?.remove('sgj_lan');
    }
    if (_pubUrl != null) {
      await _prefs?.setString('sgj_pub', _pubUrl!);
    } else {
      await _prefs?.remove('sgj_pub');
    }
    // 地址变了，上次的选择作废，等 selectActive 重新探测后由 setActive 写回
    _activeIsLan = null;
    await _prefs?.remove('sgj_active_lan');
  }

  /// 记录当前实际生效的地址（ApiClient 切换时调用）
  Future<void> setActive(String url) async {
    _serverUrl = url;
    await _prefs?.setString('sgj_server', url);
    _activeIsLan = url == _lanUrl ? true : (url == _pubUrl ? false : null);
    if (_activeIsLan != null) {
      await _prefs?.setBool('sgj_active_lan', _activeIsLan!);
    }
  }

  /// 去掉尾斜杠，空串归一为 null
  static String? _normalize(String? url) {
    if (url == null) return null;
    final t = url.trim();
    if (t.isEmpty) return null;
    return t.endsWith('/') ? t.substring(0, t.length - 1) : t;
  }

  /// 私网地址判定：192.168.* / 10.* / 172.16-31.* / localhost / 127.*
  /// 用于旧单地址迁移分类（决定存 lan 还是 pub）
  static bool isPrivateAddress(String url) {
    try {
      final host = Uri.parse(url).host;
      if (host == 'localhost' || host == '127.0.0.1') return true;
      if (host.startsWith('192.168.') || host.startsWith('10.')) return true;
      final m = RegExp(r'^172\.(\d+)\.').firstMatch(host);
      if (m != null) {
        final second = int.tryParse(m.group(1)!) ?? 0;
        if (second >= 16 && second <= 31) return true;
      }
      return false;
    } catch (_) {
      return false;
    }
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
