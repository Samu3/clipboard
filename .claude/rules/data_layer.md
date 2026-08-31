# Data Layer 规则

## 核心职责
Data层负责数据的获取、持久化和转换，实现Domain层定义的Repository接口。

## 数据模型 (Models)

### 使用Freezed + JSON序列化
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    required String email,
    @JsonKey(name: 'last_login_at') DateTime? lastLoginAt,
  }) = _UserModel;

  const UserModel._();

  factory UserModel.fromJson(Map<String, dynamic> json) =>
    _$UserModelFromJson(json);

  // 转换为Domain实体
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      lastLoginAt: lastLoginAt,
    );
  }

  // 从Domain实体创建
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      lastLoginAt: entity.lastLoginAt,
    );
  }
}
```

### 模型规则
- ✅ 使用`@freezed`和`@JsonSerializable`
- ✅ 使用`@JsonKey`处理字段映射
- ✅ 提供`toEntity()`方法转换为Domain实体
- ✅ 提供`fromEntity()`方法从Domain实体创建
- ✅ Model只用于数据传输，不包含业务逻辑
- ❌ 不在Model中进行业务验证

### JSON序列化配置
```dart
// 处理null值
@Default([]) List<String> tags,

// 自定义字段名
@JsonKey(name: 'user_id') String userId,

// 日期时间转换
@JsonKey(fromJson: _dateFromTimestamp, toJson: _dateToTimestamp)
DateTime? createdAt,

static DateTime? _dateFromTimestamp(int? timestamp) =>
  timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;

static int? _dateToTimestamp(DateTime? date) =>
  date?.millisecondsSinceEpoch;
```

## 数据源 (Data Sources)

### Remote Data Source
```dart
abstract class UserRemoteDataSource {
  Future<UserModel> getUserById(String id);
  Future<List<UserModel>> getUsers();
  Future<UserModel> createUser(UserModel user);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final Dio _dio;

  UserRemoteDataSourceImpl(this._dio);

  @override
  Future<UserModel> getUserById(String id) async {
    try {
      final response = await _dio.get('/users/$id');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  DataException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout');
      case DioExceptionType.badResponse:
        if (error.response?.statusCode == 404) {
          return NotFoundException('User not found');
        }
        return ServerException('Server error: ${error.response?.statusCode}');
      default:
        return NetworkException('Network error');
    }
  }
}
```

### Local Data Source
```dart
abstract class UserLocalDataSource {
  Future<UserModel?> getCachedUser(String id);
  Future<void> cacheUser(UserModel user);
  Future<void> clearCache();
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  final SharedPreferences _prefs;

  UserLocalDataSourceImpl(this._prefs);

  @override
  Future<UserModel?> getCachedUser(String id) async {
    final json = _prefs.getString('user_$id');
    if (json == null) return null;
    return UserModel.fromJson(jsonDecode(json));
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    await _prefs.setString(
      'user_${user.id}',
      jsonEncode(user.toJson()),
    );
  }
}
```

### 数据源规则
- ✅ 分离Remote和Local数据源
- ✅ 使用抽象接口定义
- ✅ 处理数据源特定的异常
- ✅ 返回Model类型，不返回Entity
- ❌ 不包含业务逻辑

## Repository实现

### 实现Domain层的Repository接口
```dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;
  final UserLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  UserRepositoryImpl({
    required UserRemoteDataSource remoteDataSource,
    required UserLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo;

  @override
  Future<UserEntity> getUserById(String id) async {
    if (await _networkInfo.isConnected) {
      try {
        // 从远程获取
        final userModel = await _remoteDataSource.getUserById(id);
        // 缓存到本地
        await _localDataSource.cacheUser(userModel);
        // 转换为Entity返回
        return userModel.toEntity();
      } on DataException catch (e) {
        // 远程失败，尝试从缓存获取
        return _getUserFromCache(id);
      }
    } else {
      // 无网络，从缓存获取
      return _getUserFromCache(id);
    }
  }

  Future<UserEntity> _getUserFromCache(String id) async {
    final cachedUser = await _localDataSource.getCachedUser(id);
    if (cachedUser == null) {
      throw CacheException('No cached user found');
    }
    return cachedUser.toEntity();
  }

  @override
  Future<List<UserEntity>> getUsers() async {
    final models = await _remoteDataSource.getUsers();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> saveUser(UserEntity user) async {
    final model = UserModel.fromEntity(user);
    await _remoteDataSource.createUser(model);
  }
}
```

### Repository规则
- ✅ 实现Domain层的Repository接口
- ✅ 协调多个数据源（remote/local）
- ✅ 处理缓存策略
- ✅ 将Model转换为Entity
- ✅ 处理网络异常，提供降级方案
- ❌ 不包含业务逻辑
- ❌ 不直接返回Model

## 异常处理

### Data层异常
```dart
abstract class DataException implements Exception {
  final String message;
  const DataException(this.message);
}

class NetworkException extends DataException {
  NetworkException(super.message);
}

class ServerException extends DataException {
  final int? statusCode;
  ServerException(super.message, {this.statusCode});
}

class CacheException extends DataException {
  CacheException(super.message);
}

class NotFoundException extends DataException {
  NotFoundException(super.message);
}
```

## Provider定义

### Data层Provider
```dart
// lib/features/user/data/providers/user_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_providers.g.dart';

@riverpod
UserRemoteDataSource userRemoteDataSource(UserRemoteDataSourceRef ref) {
  return UserRemoteDataSourceImpl(ref.watch(dioProvider));
}

@riverpod
UserLocalDataSource userLocalDataSource(UserLocalDataSourceRef ref) {
  return UserLocalDataSourceImpl(ref.watch(sharedPreferencesProvider));
}

@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepositoryImpl(
    remoteDataSource: ref.watch(userRemoteDataSourceProvider),
    localDataSource: ref.watch(userLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
}
```

## 网络配置

### Dio配置
```dart
// lib/core/network/dio_provider.dart
@riverpod
Dio dio(DioRef ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  // 添加拦截器
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));

  // 添加认证拦截器
  dio.interceptors.add(AuthInterceptor(ref));

  ref.onDispose(() => dio.close());

  return dio;
}
```

## 目录结构示例
```
lib/
  features/
    user/
      data/
        models/
          user_model.dart
          user_model.freezed.dart
          user_model.g.dart
        datasources/
          user_remote_datasource.dart
          user_local_datasource.dart
        repositories/
          user_repository_impl.dart
        exceptions/
          data_exceptions.dart
        providers/
          user_providers.dart
          user_providers.g.dart
```

## 最佳实践

### 1. 缓存策略
- 优先使用远程数据
- 远程失败时降级到缓存
- 定期更新缓存

### 2. 错误处理
- 捕获所有数据源异常
- 转换为合适的Domain异常
- 提供有意义的错误消息

### 3. 性能优化
- 避免不必要的网络请求
- 使用分页加载大数据
- 合理使用缓存

### 4. 测试友好
- 依赖注入所有数据源
- 易于mock网络请求
- 提供测试用的fake实现
