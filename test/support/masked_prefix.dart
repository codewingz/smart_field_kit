import 'package:flutter/material.dart';

String? maskedPrefixOf(InputDecoration? decoration) {
  final prefix = decoration?.prefix;
  if (prefix is SingleChildRenderObjectWidget) {
    final child = prefix.child;
    if (child is Text) {
      return child.data;
    }
  }
  return decoration?.prefixText;
}
