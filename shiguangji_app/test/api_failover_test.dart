import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiguangji/core/network/api_client.dart';
import 'package:shiguangji/core/network/token_store.dart';

/// 方案 A 双地址选路 / 故障转移测试。
/// 用测试内自建的 HttpServer 模拟"局域网后端"和"公网后端"，
/// 停掉其中一个模拟网络切换，验证拦截器自动切换并无缝重放请求。
void main() {
  late HttpServer lan;
  late HttpServer pub;
  final lanHits = <String>[];
  final pubHits = <String>[];

  /// 起一个假后端：/actuator/health 回 200，/api/v1/* 回 Result JSON，并记录请求路径
  Future<HttpServer> startFake(List<String> hits) async {
    final s = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    s.listen((req) async {
      hits.add(req.uri.path);
      req.response.statusCode = 200;
      if (req.uri.path == '/actuator/health') {
        req.response.write('{"status":"UP"}');
      } else {
        req.response.headers.contentType = ContentType.json;
        req.response.write('{"code":0,"message":"ok","data":null}');
      }
      await req.response.close();
    });
    return s;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    lanHits.clear();
    pubHits.clear();
    lan = await startFake(lanHits);
    pub = await startFake(pubHits);
    ApiClient.onAuthFailed = null;
    await TokenStore.instance.init();
    ApiClient.init();
  });

  tearDown(() async {
    ApiClient.onAuthFailed = null;
    await lan.close(force: true);
    await pub.close(force: true);
  });

  /// 连不上的地址（端口 1 基本必拒绝，探测/请求都会快速失败）
  const dead = 'http://127.0.0.1:1';

  test('私网地址判定：迁移分类用', () {
    expect(TokenStore.isPrivateAddress('http://192.168.1.111:8080'), isTrue);
    expect(TokenStore.isPrivateAddress('http://10.0.0.5:8080'), isTrue);
    expect(TokenStore.isPrivateAddress('http://172.16.0.9:8080'), isTrue);
    expect(TokenStore.isPrivateAddress('http://172.31.255.1:8080'), isTrue);
    expect(TokenStore.isPrivateAddress('http://172.32.0.1:8080'), isFalse);
    expect(TokenStore.isPrivateAddress('http://localhost:8080'), isTrue);
    expect(TokenStore.isPrivateAddress('https://nas.example.com:6535'), isFalse);
  });

  test('旧单地址迁移：私网归局域网 / 域名归公网', () async {
    SharedPreferences.setMockInitialValues({'sgj_server': 'http://192.168.1.111:8080'});
    await TokenStore.instance.init();
    expect(TokenStore.instance.lanUrl, 'http://192.168.1.111:8080');
    expect(TokenStore.instance.pubUrl, isNull);

    SharedPreferences.setMockInitialValues({'sgj_server': 'https://nas.example.com:6535'});
    await TokenStore.instance.init();
    expect(TokenStore.instance.lanUrl, isNull);
    expect(TokenStore.instance.pubUrl, 'https://nas.example.com:6535');
  });

  test('setAddresses 归一化 + otherAddress', () async {
    await TokenStore.instance.setAddresses(lan: 'http://a.b/', pub: '  ');
    expect(TokenStore.instance.lanUrl, 'http://a.b');
    expect(TokenStore.instance.pubUrl, isNull);

    await TokenStore.instance.setAddresses(lan: 'http://a.b', pub: 'http://c.d/');
    await TokenStore.instance.setActive('http://a.b');
    expect(TokenStore.instance.activeIsLan, isTrue);
    expect(TokenStore.instance.otherAddress, 'http://c.d');
    await TokenStore.instance.setActive('http://c.d');
    expect(TokenStore.instance.otherAddress, 'http://a.b');
  });

  test('selectActive：局域网不通自动选公网', () async {
    await TokenStore.instance.setAddresses(lan: dead, pub: 'http://127.0.0.1:${pub.port}');
    await ApiClient.selectActive();
    expect(ApiClient.serverUrl, 'http://127.0.0.1:${pub.port}');
    expect(TokenStore.instance.activeIsLan, isFalse);
  });

  test('selectActive：局域网通则优先局域网', () async {
    await TokenStore.instance.setAddresses(
        lan: 'http://127.0.0.1:${lan.port}', pub: 'http://127.0.0.1:${pub.port}');
    await ApiClient.selectActive();
    expect(ApiClient.serverUrl, 'http://127.0.0.1:${lan.port}');
    expect(TokenStore.instance.activeIsLan, isTrue);
  });

  test('回到家里：公网也通，仍自动切回局域网', () async {
    await TokenStore.instance.setAddresses(
        lan: 'http://127.0.0.1:${lan.port}', pub: 'http://127.0.0.1:${pub.port}');
    // 模拟"在外面"的状态：上次走的是公网
    await ApiClient.switchActive('http://127.0.0.1:${pub.port}');
    expect(TokenStore.instance.activeIsLan, isFalse);
    // 回家打开 App（回到前台触发 re-select）：局域网通 → 切回，哪怕公网也通
    await ApiClient.selectActive();
    expect(ApiClient.serverUrl, 'http://127.0.0.1:${lan.port}');
    expect(TokenStore.instance.activeIsLan, isTrue);
  });

  test('当前地址挂掉：拦截器自动切另一条路并无缝重放', () async {
    await TokenStore.instance.setAddresses(
        lan: 'http://127.0.0.1:${lan.port}', pub: 'http://127.0.0.1:${pub.port}');
    await ApiClient.selectActive();
    expect(ApiClient.serverUrl, 'http://127.0.0.1:${lan.port}');

    // "离开家"：局域网后端停机
    await lan.close(force: true);

    final kicked = <AuthFailureReason>[];
    ApiClient.onAuthFailed = (r) => kicked.add(r);

    // 请求打到已停机的局域网 → 探测公网通 → 切换 → 重放成功
    final resp = await ApiClient.dio.get('ping');
    expect(resp.data['code'], 0);
    expect(ApiClient.serverUrl, 'http://127.0.0.1:${pub.port}');
    expect(pubHits, contains('/api/v1/ping'));
    expect(kicked, isEmpty);  // 切换成功不踢登录
  });

  test('两条路都不通：清登录态并回调 serverUnreachable', () async {
    await TokenStore.instance.setAddresses(
        lan: 'http://127.0.0.1:${lan.port}', pub: 'http://127.0.0.1:${pub.port}');
    await ApiClient.selectActive();
    await TokenStore.instance.setTokens('access-x', 'refresh-x');
    expect(TokenStore.instance.isAuthed, isTrue);

    // 全部停机
    await lan.close(force: true);
    await pub.close(force: true);

    final kicked = <AuthFailureReason>[];
    ApiClient.onAuthFailed = (r) => kicked.add(r);

    await expectLater(ApiClient.dio.get('ping'), throwsA(isA<DioException>()));
    expect(TokenStore.instance.isAuthed, isFalse);  // 登录态已清
    expect(kicked, [AuthFailureReason.serverUnreachable]);
  });
}
