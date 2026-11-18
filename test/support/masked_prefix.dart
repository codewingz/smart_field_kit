import 'package:material_ui/material_ui.dart';

String? maskedPrefixOf(InputDecoration? decoration) {
  var prefix = decoration?.prefix;
  if (prefix is ExcludeSemantics) {
    prefix = prefix.child;
  }
  if (prefix is SingleChildRenderObjectWidget) {
    final child = prefix.child;
    if (child is Text) {
      return child.data;
    }
  }
  return decoration?.prefixText;
}
