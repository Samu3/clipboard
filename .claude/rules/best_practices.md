# Flutter 最佳实践

## 代码组织

### Feature-First结构
优先按功能划分，而非按类型:
```
lib/
  features/              ✅ 按功能组织
    auth/
    user_profile/
    home/

  lib/                   ❌ 避免按类型组织
    models/
    views/
    controllers/
```

### 共享代码组织
```
lib/
  core/                  # 核心基础设施
    network/
    error/
    theme/
    constants/
  shared/                # 跨Feature共享
    widgets/
    utils/
```

## 性能优化

### 1. 使用const构造器
```dart
// ✅ 编译时常量，不会重建
const Text('Hello')
const SizedBox(height: 16)
const Padding(padding: EdgeInsets.all(8))

// ❌ 每次build都创建新实例
Text('Hello')
SizedBox(height: 16)
```

### 2. 避免在build中创建对象
```dart
// ❌ 避免
@override
Widget build(BuildContext context) {
  final style = TextStyle(fontSize: 16);  // 每次build都创建
  return Text('Hello', style: style);
}

// ✅ 推荐
class MyWidget extends StatelessWidget {
  static const _textStyle = TextStyle(fontSize: 16);  // 复用

  @override
  Widget build(BuildContext context) {
    return Text('Hello', style: _textStyle);
  }
}
```

### 3. 拆分Widget避免不必要的重建
```dart
// ❌ 整个Widget都会重建
class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Column(
      children: [
        Text('Count: $count'),  // 需要重建
        ExpensiveWidget(),      // 不需要重建但也会重建
      ],
    );
  }
}

// ✅ 分离成独立Widget
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CounterDisplay(),     // 只有这个会重建
        const ExpensiveWidget(),    // const，不会重建
      ],
    );
  }
}

class CounterDisplay extends ConsumerWidget {
  const CounterDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('Count: $count');
  }
}
```

### 4. 使用.select()精确订阅
```dart
// ❌ user对象任何字段变化都会重建
final user = ref.watch(userProvider);
return Text(user.name);

// ✅ 只有name变化才重建
final userName = ref.watch(userProvider.select((user) => user.name));
return Text(userName);
```

### 5. 列表性能优化
```dart
// ✅ 使用ListView.builder而非ListView
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

// ✅ 为列表项提供key
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    final item = items[index];
    return ItemWidget(
      key: ValueKey(item.id),  // 帮助Flutter复用Widget
      item: item,
    );
  },
)
```

## 错误处理

### 1. 使用AsyncValue优雅处理异步状态
```dart
final userAsync = ref.watch(userProvider);

return userAsync.when(
  data: (user) => UserProfile(user),
  loading: () => const CircularProgressIndicator(),
  error: (error, stack) => ErrorView(error.toString()),
);
```

### 2. 全局错误捕获
```dart
void main() {
  FlutterError.onError = (details) {
    // 记录Flutter框架错误
    logger.error('Flutter Error', details.exception, details.stack);
  };

  runZonedGuarded(() {
    runApp(const MyApp());
  }, (error, stack) {
    // 记录Dart错误
    logger.error('Dart Error', error, stack);
  });
}
```

### 3. 网络错误处理
```dart
class UserRepositoryImpl implements UserRepository {
  @override
  Future<UserEntity> getUserById(String id) async {
    try {
      final response = await _dio.get('/users/$id');
      return UserModel.fromJson(response.data).toEntity();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw UserNotFoundException(id);
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw NetworkException('Connection timeout');
      } else {
        throw ServerException('Unknown server error');
      }
    } catch (e) {
      throw DataException('Failed to get user: $e');
    }
  }
}
```

## 空安全

### 1. 明确处理null值
```dart
// ✅ 使用?? 提供默认值
final name = user?.name ?? 'Unknown';

// ✅ 使用?. 安全访问
final email = user?.profile?.email;

// ❌ 避免强制解包
final name = user!.name;  // 可能抛出异常
```

### 2. 使用late谨慎
```dart
// ✅ 只在确定初始化后才访问时使用
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);  // 确保初始化
  }
}

// ❌ 避免用late逃避null检查
late String userName;  // 如果忘记初始化会抛异常
```

## 依赖注入

### 使用Riverpod进行依赖注入
```dart
// ✅ 通过Provider提供依赖
@riverpod
Dio dio(DioRef ref) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  ref.onDispose(() => dio.close());
  return dio;
}

@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepositoryImpl(
    remoteDataSource: ref.watch(userRemoteDataSourceProvider),
    localDataSource: ref.watch(userLocalDataSourceProvider),
  );
}

// ❌ 避免全局单例
class AppSingleton {
  static final instance = AppSingleton._();
  AppSingleton._();
}
```

## 代码质量

### 1. 使用分析器规则
在`analysis_options.yaml`中配置严格的lint规则:
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - prefer_final_fields
    - avoid_print
    - always_use_package_imports
    - sort_pub_dependencies
```

### 2. 添加文档注释
```dart
/// 获取指定ID的用户信息
///
/// [userId] 用户ID
///
/// 如果用户不存在，抛出 [UserNotFoundException]
/// 如果网络错误，抛出 [NetworkException]
Future<UserEntity> getUserById(String userId);
```

### 3. 使用类型注解
```dart
// ✅ 明确类型
final List<String> names = [];
final Map<String, int> scores = {};

// ❌ 避免var（除非类型显而易见）
var data = fetchData();  // 不清楚返回类型
```

## 状态管理最佳实践

### 1. 保持状态本地化
```dart
// ✅ 状态只在需要的地方使用
class CounterWidget extends StatefulWidget {
  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0;  // 本地状态

  @override
  Widget build(BuildContext context) {
    return Text('$_count');
  }
}

// ❌ 不要把所有状态都放到全局Provider
```

### 2. 单向数据流
```dart
// ✅ 数据从Provider流向UI
class TodoListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todosProvider);  // 读取状态

    return ListView(
      children: todos.map((todo) {
        return TodoItem(
          todo: todo,
          onTap: () {
            // 通过Notifier修改状态
            ref.read(todosProvider.notifier).toggleTodo(todo.id);
          },
        );
      }).toList(),
    );
  }
}
```

## 测试

### 1. 编写可测试的代码
```dart
// ✅ 依赖注入，易于测试
class GetUserUseCase {
  final UserRepository repository;

  GetUserUseCase(this.repository);

  Future<UserEntity> call(String id) => repository.getUserById(id);
}

// ❌ 硬编码依赖，难以测试
class GetUserUseCase {
  Future<UserEntity> call(String id) {
    final repo = UserRepositoryImpl();  // 无法mock
    return repo.getUserById(id);
  }
}
```

### 2. 使用ProviderContainer测试Provider
```dart
void main() {
  test('GetUserUseCase returns user', () async {
    final container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(MockUserRepository()),
      ],
    );

    final useCase = container.read(getUserUseCaseProvider);
    final user = await useCase.call('123');

    expect(user.id, '123');
  });
}
```

## 资源管理

### 1. 及时释放资源
```dart
class _MyPageState extends State<MyPage> {
  late StreamSubscription _subscription;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _subscription = stream.listen((data) {});
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _subscription.cancel();      // ✅ 取消订阅
    _controller.dispose();       // ✅ 释放控制器
    super.dispose();
  }
}
```

### 2. 使用Riverpod自动管理
```dart
@riverpod
Stream<User> userStream(UserStreamRef ref) {
  final stream = FirebaseAuth.instance.authStateChanges();

  // Riverpod会在Provider销毁时自动取消订阅
  return stream;
}
```

## 代码复用

### 1. 使用扩展方法
```dart
extension BuildContextExtensions on BuildContext {
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
}

// 使用
context.showSnackBar('Hello');
final style = context.textTheme.bodyLarge;
```

### 2. 创建可复用组件
```dart
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
        ? const CircularProgressIndicator()
        : Text(text),
    );
  }
}
```

## 安全

### 1. 不在代码中硬编码敏感信息
```dart
// ❌ 避免
const apiKey = 'sk_live_1234567890';

// ✅ 使用环境变量或配置文件
@riverpod
String apiKey(ApiKeyRef ref) {
  return const String.fromEnvironment('API_KEY');
}
```

### 2. 验证用户输入
```dart
class EmailValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }

    return null;
  }
}
```

## 国际化

### 使用Flutter intl
```dart
// l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart

// 使用
Text(AppLocalizations.of(context)!.hello)
```

## 总结

1. **性能**: 使用const、拆分Widget、精确订阅
2. **错误处理**: AsyncValue、全局捕获、明确异常类型
3. **空安全**: 谨慎使用!和late
4. **依赖注入**: 使用Riverpod管理依赖
5. **代码质量**: Lint规则、类型注解
6. **测试**: 依赖注入、Provider测试
7. **资源管理**: 及时释放、自动管理
8. **安全**: 不硬编码敏感信息、验证输入
