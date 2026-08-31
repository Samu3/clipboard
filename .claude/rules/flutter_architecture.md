# Flutter Clean Architecture 规则

## 架构层次
项目采用Clean Architecture，严格分为以下层次：

### 1. Presentation Layer (表现层)
- **位置**: `lib/features/{feature_name}/presentation/`
- **职责**: UI组件、页面、状态管理
- **组成**:
  - `pages/` - 页面级Widget
  - `widgets/` - 可复用组件
  - `providers/` - Riverpod状态管理
  - `notifiers/` - StateNotifier/AsyncNotifier类

### 2. Domain Layer (领域层)
- **位置**: `lib/features/{feature_name}/domain/`
- **职责**: 业务逻辑、实体、用例
- **组成**:
  - `entities/` - 业务实体（使用Freezed）
  - `usecases/` - 用例类
  - `repositories/` - 仓储接口（抽象类）

### 3. Data Layer (数据层)
- **位置**: `lib/features/{feature_name}/data/`
- **职责**: 数据获取、持久化、API调用
- **组成**:
  - `models/` - 数据模型（使用Freezed + JSON序列化）
  - `repositories/` - 仓储实现
  - `datasources/` - 数据源（remote/local）

### 4. Core Layer (核心层)
- **位置**: `lib/core/`
- **职责**: 共享工具、常量、基础设施
- **组成**:
  - `network/` - 网络配置（Dio）
  - `error/` - 错误处理
  - `utils/` - 工具类
  - `constants/` - 常量
  - `theme/` - 主题配置
  - `router/` - 路由配置（GoRouter）

## 依赖规则
**严格遵守依赖方向**:
```
Presentation → Domain → Data
     ↓
   Core (所有层都可依赖)
```

### 禁止的依赖
- ❌ Domain层不能依赖Data层
- ❌ Domain层不能依赖Presentation层
- ❌ Data层不能依赖Presentation层
- ❌ 任何层不能跨Feature直接依赖

## Feature组织
每个功能模块独立组织：
```
lib/
  features/
    auth/
      data/
      domain/
      presentation/
    home/
      data/
      domain/
      presentation/
  core/
  shared/
```

## 文件命名规范
- 实体: `{name}_entity.dart`
- 模型: `{name}_model.dart`
- 仓储接口: `{name}_repository.dart`
- 仓储实现: `{name}_repository_impl.dart`
- 用例: `{action}_{entity}_usecase.dart`
- Provider: `{name}_provider.dart`
- Notifier: `{name}_notifier.dart`
- 页面: `{name}_page.dart`
- Widget: `{name}_widget.dart`
