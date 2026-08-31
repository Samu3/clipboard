# Flutter 项目结构

## 完整目录结构

```
unique_health/
├── lib/
│   ├── main.dart                           # 应用入口
│   ├── app.dart                            # App配置（主题、路由等）
│   │
│   ├── core/                               # 核心基础设施（所有层共享）
│   │   ├── network/
│   │   │   ├── dio_provider.dart           # Dio配置
│   │   │   ├── network_info.dart           # 网络状态检测
│   │   │   └── interceptors/
│   │   │       ├── auth_interceptor.dart
│   │   │       └── logging_interceptor.dart
│   │   │
│   │   ├── error/
│   │   │   ├── failures.dart               # 通用错误类型
│   │   │   └── exceptions.dart             # 通用异常
│   │   │
│   │   ├── router/
│   │   │   ├── app_router.dart             # GoRouter配置
│   │   │   └── route_names.dart            # 路由常量
│   │   │
│   │   ├── theme/
│   │   │   ├── app_theme.dart              # 主题配置
│   │   │   ├── app_colors.dart             # 颜色常量
│   │   │   └── app_text_styles.dart        # 文字样式
│   │   │
│   │   ├── constants/
│   │   │   ├── api_constants.dart          # API常量
│   │   │   ├── app_constants.dart          # 应用常量
│   │   │   └── storage_keys.dart           # 存储Key
│   │   │
│   │   ├── utils/
│   │   │   ├── date_formatter.dart
│   │   │   ├── validators.dart
│   │   │   └── logger.dart
│   │   │
│   │   └── providers/
│   │       ├── core_providers.dart         # 核心Provider
│   │       └── core_providers.g.dart
│   │
│   ├── shared/                             # 跨Feature共享代码
│   │   ├── widgets/                        # 共享UI组件
│   │   │   ├── buttons/
│   │   │   │   ├── primary_button.dart
│   │   │   │   └── secondary_button.dart
│   │   │   ├── inputs/
│   │   │   │   ├── text_input.dart
│   │   │   │   └── search_input.dart
│   │   │   ├── loading/
│   │   │   │   └── loading_indicator.dart
│   │   │   ├── error/
│   │   │   │   └── error_view.dart
│   │   │   └── empty/
│   │   │       └── empty_state.dart
│   │   │
│   │   ├── extensions/                     # 扩展方法
│   │   │   ├── context_extensions.dart
│   │   │   ├── string_extensions.dart
│   │   │   └── datetime_extensions.dart
│   │   │
│   │   └── models/                         # 共享数据模型
│   │       └── pagination.dart
│   │
│   └── features/                           # 功能模块（按Feature组织）
│       │
│       ├── auth/                           # 认证功能
│       │   ├── data/
│       │   │   ├── models/
│       │   │   │   ├── auth_model.dart
│       │   │   │   ├── auth_model.freezed.dart
│       │   │   │   └── auth_model.g.dart
│       │   │   ├── datasources/
│       │   │   │   ├── auth_remote_datasource.dart
│       │   │   │   └── auth_local_datasource.dart
│       │   │   ├── repositories/
│       │   │   │   └── auth_repository_impl.dart
│       │   │   └── providers/
│       │   │       ├── auth_providers.dart
│       │   │       └── auth_providers.g.dart
│       │   │
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   ├── user_entity.dart
│       │   │   │   └── user_entity.freezed.dart
│       │   │   ├── repositories/
│       │   │   │   └── auth_repository.dart
│       │   │   ├── usecases/
│       │   │   │   ├── sign_in_usecase.dart
│       │   │   │   ├── sign_up_usecase.dart
│       │   │   │   ├── sign_out_usecase.dart
│       │   │   │   └── get_current_user_usecase.dart
│       │   │   └── providers/
│       │   │       ├── auth_providers.dart
│       │   │       └── auth_providers.g.dart
│       │   │
│       │   └── presentation/
│       │       ├── pages/
│       │       │   ├── login_page.dart
│       │       │   ├── register_page.dart
│       │       │   └── forgot_password_page.dart
│       │       ├── widgets/
│       │       │   ├── login_form.dart
│       │       │   └── social_login_buttons.dart
│       │       ├── notifiers/
│       │       │   ├── auth_notifier.dart
│       │       │   └── auth_notifier.g.dart
│       │       └── providers/
│       │           ├── auth_providers.dart
│       │           └── auth_providers.g.dart
│       │
│       ├── home/                           # 首页功能
│       │   ├── data/
│       │   │   ├── models/
│       │   │   ├── datasources/
│       │   │   ├── repositories/
│       │   │   └── providers/
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   ├── repositories/
│       │   │   ├── usecases/
│       │   │   └── providers/
│       │   └── presentation/
│       │       ├── pages/
│       │       │   └── home_page.dart
│       │       ├── widgets/
│       │       ├── notifiers/
│       │       └── providers/
│       │
│       ├── profile/                        # 用户资料功能
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       │
│       └── settings/                       # 设置功能
│           ├── data/
│           ├── domain/
│           └── presentation/
│
├── test/                                   # 测试文件
│   ├── unit/
│   │   ├── core/
│   │   └── features/
│   │       └── auth/
│   │           ├── data/
│   │           ├── domain/
│   │           └── presentation/
│   ├── widget/
│   └── integration/
│
├── assets/                                 # 静态资源
│   ├── images/
│   ├── fonts/
│   └── icons/
│
├── pubspec.yaml                           # 依赖配置
├── analysis_options.yaml                  # 代码分析配置
└── README.md
```

## 层级说明

### Core层
存放所有Feature共享的基础设施代码：
- **network/**: 网络配置、拦截器
- **error/**: 通用错误和异常定义
- **router/**: 路由配置
- **theme/**: 主题和样式
- **constants/**: 常量定义
- **utils/**: 工具类
- **providers/**: 核心Provider（Dio、SharedPreferences等）

### Shared层
存放跨Feature共享的业务代码：
- **widgets/**: 可复用的UI组件
- **extensions/**: 扩展方法
- **models/**: 共享的数据模型

### Features层
按功能模块组织，每个Feature包含三层：

#### Data层
- **models/**: 数据模型（带JSON序列化）
- **datasources/**: 数据源（remote/local）
- **repositories/**: Repository实现
- **providers/**: Data层Provider

#### Domain层
- **entities/**: 业务实体（不带JSON序列化）
- **repositories/**: Repository接口
- **usecases/**: 用例
- **providers/**: Domain层Provider

#### Presentation层
- **pages/**: 页面级Widget
- **widgets/**: 局部组件
- **notifiers/**: 状态管理
- **providers/**: Presentation层Provider

## Feature示例：Todo

```
features/
  todo/
    data/
      models/
        todo_model.dart
        todo_model.freezed.dart
        todo_model.g.dart
      datasources/
        todo_remote_datasource.dart
        todo_local_datasource.dart
      repositories/
        todo_repository_impl.dart
      providers/
        todo_data_providers.dart
        todo_data_providers.g.dart

    domain/
      entities/
        todo_entity.dart
        todo_entity.freezed.dart
      repositories/
        todo_repository.dart
      usecases/
        get_todos_usecase.dart
        create_todo_usecase.dart
        update_todo_usecase.dart
        delete_todo_usecase.dart
      providers/
        todo_domain_providers.dart
        todo_domain_providers.g.dart

    presentation/
      pages/
        todo_list_page.dart
        todo_detail_page.dart
        create_todo_page.dart
      widgets/
        todo_item.dart
        todo_filter.dart
      notifiers/
        todos_notifier.dart
        todos_notifier.g.dart
      providers/
        todo_presentation_providers.dart
        todo_presentation_providers.g.dart
```

## 文件内容示例

### main.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

### app.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Unique Health',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
```

## 命名约定

### 文件夹
- 使用snake_case
- 按功能/类型命名

### 文件
- 使用snake_case
- 包含类型后缀：`_page`, `_widget`, `_model`, `_entity`, `_usecase`等

### Provider文件组织
每一层的Provider放在各自层级的`providers/`目录下：
- Data层: `{feature}/data/providers/`
- Domain层: `{feature}/domain/providers/`
- Presentation层: `{feature}/presentation/providers/`

## 依赖规则

```
Presentation → Domain → Data
     ↓           ↓       ↓
        Core & Shared
```

- Presentation层可以依赖Domain层
- Domain层可以依赖Core层，但不能依赖Data/Presentation层
- Data层可以依赖Domain层和Core层
- 所有层都可以依赖Shared层
- Feature之间不能直接依赖

## 导入规则

### 使用相对导入（同Feature内）
```dart
// ✅ 同一Feature内使用相对导入
import '../domain/entities/user_entity.dart';
import '../../data/models/user_model.dart';
```

### 使用绝对导入（跨Feature）
```dart
// ✅ 跨Feature使用绝对导入
import 'package:clipboard/core/theme/app_colors.dart';
import 'package:clipboard/shared/widgets/buttons/primary_button.dart';
```

## 测试目录结构

测试目录结构镜像lib目录：
```
test/
  unit/
    features/
      auth/
        data/
          repositories/
            auth_repository_impl_test.dart
        domain/
          usecases/
            sign_in_usecase_test.dart
  widget/
    features/
      auth/
        presentation/
          pages/
            login_page_test.dart
```

## 最佳实践

1. **保持Feature独立**: 每个Feature应该是自包含的
2. **共享代码放shared**: 多个Feature使用的代码放到shared
3. **基础设施放core**: 网络、路由、主题等放到core
4. **遵循依赖规则**: 严格遵守层级依赖方向
5. **Provider就近原则**: Provider定义在使用它的层级
