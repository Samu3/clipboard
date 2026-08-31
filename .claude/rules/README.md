# Flutter Clean Architecture + Riverpod 规则总览

这个目录包含了基于Clean Architecture和Riverpod的Flutter项目开发规则。

## 规则文件列表

1. **flutter_architecture.md** - 架构总览和依赖规则
2. **domain_layer.md** - Domain层规则（实体、用例、Repository接口）
3. **data_layer.md** - Data层规则（Model、数据源、Repository实现）
4. **presentation_layer.md** - Presentation层规则（页面、Widget、状态管理）
5. **riverpod_guidelines.md** - Riverpod状态管理详细指南
6. **naming_conventions.md** - 命名规范
7. **project_structure.md** - 项目目录结构
8. **best_practices.md** - 最佳实践和性能优化
9. **_usage.md** - 版本管理使用规范

## 重要规则

### 1. 不要创建项目文档

**禁止创建以下类型的文档：**
- ❌ 使用指南（如 QUICK_START.md, USER_GUIDE.md）
- ❌ 功能说明文档（如 THEME_SYSTEM.md, FEATURE_GUIDE.md）
- ❌ API文档（如 API.md）
- ❌ 配置说明文档（如 CONFIGURATION.md, SETUP.md）
- ❌ Core层README（如 lib/core/README.md）

**只在必要时创建技术文档：**
- ✅ 架构规则文档（.claude/rules/）
- ✅ 代码注释（必要的类和方法注释）
- ✅ README.md（项目基本信息）

**原因：**
- 文档容易过时，代码才是真相
- 良好的代码结构和命名比文档更重要
- 代码注释应该足够说明问题

### 2. 架构层次
```
Presentation → Domain → Data
     ↓           ↓       ↓
        Core & Shared
```

### 3. Feature结构
```
features/
  {feature_name}/
    data/
      models/
      datasources/
      repositories/
      providers/
    domain/
      entities/
      repositories/
      usecases/
      providers/
    presentation/
      pages/
      widgets/
      notifiers/
      providers/
```

### 4. 核心原则

1. **依赖规则**: 依赖只能从外向内（Presentation → Domain → Data）
2. **单一职责**: 每个类、方法只做一件事
3. **依赖注入**: 使用Riverpod管理所有依赖
4. **不可变性**: 使用Freezed创建不可变数据类
5. **类型安全**: 明确所有类型，充分利用Dart的类型系统
6. **代码即文档**: 用清晰的命名和必要的注释代替冗长的文档

### 5. 命名约定

| 类型 | 命名规则 | 示例 |
|------|---------|------|
| 文件 | snake_case | user_profile_page.dart |
| 类 | PascalCase | UserEntity, HomePage |
| 变量/方法 | camelCase | userName, getUserById() |
| 私有成员 | _camelCase | _userId, _loadData() |
| 常量 | camelCase | maxRetryCount |


### 7. 代码生成

项目使用以下代码生成工具：
- **freezed**: 生成不可变数据类
- **json_serializable**: JSON序列化
- **riverpod_generator**: Provider代码生成

运行生成命令：
```bash
 dart run build_runner watch --delete-conflicting-outputs
```

常用命令：
```bash
# 获取依赖
 flutter pub get

# 运行应用
 flutter run

# 运行测试
 flutter test

# 代码分析
 flutter analyze
```

### 8. 关键包

```yaml
dependencies:
  # 状态管理
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  hooks_riverpod: ^2.5.1

  # 数据模型
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

  # 网络
  dio: ^5.4.0

  # 路由
  go_router: ^14.0.0

dev_dependencies:
  # 代码生成
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  riverpod_generator: ^2.3.0
```

## 开发流程

### 创建新Feature

1. **创建目录结构**
```bash
mkdir -p lib/features/{feature_name}/{data,domain,presentation}/{models,entities,pages}
```

2. **定义Domain层**
   - 创建Entity（业务实体）
   - 定义Repository接口

3. **实现Data层**
   - 创建Model（带JSON序列化）
   - 实现DataSource
   - 实现Repository

4. **构建Presentation层**
   - 创建Notifier管理状态
   - 构建Page和Widget
   - 连接Provider

### 代码审查检查清单

- [ ] 是否遵循依赖规则？
- [ ] 是否使用Freezed创建不可变类？
- [ ] Provider是否正确配置？
- [ ] 是否处理了所有错误情况？
- [ ] Widget是否使用const构造器？
- [ ] 命名是否符合规范？
- [ ] 是否添加了必要的注释？
- [ ] 是否编写了测试？
- [ ] 是否避免创建不必要的文档？

## 注意事项

### Domain层不应该
- ❌ 导入Flutter包
- ❌ 导入Data层
- ❌ 包含JSON序列化逻辑
- ❌ 直接访问网络或数据库

### Data层不应该
- ❌ 包含业务逻辑
- ❌ 导入Presentation层
- ❌ 直接返回Model（应转换为Entity）

### Presentation层不应该
- ❌ 直接访问Repository
- ❌ 包含复杂业务逻辑
- ❌ 直接处理网络请求

### 文档编写
- ❌ 不要创建使用指南和配置说明文档
- ❌ 不要为每个功能模块写独立文档
- ✅ 用清晰的代码和注释代替文档
- ✅ 只在 .claude/rules/ 中维护架构规则

## 参考资源

- [Clean Architecture - Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Riverpod官方文档](https://riverpod.dev/)
- [Flutter架构示例](https://github.com/ResoCoder/flutter-tdd-clean-architecture-course)

## 问题反馈

如果发现规则有问题或需要补充，请更新相应的规则文件。

---

**记住**: 这些规则是指导原则，不是绝对的。在特定情况下，可以根据实际需求灵活调整，但要保持一致性。代码和注释胜过文档。

