# Domain Layer 规则

## 核心原则
Domain层是应用的核心，**完全独立于框架和外部依赖**。

## 实体 (Entities)

### 使用Freezed定义实体
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';

@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String name,
    required String email,
    DateTime? lastLoginAt,
  }) = _UserEntity;

  const UserEntity._();

  // 业务方法
  bool get isActive => lastLoginAt != null;
}
```

### 实体规则
- ✅ 使用`@freezed`注解实现不可变性
- ✅ 只包含业务相关的属性和方法
- ✅ 不依赖任何外部框架（除Freezed）
- ❌ 不包含JSON序列化逻辑
- ❌ 不依赖UI框架
- ❌ 不包含数据库注解

## 仓储接口 (Repository Interfaces)

### 定义抽象仓储
```dart
abstract class UserRepository {
  Future<UserEntity> getUserById(String id);
  Future<List<UserEntity>> getUsers();
  Future<void> saveUser(UserEntity user);
  Future<void> deleteUser(String id);
}
```

### 仓储规则
- ✅ 使用`abstract class`定义接口
- ✅ 返回Domain实体类型
- ✅ 使用Future/Stream处理异步
- ❌ 不包含实现细节
- ❌ 不依赖具体的数据源

## 用例 (Use Cases)

### UseCase基类
```dart
abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

abstract class StreamUseCase<Type, Params> {
  Stream<Type> call(Params params);
}
```

### 用例实现
```dart
class GetUserUseCase implements UseCase<UserEntity, String> {
  final UserRepository _repository;

  GetUserUseCase(this._repository);

  @override
  Future<UserEntity> call(String userId) async {
    // 业务逻辑
    final user = await _repository.getUserById(userId);

    // 可以添加业务规则验证
    if (!user.isActive) {
      throw UserNotActiveException();
    }

    return user;
  }
}
```

### 用例规则
- ✅ 每个用例只做一件事（单一职责）
- ✅ 用例名称清晰表达意图：`Get/Create/Update/Delete/Validate{Entity}`
- ✅ 依赖仓储接口，不依赖实现
- ✅ 包含业务验证逻辑
- ✅ 使用依赖注入获取Repository
- ❌ 不直接访问数据源
- ❌ 不包含UI逻辑

### 无参数用例
```dart
class NoParams {}

class GetCurrentUserUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository _authRepository;

  GetCurrentUserUseCase(this._authRepository);

  @override
  Future<UserEntity> call(NoParams params) async {
    return _authRepository.getCurrentUser();
  }
}
```

## 值对象 (Value Objects)

### 封装业务规则
```dart
@freezed
class Email with _$Email {
  const factory Email(String value) = _Email;

  const Email._();

  factory Email.parse(String input) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(input)) {
      throw InvalidEmailException(input);
    }
    return Email(input);
  }
}
```

### 值对象规则
- ✅ 封装验证逻辑
- ✅ 不可变
- ✅ 使用factory构造器验证
- ✅ 重写`==`和`hashCode`（Freezed自动完成）

## 异常定义

### Domain异常
```dart
abstract class DomainException implements Exception {
  final String message;
  const DomainException(this.message);
}

class UserNotFoundException extends DomainException {
  UserNotFoundException(String userId)
    : super('User with id $userId not found');
}

class InvalidEmailException extends DomainException {
  InvalidEmailException(String email)
    : super('Invalid email: $email');
}
```

### 异常规则
- ✅ 继承自`DomainException`
- ✅ 描述业务错误，不是技术错误
- ✅ 提供清晰的错误信息
- ❌ 不包含HTTP状态码等技术细节

## Provider定义

### Domain层Provider
```dart
// lib/features/user/domain/providers/user_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_providers.g.dart';

@riverpod
GetUserUseCase getUserUseCase(GetUserUseCaseRef ref) {
  return GetUserUseCase(
    ref.watch(userRepositoryProvider),
  );
}

@riverpod
CreateUserUseCase createUserUseCase(CreateUserUseCaseRef ref) {
  return CreateUserUseCase(
    ref.watch(userRepositoryProvider),
  );
}
```

## 目录结构示例
```
lib/
  features/
    user/
      domain/
        entities/
          user_entity.dart
          user_entity.freezed.dart
        repositories/
          user_repository.dart
        usecases/
          get_user_usecase.dart
          create_user_usecase.dart
          update_user_usecase.dart
        exceptions/
          user_exceptions.dart
        providers/
          user_providers.dart
          user_providers.g.dart
```

## 最佳实践

### 1. 保持Domain层纯净
Domain层不应该知道：
- 如何序列化数据
- 数据来自网络还是本地
- 使用什么UI框架
- 如何进行导航

### 2. 面向接口编程
- 依赖抽象（Repository接口）
- 不依赖具体实现

### 3. 单一职责
- 每个UseCase只做一件事
- Entity只包含业务逻辑

### 4. 可测试性
- 所有依赖通过构造器注入
- 易于mock和测试
