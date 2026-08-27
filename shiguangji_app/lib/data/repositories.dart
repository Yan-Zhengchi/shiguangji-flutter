import '../core/network/api_client.dart';
import '../shared/models.dart';

/// 菜谱仓库（首页/分类/详情/搜索/发布编辑删除/个人菜谱）
class RecipeRepository {
  Future<List<CategoryVO>> categories() async {
    final r = await ApiClient.dio.get('categories');
    return ApiClient.unwrapList<CategoryVO>(r, CategoryVO.fromJson);
  }

  Future<List<RecipeCardVO>> home({String? categoryId, int page = 1, int size = 6}) async {
    final r = await ApiClient.dio.get('recipes/home',
        queryParameters: {'categoryId': categoryId, 'page': page, 'size': size});
    return ApiClient.unwrapList<RecipeCardVO>(r, RecipeCardVO.fromJson);
  }

  Future<List<RecipeCardVO>> hot({int limit = 10}) async {
    final r = await ApiClient.dio.get('recipes/hot', queryParameters: {'limit': limit});
    return ApiClient.unwrapList<RecipeCardVO>(r, RecipeCardVO.fromJson);
  }

  Future<RecipeDetailVO> detail(String id) async {
    final r = await ApiClient.dio.get('recipes/$id');
    return ApiClient.unwrap<RecipeDetailVO>(r, RecipeDetailVO.fromJson);
  }

  Future<String> publish(Map<String, dynamic> body) async {
    final r = await ApiClient.dio.post('recipes', data: body);
    final m = r.data as Map;
    if (m['code'] != 0) throw ApiException(m['code'] ?? -1, m['message'] ?? '发布失败');
    return m['data'].toString();
  }

  Future<void> update(String id, Map<String, dynamic> body) async {
    final r = await ApiClient.dio.put('recipes/$id', data: body);
    final m = r.data as Map;
    if (m['code'] != 0) throw ApiException(m['code'] ?? -1, m['message'] ?? '修改失败');
  }

  Future<void> delete(String id) async {
    await ApiClient.dio.delete('recipes/$id');
  }

  Future<List<RecipeCardVO>> search(String keyword, {int page = 1, int size = 10}) async {
    final r = await ApiClient.dio.get('search',
        queryParameters: {'keyword': keyword, 'page': page, 'size': size});
    return ApiClient.unwrapList<RecipeCardVO>(r, RecipeCardVO.fromJson);
  }

  Future<List<String>> hotKeywords() async {
    final r = await ApiClient.dio.get('search/hot');
    final m = r.data as Map;
    if (m['code'] != 0) return [];
    return (m['data'] as List?)?.map((e) => e.toString()).toList() ?? [];
  }

  Future<List<String>> history() async {
    final r = await ApiClient.dio.get('search/history');
    final m = r.data as Map;
    if (m['code'] != 0) return [];
    return (m['data'] as List?)?.map((e) => e.toString()).toList() ?? [];
  }

  Future<void> clearHistory() async {
    await ApiClient.dio.delete('search/history');
  }

  Future<List<RecipeCardVO>> userRecipes({int page = 1, int size = 20}) async {
    final r = await ApiClient.dio.get('users/recipes',
        queryParameters: {'page': page, 'size': size});
    return ApiClient.unwrapList<RecipeCardVO>(r, RecipeCardVO.fromJson);
  }
}

/// 收藏仓库
class FavoriteRepository {
  Future<void> favorite(String recipeId) async {
    await ApiClient.dio.post('favorites/$recipeId');
  }

  Future<void> unfavorite(String recipeId) async {
    await ApiClient.dio.delete('favorites/$recipeId');
  }

  Future<List<RecipeCardVO>> list({int page = 1, int size = 20}) async {
    final r = await ApiClient.dio.get('favorites',
        queryParameters: {'page': page, 'size': size});
    return ApiClient.unwrapList<RecipeCardVO>(r, RecipeCardVO.fromJson);
  }
}

/// 家庭仓库
class FamilyRepository {
  Future<List<FamilyVO>> list() async {
    final r = await ApiClient.dio.get('families');
    return ApiClient.unwrapList<FamilyVO>(r, FamilyVO.fromJson);
  }

  Future<FamilyVO> create(String name, {String? coverUrl}) async {
    final r = await ApiClient.dio.post('families', data: {'name': name, 'coverUrl': coverUrl});
    return ApiClient.unwrap<FamilyVO>(r, FamilyVO.fromJson);
  }

  Future<void> invite(String familyId, {String? username, String? phone}) async {
    await ApiClient.dio.post('families/$familyId/members',
        data: {'username': username, 'phone': phone});
  }

  Future<List<RecipeCardVO>> recipes(String familyId) async {
    final r = await ApiClient.dio.get('families/$familyId/recipes');
    return ApiClient.unwrapList<RecipeCardVO>(r, RecipeCardVO.fromJson);
  }

  Future<void> addRecipe(String familyId, String recipeId) async {
    await ApiClient.dio.post('families/$familyId/recipes/$recipeId');
  }

  Future<void> removeRecipe(String familyId, String recipeId) async {
    await ApiClient.dio.delete('families/$familyId/recipes/$recipeId');
  }
}

/// 用户仓库
class UserRepository {
  Future<ProfileVO> profile() async {
    final r = await ApiClient.dio.get('users/profile');
    return ApiClient.unwrap<ProfileVO>(r, ProfileVO.fromJson);
  }

  Future<ProfileVO> update({String? nickname, String? phone, String? avatarUrl}) async {
    final r = await ApiClient.dio.put('users/profile',
        data: {'nickname': nickname, 'phone': phone, 'avatarUrl': avatarUrl});
    return ApiClient.unwrap<ProfileVO>(r, ProfileVO.fromJson);
  }
}

/// 鉴权仓库（登录/注册/登出/me）
class AuthRepository {
  Future<TokenVO> register(String username, String password, String nickname, {String? phone}) async {
    final r = await ApiClient.dio.post('auth/register',
        data: {'username': username, 'password': password, 'nickname': nickname, 'phone': phone});
    return ApiClient.unwrap<TokenVO>(r, TokenVO.fromJson);
  }

  Future<TokenVO> login(String username, String password) async {
    final r = await ApiClient.dio.post('auth/login',
        data: {'username': username, 'password': password});
    return ApiClient.unwrap<TokenVO>(r, TokenVO.fromJson);
  }

  Future<void> logout({String? refreshToken}) async {
    await ApiClient.dio.post('auth/logout', data: {'refreshToken': refreshToken});
  }
}
