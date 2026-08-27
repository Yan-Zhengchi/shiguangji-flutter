/// 食光记 DTO（手写 fromJson，与后端契约一致）
/// 注意：后端 Long 全局序列化为 String，故 id/userId 等用 String 承接更安全。
library;

String? _str(dynamic v) => v?.toString();
int? _int(dynamic v) => v is int ? v : (v is String ? int.tryParse(v) : (v is num ? v.toInt() : null));

class TokenVO {
  final String userId;
  final String username;
  final String nickname;
  final String? avatarUrl;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  TokenVO({required this.userId, required this.username, required this.nickname,
    this.avatarUrl, required this.accessToken, required this.refreshToken, required this.expiresIn});
  factory TokenVO.fromJson(Map<String, dynamic> j) => TokenVO(
    userId: _str(j['userId']) ?? '', username: j['username'] ?? '', nickname: j['nickname'] ?? '',
    avatarUrl: _str(j['avatarUrl']), accessToken: j['accessToken'] ?? '',
    refreshToken: j['refreshToken'] ?? '', expiresIn: _int(j['expiresIn']) ?? 7200,
  );
}

class CategoryVO {
  final String id;
  final String name;
  final String? icon;
  final int? sort;
  CategoryVO({required this.id, required this.name, this.icon, this.sort});
  factory CategoryVO.fromJson(Map<String, dynamic> j) => CategoryVO(
    id: _str(j['id']) ?? '', name: j['name'] ?? '', icon: _str(j['icon']), sort: _int(j['sort']),
  );
}

class RecipeCardVO {
  final String id;
  final String title;
  final String? coverUrl;
  final String? authorName;
  final int favoriteCount;
  final double? imgRatio;
  RecipeCardVO({required this.id, required this.title, this.coverUrl, this.authorName,
    this.favoriteCount = 0, this.imgRatio});
  factory RecipeCardVO.fromJson(Map<String, dynamic> j) => RecipeCardVO(
    id: _str(j['id']) ?? '', title: j['title'] ?? '', coverUrl: _str(j['coverUrl']),
    authorName: _str(j['authorName']), favoriteCount: _int(j['favoriteCount']) ?? 0,
    imgRatio: (j['imgRatio'] is num) ? (j['imgRatio'] as num).toDouble() : null,
  );
}

class IngredientVO {
  final String type;   // 主料 / 配料
  final String name;
  final String? amount;
  IngredientVO({required this.type, required this.name, this.amount});
  factory IngredientVO.fromJson(Map<String, dynamic> j) => IngredientVO(
    type: j['type'] ?? '主料', name: j['name'] ?? '', amount: _str(j['amount']),
  );
}

class ExperienceVO {
  final String? text;
  final String? happenedAt;   // yyyy-MM-dd
  final int? count;
  ExperienceVO({this.text, this.happenedAt, this.count});
  factory ExperienceVO.fromJson(Map<String, dynamic> j) => ExperienceVO(
    text: _str(j['text']), happenedAt: _str(j['happenedAt']), count: _int(j['count']),
  );
}

class RecipeDetailVO {
  final String id;
  final String title;
  final String authorName;
  final String? authorAvatar;
  final int favoriteCount;
  final int viewCount;
  final int? cookMinutes;
  final String difficulty;
  final String servings;
  final String? categoryName;
  final String? description;
  final List<IngredientVO> ingredients;
  final List<String> tools;
  final List<String> steps;
  final String? tips;
  final List<String> notes;
  final ExperienceVO? experience;
  final bool favorite;
  final List<String> images;
  RecipeDetailVO({
    required this.id, required this.title, required this.authorName, this.authorAvatar,
    this.favoriteCount = 0, this.viewCount = 0, this.cookMinutes, required this.difficulty,
    required this.servings, this.categoryName, this.description, this.ingredients = const [],
    this.tools = const [], this.steps = const [], this.tips, this.notes = const [],
    this.experience, this.favorite = false, this.images = const [],
  });
  factory RecipeDetailVO.fromJson(Map<String, dynamic> j) => RecipeDetailVO(
    id: _str(j['id']) ?? '', title: j['title'] ?? '', authorName: j['authorName'] ?? '',
    authorAvatar: _str(j['authorAvatar']),
    favoriteCount: _int(j['favoriteCount']) ?? 0, viewCount: _int(j['viewCount']) ?? 0,
    cookMinutes: _int(j['cookMinutes']), difficulty: j['difficulty'] ?? '中等',
    servings: j['servings'] ?? '', categoryName: _str(j['categoryName']),
    description: _str(j['description']),
    ingredients: (j['ingredients'] as List?)?.map((e) => IngredientVO.fromJson(Map<String, dynamic>.from(e))).toList() ?? [],
    tools: (j['tools'] as List?)?.map((e) => e.toString()).toList() ?? [],
    steps: (j['steps'] as List?)?.map((e) => e.toString()).toList() ?? [],
    tips: _str(j['tips']),
    notes: (j['notes'] as List?)?.map((e) => e.toString()).toList() ?? [],
    experience: j['experience'] is Map ? ExperienceVO.fromJson(Map<String, dynamic>.from(j['experience'])) : null,
    favorite: j['favorite'] == true,
    images: (j['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
  );
}

class ProfileStatsVO {
  final int recipeCount;
  final int favoriteCount;
  final int familyCount;
  ProfileStatsVO({this.recipeCount = 0, this.favoriteCount = 0, this.familyCount = 0});
  factory ProfileStatsVO.fromJson(Map<String, dynamic> j) => ProfileStatsVO(
    recipeCount: _int(j['recipeCount']) ?? 0,
    favoriteCount: _int(j['favoriteCount']) ?? 0,
    familyCount: _int(j['familyCount']) ?? 0,
  );
}

class ProfileVO {
  final String userId;
  final String username;
  final String nickname;
  final String? phone;
  final String? avatarUrl;
  final ProfileStatsVO stats;
  ProfileVO({required this.userId, required this.username, required this.nickname,
    this.phone, this.avatarUrl, required this.stats});
  factory ProfileVO.fromJson(Map<String, dynamic> j) => ProfileVO(
    userId: _str(j['userId']) ?? '', username: j['username'] ?? '', nickname: j['nickname'] ?? '',
    phone: _str(j['phone']), avatarUrl: _str(j['avatarUrl']),
    stats: j['stats'] is Map ? ProfileStatsVO.fromJson(Map<String, dynamic>.from(j['stats'])) : ProfileStatsVO(),
  );
}

class FamilyVO {
  final String id;
  final String name;
  final String? coverUrl;
  final String ownerId;
  final int memberCount;
  final String? createdAt;
  FamilyVO({required this.id, required this.name, this.coverUrl, required this.ownerId,
    this.memberCount = 0, this.createdAt});
  factory FamilyVO.fromJson(Map<String, dynamic> j) => FamilyVO(
    id: _str(j['id']) ?? '', name: j['name'] ?? '', coverUrl: _str(j['coverUrl']),
    ownerId: _str(j['ownerId']) ?? '', memberCount: _int(j['memberCount']) ?? 0,
    createdAt: _str(j['createdAt']),
  );
}
