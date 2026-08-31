/*
 * @Author: caibi1990 1006451068@qq.com
 * @Date: 2025-03-24 08:22:39
 * @LastEditors: caibi1990 1006451068@qq.com
 * @LastEditTime: 2025-04-29 14:41:56
 * @FilePath: /zrproject/lib/http/result/base_result.dart
 * @Description: 
 * 
 * Copyright (c) 2025 by caibi1990, All Rights Reserved. 
 */
import 'package:json_annotation/json_annotation.dart';

part 'base_result.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class BaseResult<T> {
  @JsonKey(name: "code")
  int? code;
  @JsonKey(name: "msg")
  String? msg;
  @JsonKey(name: "data")
  T? data;

  @JsonKey(name: "isSuccess")
  bool? isSuccess;

  BaseResult({this.code, this.msg, this.data, this.isSuccess});

  BaseResult errorResult() {
    var res = BaseResult(msg: "", code: 0);

    res.isSuccess = false;

    return res;
  }

  BaseResult<R> copyResult<R>() {
    return BaseResult<R>(msg: msg, code: code, isSuccess: isSuccess);
  }

  // 以下重写方法会导致报错估先注释
  // @override
  // String toString() {
  //   return jsonEncode(toJson((value) => {value}));
  // }

  factory BaseResult.fromJson(
          Map<String, dynamic> json, T Function(Object? json) fromJsonT) =>
      _$BaseResultFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$BaseResultToJson(this, toJsonT);
}
