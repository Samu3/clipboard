# Presentation Layer 规则

## 核心职责
Presentation层负责UI展示和用户交互，使用Riverpod管理状态。

## 页面 (Pages)

### 使用ConsumerWidget/HookConsumerWidget
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: userAsync.when(
        data: (user) => UserProfileContent(user: user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorView(error: error.toString()),
      ),
    );
  }
}
```

### 使用HookConsumerWidget (需要Hooks)
```dart
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SearchPage extends HookConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final focusNode = useFocusNode();

    return Scaffold(
      body: Column(
        children: [
          TextField(
            controller: searchController,
            focusNode: focusNode,
            onChanged: (value) {
              ref.read(searchNotifierProvider.notifier).search(value);
            },
          ),
        ],
      ),
    );
  }
}
```

### 页面规则
- ✅ 使用`ConsumerWidget`或`HookConsumerWidget`
- ✅ 通过`ref.watch`监听Provider
- ✅ 使用`ref.read`处理事件
- ✅ 页面只负责UI布局，不包含业务逻辑
- ✅ 使用`.when()`优雅处理AsyncValue
- ❌ 不直接调用Repository或UseCase
- ❌ 不在Widget中处理复杂的业务逻辑

## 组件 (Widgets)

### 可复用组件
```dart
class UserAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.size = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: size / 2,
        backgroundImage: CachedNetworkImageProvider(imageUrl),
      ),
    );
  }
}
```

### 组件规则
- ✅ 单一职责，只做一件事
- ✅ 通过构造器接收数据
- ✅ 优先使用`StatelessWidget`
- ✅ 使用`const`构造器
- ✅ 提供必要的自定义参数
- ❌ 不直接访问Provider（除非必要）
- ❌ 避免过深的Widget树嵌套

## 状态管理 (Notifiers)

### AsyncNotifier (推荐用于异步状态)
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_notifier.g.dart';

@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  Future<UserEntity> build(String userId) async {
    // 初始化状态：获取用户数据
    final useCase = ref.watch(getUserUseCaseProvider);
    return useCase.call(userId);
  }

  Future<void> updateProfile(String name, String email) async {
    // 显示loading状态
    state = const AsyncValue.loading();

    // 执行更新操作
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(updateUserUseCaseProvider);
      final currentUser = state.value!;
      final updatedUser = currentUser.copyWith(name: name, email: email);
      await useCase.call(updatedUser);
      return updatedUser;
    });
  }

  Future<void> refresh() async {
    // 刷新数据
    ref.invalidateSelf();
  }
}
```

### Notifier (同步状态)
```dart
@riverpod
class CounterNotifier extends _$CounterNotifier {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}
```

### Notifier规则
- ✅ 使用`@riverpod`注解和code generation
- ✅ 异步操作使用`AsyncNotifier`
- ✅ 简单同步状态使用`Notifier`
- ✅ 在Notifier中调用UseCase
- ✅ 使用`AsyncValue.guard`捕获异常
- ✅ 提供清晰的方法名（CRUD操作）
- ❌ 不直接访问Repository
- ❌ 不在Notifier中处理导航逻辑

## 副作用处理

### ref.listen (监听变化)
```dart
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听认证状态变化
    ref.listen(authNotifierProvider, (previous, next) {
      next.whenData((authState) {
        if (authState.isAuthenticated) {
          // 导航到主页
          context.go('/home');
        }
      });

      // 处理错误
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${next.error}')),
        );
      }
    });

    return Scaffold(
      body: LoginForm(),
    );
  }
}
```

### 使用Hooks处理副作用
```dart
class UserPage extends HookConsumerWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      // 页面加载时获取数据
      ref.read(userNotifierProvider.notifier).fetchUser();
      return null;
    }, []);

    return Scaffold(
      body: UserContent(),
    );
  }
}
```

## 导航

### 使用GoRouter
```dart
// lib/core/router/app_router.dart
@riverpod
GoRouter goRouter(GoRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/user/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return UserProfilePage(userId: id);
        },
      ),
    ],
    redirect: (context, state) {
      // 认证检查
      final isAuth = ref.read(authNotifierProvider).value?.isAuthenticated ?? false;
      if (!isAuth && state.matchedLocation != '/login') {
        return '/login';
      }
      return null;
    },
  );
}
```

### 导航规则
- ✅ 使用GoRouter进行声明式路由
- ✅ 在Widget中使用`context.go()`/`context.push()`
- ✅ 路径参数使用`pathParameters`
- ✅ 查询参数使用`queryParameters`
- ❌ 不在Notifier中执行导航
- ❌ 避免硬编码路由路径，使用常量

## UI响应式设计

### 使用LayoutBuilder
```dart
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return const DesktopLayout();
        } else {
          return const MobileLayout();
        }
      },
    );
  }
}
```

### 使用MediaQuery
```dart
final screenWidth = MediaQuery.of(context).size.width;
final isLargeScreen = screenWidth > 600;
```

## 错误处理UI

### 错误Widget
```dart
class ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
```

## Provider使用示例

### 在页面中使用
```dart
class TodoListPage extends ConsumerWidget {
  const TodoListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听todos列表
    final todosAsync = ref.watch(todosNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: todosAsync.when(
        data: (todos) => ListView.builder(
          itemCount: todos.length,
          itemBuilder: (context, index) {
            final todo = todos[index];
            return TodoItem(
              todo: todo,
              onToggle: () {
                // 使用read调用方法
                ref.read(todosNotifierProvider.notifier).toggleTodo(todo.id);
              },
            );
          },
        ),
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorView(
          error: error.toString(),
          onRetry: () {
            ref.invalidate(todosNotifierProvider);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddTodoDialog(
        onAdd: (title) {
          ref.read(todosNotifierProvider.notifier).addTodo(title);
        },
      ),
    );
  }
}
```

## 性能优化

### 使用.select避免不必要重建
```dart
// 只监听name变化
final userName = ref.watch(
  userProvider.select((user) => user.name),
);
```

### 使用const构造器
```dart
const Text('Hello')  // ✅ 优化性能
Text('Hello')        // ❌ 每次都创建新实例
```

### 分离大Widget
```dart
// ❌ 避免
class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          // 100行代码...
        ],
      ),
    );
  }
}

// ✅ 推荐
class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          const Header(),
          const Content(),
          const Footer(),
        ],
      ),
    );
  }
}
```

## 目录结构示例
```
lib/
  features/
    user/
      presentation/
        pages/
          user_profile_page.dart
          user_list_page.dart
        widgets/
          user_avatar.dart
          user_card.dart
        notifiers/
          user_notifier.dart
          user_notifier.g.dart
        providers/
          user_providers.dart
          user_providers.g.dart
```

## 最佳实践

### 1. 保持Widget简洁
- Widget只负责UI，不处理业务逻辑
- 复杂逻辑移到Notifier中

### 2. 合理使用Provider
- 使用`ref.watch`响应式监听
- 使用`ref.read`处理事件
- 使用`ref.listen`处理副作用

### 3. 错误处理
- 总是处理`AsyncValue`的error状态
- 提供用户友好的错误提示
- 提供重试机制

### 4. 性能优化
- 使用`const`构造器
- 使用`.select()`避免不必要的重建
- 拆分大Widget为小组件

### 5. 可测试性
- Widget测试只测试UI行为
- Mock Provider进行隔离测试
