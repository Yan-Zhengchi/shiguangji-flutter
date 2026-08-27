import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories.dart';
import '../shared/models.dart';

// ---------- 仓库单例 ----------
final recipeRepoProvider = Provider((ref) => RecipeRepository());
final favoriteRepoProvider = Provider((ref) => FavoriteRepository());
final familyRepoProvider = Provider((ref) => FamilyRepository());
final userRepoProvider = Provider((ref) => UserRepository());
final authRepoProvider = Provider((ref) => AuthRepository());

// ---------- 分类（缓存）----------
final categoriesProvider = FutureProvider<List<CategoryVO>>((ref) async {
  return ref.watch(recipeRepoProvider).categories();
});

// ---------- 首页瀑布流 ----------
final homeFeedProvider =
    FutureProvider.family<List<RecipeCardVO>, ({String? categoryId, int page})>(
        (ref, arg) async {
  return ref.watch(recipeRepoProvider).home(categoryId: arg.categoryId, page: arg.page);
});

// ---------- 热门榜 ----------
final hotProvider = FutureProvider<List<RecipeCardVO>>(
    (ref) => ref.watch(recipeRepoProvider).hot(limit: 10));

// ---------- 详情 ----------
final detailProvider = FutureProvider.family<RecipeDetailVO, String>(
    (ref, id) => ref.watch(recipeRepoProvider).detail(id));

// ---------- 搜索 ----------
final searchProvider = FutureProvider.family<List<RecipeCardVO>, String>(
    (ref, keyword) => ref.watch(recipeRepoProvider).search(keyword));

final hotKeywordsProvider = FutureProvider<List<String>>(
    (ref) => ref.watch(recipeRepoProvider).hotKeywords());

final searchHistoryProvider = FutureProvider<List<String>>(
    (ref) => ref.watch(recipeRepoProvider).history());

// ---------- 收藏 ----------
final favoritesProvider =
    FutureProvider<List<RecipeCardVO>>((ref) => ref.watch(favoriteRepoProvider).list());

// ---------- 个人 ----------
final profileProvider = FutureProvider<ProfileVO>(
    (ref) => ref.watch(userRepoProvider).profile());

final userRecipesProvider =
    FutureProvider<List<RecipeCardVO>>((ref) => ref.watch(recipeRepoProvider).userRecipes());

// ---------- 家庭 ----------
final familiesProvider =
    FutureProvider<List<FamilyVO>>((ref) => ref.watch(familyRepoProvider).list());

final familyRecipesProvider = FutureProvider.family<List<RecipeCardVO>, String>(
    (ref, familyId) => ref.watch(familyRepoProvider).recipes(familyId));

// ---------- 当前登录用户信息（轻量，基于 TokenStore）----------
final currentNicknameProvider = Provider<String?>((ref) => null);
