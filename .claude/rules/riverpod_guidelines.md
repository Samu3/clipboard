# Riverpod 状态管理规则

## Provider类型选择

### 1. Provider (不可变数据)
用于提供不会改变的依赖或配置:
```dart
@riverpod
Dio dio(DioRef ref) {
  return Dio(BaseOptions(baseUrl: 'https://api.example.com'));
}
```

### 2. FutureProvider (异步数据)
用于一次性异步数据获取:
```dart
@riverpod
Future<User> currentUser(CurrentUserRef ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getCurrentUser();
}
```

### 3. StreamProvider (流数据)
用于监听持续变化的数据流:
```dart
@riverpod
Stream<List<Message>> messages(MessagesRef ref) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.watchMessages();
}
```

### 4. StateNotifierProvider (复杂状态)
用于管理可变的复杂状态:
```dart
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<AuthState> build() async {
    return const AuthState.unauthenticated();
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).signIn(email, password);
      return AuthState.authenticated(user);
    });
  }
}
```

## 代码生成注解

### 使用riverpod_annotation
**必须使用**code generation:
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '{filename}.g.dart';

@riverpod
class MyNotifier extends _$MyNotifier {
  // implementation
}
```



## Provider命名规范

### Provider命名
- Repository Provider: `{name}RepositoryProvider`
- UseCase Provider: `{action}{Entity}UseCaseProvider`
- Notifier Provider: `{name}NotifierProvider`
- 数据Provider: `{name}Provider`

### 示例
```dart
@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepositoryImpl(
    remoteDataSource: ref.watch(userRemoteDataSourceProvider),
  );
}

@riverpod
GetUserUseCase getUserUseCase(GetUserUseCaseRef ref) {
  return GetUserUseCase(ref.watch(userRepositoryProvider));
}

@riverpod
class UserNotifier extends _$UserNotifier {
  // ...
}
```

## Ref使用规则

### ref.watch vs ref.read vs ref.listen

#### ref.watch (在build中使用)
响应式监听，当依赖变化时重建:
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final user = ref.watch(currentUserProvider);
  return user.when(
    data: (data) => Text(data.name),
    loading: () => CircularProgressIndicator(),
    error: (err, stack) => Text('Error: $err'),
  );
}
```

#### ref.read (在事件处理中使用)
一次性读取，不监听变化:
```dart
void onPressed() {
  ref.read(userNotifierProvider.notifier).updateUser();
}
```

#### ref.listen (监听变化执行副作用)
监听变化但不重建UI:
```dart
@override
void initState() {
  super.initState();
  ref.listen(authNotifierProvider, (previous, next) {
    if (next.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${next.error}')),
      );
    }
  });
}
```

## AsyncValue处理

使用`.when`方法优雅处理异步状态:
```dart
final asyncValue = ref.watch(userProvider);

return asyncValue.when(
  data: (user) => UserProfile(user),
  loading: () => const LoadingIndicator(),
  error: (error, stackTrace) => ErrorWidget(error),
);
```

使用`.maybeWhen`处理部分状态:
```dart
asyncValue.maybeWhen(
  data: (user) => UserProfile(user),
  orElse: () => const SizedBox.shrink(),
);
```

## Provider依赖注入

### 依赖其他Provider
```dart
@riverpod
class TodoNotifier extends _$TodoNotifier {
  @override
  Future<List<Todo>> build() async {
    // 依赖其他Provider
    final repository = ref.watch(todoRepositoryProvider);
    return repository.getTodos();
  }
}
```

### 自动释放资源
```dart
@riverpod
Dio dio(DioRef ref) {
  final dio = Dio();
  ref.onDispose(() {
    dio.close();
  });
  return dio;
}
```

## 最佳实践

### 1. Provider放置位置
- Data层Provider: `lib/features/{feature}/data/providers/`
- Domain层Provider: `lib/features/{feature}/domain/providers/`
- Presentation层Provider: `lib/features/{feature}/presentation/providers/`

### 2. 避免过度使用全局Provider
- 优先使用局部Provider
- 使用`ProviderScope`创建作用域

### 3. 测试友好
- 使用`ProviderContainer`进行单元测试
- 使用`overrideWith`替换Provider实现

### 4. 性能优化
- 使用`.select()`避免不必要的重建
```dart
final userName = ref.watch(userProvider.select((user) => user.name));
```

### 5. 错误处理
- 在Notifier中使用`AsyncValue.guard`捕获异常
- 提供友好的错误UI
