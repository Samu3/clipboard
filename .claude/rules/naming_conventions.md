# Flutter 命名规范

## 文件命名
所有文件使用**snake_case**（小写+下划线）:

### 基础规则
- ✅ `user_profile_page.dart`
- ✅ `auth_repository.dart`
- ✅ `get_user_usecase.dart`
- ❌ `UserProfilePage.dart`
- ❌ `authRepository.dart`

### 层级命名
```
Domain层:
  - {name}_entity.dart          # 实体
  - {name}_repository.dart      # 仓储接口
  - {action}_{entity}_usecase.dart  # 用例

Data层:
  - {name}_model.dart           # 数据模型
  - {name}_repository_impl.dart # 仓储实现
  - {name}_remote_datasource.dart   # 远程数据源
  - {name}_local_datasource.dart    # 本地数据源

Presentation层:
  - {name}_page.dart            # 页面
  - {name}_widget.dart          # 组件
  - {name}_notifier.dart        # 状态管理
  - {name}_provider.dart        # Provider定义
```

## 类命名
使用**PascalCase**（大驼峰）:

### Entity类
```dart
class UserEntity         // ✅
class User_Entity        // ❌
class userEntity         // ❌
```

### Model类
```dart
class UserModel          // ✅
class UserDTO           // ✅ (如果使用DTO模式)
```

### Repository类
```dart
// 接口
abstract class UserRepository        // ✅

// 实现
class UserRepositoryImpl            // ✅
```

### UseCase类
```dart
class GetUserUseCase                // ✅
class CreateUserUseCase             // ✅
class UpdateUserProfileUseCase      // ✅
```

### Notifier类
```dart
class AuthNotifier extends _$AuthNotifier     // ✅
class UserNotifier extends _$UserNotifier     // ✅
```

### Widget类
```dart
class HomePage extends ConsumerWidget         // ✅ 页面用Page
class UserCard extends StatelessWidget        // ✅ 组件用Widget/Card/Button等
class LoadingIndicator extends StatelessWidget // ✅
```

## 变量/方法命名
使用**camelCase**（小驼峰）:

### 变量
```dart
final userName = 'John';              // ✅
final user_name = 'John';             // ❌
final UserName = 'John';              // ❌
```

### 方法
```dart
void getUserById(String id) {}        // ✅
void get_user_by_id(String id) {}     // ❌
void GetUserById(String id) {}        // ❌
```

### 私有成员
```dart
final _userId = '123';                // ✅ 私有变量用下划线前缀
void _loadData() {}                   // ✅ 私有方法用下划线前缀
```

## 常量命名

### 普通常量：lowerCamelCase
```dart
const defaultTimeout = Duration(seconds: 30);     // ✅
const maxRetryCount = 3;                         // ✅
```

### 枚举值：camelCase
```dart
enum AuthStatus {
  authenticated,      // ✅
  unauthenticated,   // ✅
  loading,           // ✅
}
```

### 配置常量类
```dart
class AppConfig {
  static const apiBaseUrl = 'https://api.example.com';  // ✅
  static const apiTimeout = Duration(seconds: 30);       // ✅
}
```

## Provider命名

### Provider变量名
```dart
// Repository Provider
@riverpod
UserRepository userRepository(UserRepositoryRef ref) {}   // ✅

// UseCase Provider
@riverpod
GetUserUseCase getUserUseCase(GetUserUseCaseRef ref) {}   // ✅

// Notifier Provider
@riverpod
class UserNotifier extends _$UserNotifier {}              // ✅
```

### Provider使用
```dart
ref.watch(userRepositoryProvider)         // ✅
ref.watch(getUserUseCaseProvider)         // ✅
ref.watch(userNotifierProvider)           // ✅
ref.watch(userNotifierProvider.notifier)  // ✅ 访问Notifier实例
```

## 目录命名
使用**snake_case**:

```
lib/
  features/
    user_profile/        // ✅ 多个单词用下划线
    auth/               // ✅ 单个单词
    shopping_cart/      // ✅
  core/
    network/
    database/
```

## 路由命名

### 路由路径
```dart
class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const userProfile = '/user/:id';        // ✅ kebab-case
  static const settings = '/settings';
  static const aboutUs = '/about-us';            // ✅ 多单词用连字符
}
```

## 测试文件命名

### 测试文件
```dart
user_repository_test.dart          // ✅ 单元测试
user_profile_page_test.dart       // ✅ Widget测试
auth_integration_test.dart        // ✅ 集成测试
```

## Asset资源命名

### 图片资源
```
assets/
  images/
    logo.png                       // ✅
    user_avatar_placeholder.png    // ✅
    icon_home.svg                 // ✅
    icon_home_active.svg          // ✅
```

### 字体资源
```
assets/
  fonts/
    roboto_regular.ttf            // ✅
    roboto_bold.ttf              // ✅
```

## 扩展方法命名

### 扩展类
```dart
extension StringExtensions on String {      // ✅
  bool get isEmail => ...;
  String capitalize() => ...;
}

extension DateTimeX on DateTime {           // ✅ 也可以用X后缀
  bool get isToday => ...;
}
```

## 特殊命名规则

### Freezed生成的文件
```dart
user_entity.dart           // ✅ 源文件
user_entity.freezed.dart   // ✅ Freezed生成
user_model.dart           // ✅ 源文件
user_model.g.dart         // ✅ json_serializable生成
user_model.freezed.dart   // ✅ Freezed生成
```

### Provider生成的文件
```dart
user_providers.dart       // ✅ 源文件
user_providers.g.dart     // ✅ riverpod_generator生成
```

## 命名反模式（避免）

### 避免缩写
```dart
class UsrRepo {}          // ❌ 避免不清晰的缩写
class UserRepository {}   // ✅ 使用完整单词
```

### 避免匈牙利命名法
```dart
String strUserName;       // ❌
int iCount;              // ❌
String userName;         // ✅
int count;              // ✅
```

### 避免无意义的名称
```dart
void doStuff() {}        // ❌
void getData() {}        // ❌
void processInfo() {}    // ❌

void fetchUserProfile() {}    // ✅ 清晰明确
void validateEmail() {}       // ✅
```

## 一致性原则

### CRUD操作命名
```dart
// UseCase命名
GetUserUseCase           // ✅ 获取
CreateUserUseCase        // ✅ 创建
UpdateUserUseCase        // ✅ 更新
DeleteUserUseCase        // ✅ 删除

// Repository方法命名
getUserById()           // ✅
createUser()           // ✅
updateUser()           // ✅
deleteUser()           // ✅

// Notifier方法命名
fetchUser()            // ✅ 或getUser()
addUser()              // ✅ 或createUser()
updateUser()           // ✅
removeUser()           // ✅ 或deleteUser()
```

### 状态命名
```dart
isLoading              // ✅ bool类型用is前缀
hasError               // ✅ bool类型用has前缀
canEdit                // ✅ bool类型用can前缀

loadingState           // ❌ 避免State后缀（会和Widget State混淆）
isLoading              // ✅
```

## 总结

| 类型 | 命名规则 | 示例 |
|------|---------|------|
| 文件 | snake_case | user_profile_page.dart |
| 类 | PascalCase | UserEntity, HomePage |
| 变量/方法 | camelCase | userName, getUserById() |
| 私有成员 | _camelCase | _userId, _loadData() |
| 常量 | camelCase | maxRetryCount |
| 目录 | snake_case | user_profile/ |
| 路由 | kebab-case | /user-profile |
