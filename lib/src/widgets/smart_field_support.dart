import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

final class SmartRedactedTextEditingController extends TextEditingController {
  SmartRedactedTextEditingController({super.text});

  @override
  String toString() => 'TextEditingController(redacted)';
}

final class SmartInputHandle {
  SmartInputHandle({this.redacted = false, this.initialText});

  final bool redacted;
  final String? initialText;
  TextEditingController? _externalController;
  FocusNode? _externalFocusNode;
  TextEditingController? _ownedController;
  FocusNode? _ownedFocusNode;

  TextEditingValue? _seed;

  void update({
    TextEditingController? controller,
    FocusNode? focusNode,
    TextEditingValue? seed,
  }) {
    final previous = _externalController;
    if (previous != null && controller == null && _ownedController == null) {
      _seed = previous.value;
    }
    _externalController = controller;
    _externalFocusNode = focusNode;
    _seed = seed ?? _seed;
  }

  void releaseUnused() {
    if (_externalController != null) {
      _ownedController?.dispose();
      _ownedController = null;
    }
    if (_externalFocusNode != null) {
      _ownedFocusNode?.dispose();
      _ownedFocusNode = null;
    }
  }

  bool get ownsController => _externalController == null;

  TextEditingController get controller {
    return _externalController ?? (_ownedController ??= _createController());
  }

  TextEditingController _createController() {
    final seed = _seed;
    if (redacted) {
      return SmartRedactedTextEditingController(
        text: seed?.text ?? initialText,
      );
    }
    return seed == null
        ? TextEditingController(text: initialText)
        : TextEditingController.fromValue(seed);
  }

  FocusNode get focusNode {
    return _externalFocusNode ?? (_ownedFocusNode ??= FocusNode());
  }

  void dispose() {
    _ownedController?.dispose();
    _ownedFocusNode?.dispose();
    _ownedController = null;
    _ownedFocusNode = null;
  }
}

Widget? composeSuffixActions(Iterable<Widget> children) {
  final list = children.toList(growable: false);
  if (list.isEmpty) {
    return null;
  }
  if (list.length == 1) {
    return list.single;
  }
  return Row(mainAxisSize: MainAxisSize.min, children: list);
}

class SmartPickerScope extends InheritedWidget {
  const SmartPickerScope({
    super.key,
    required this.interactive,
    required super.child,
  });

  final bool interactive;

  @override
  bool updateShouldNotify(SmartPickerScope oldWidget) {
    return oldWidget.interactive != interactive;
  }
}

class SmartLtrContentScope extends InheritedWidget {
  const SmartLtrContentScope({super.key, required super.child});

  static bool isActive(BuildContext context) {
    return context.getInheritedWidgetOfExactType<SmartLtrContentScope>() !=
        null;
  }

  @override
  bool updateShouldNotify(SmartLtrContentScope oldWidget) => false;
}

class SmartSensitiveInputScope extends InheritedWidget {
  const SmartSensitiveInputScope({super.key, required super.child});

  static bool isActive(BuildContext context) {
    return context.getInheritedWidgetOfExactType<SmartSensitiveInputScope>() !=
        null;
  }

  @override
  bool updateShouldNotify(SmartSensitiveInputScope oldWidget) => false;
}

String smartIsolateLtr(String text) {
  return text.isEmpty ? text : '\u2066$text\u2069';
}

bool smartResolveEnabled(bool? enabled, InputDecoration decoration) {
  return enabled ?? decoration.enabled;
}

Widget smartClearButton({
  required String tooltip,
  required VoidCallback? onPressed,
}) {
  return IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: const Icon(Icons.clear),
  );
}

Widget smartPassiveFocus({
  required Widget child,
  ValueChanged<bool>? onFocusChange,
  FocusOnKeyEventCallback? onKeyEvent,
}) {
  return Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onFocusChange: onFocusChange,
    onKeyEvent: onKeyEvent,
    child: child,
  );
}

abstract class SmartFormFieldValue extends FormFieldState<String> {
  static void set(FormFieldState<String>? state, String text) {
    state?.setValue(text);
  }
}

class SmartScaleToFit extends SingleChildRenderObjectWidget {
  const SmartScaleToFit({
    super.key,
    this.minChildWidth,
    this.maxWidthFactor = 1,
    super.child,
  });

  final double? minChildWidth;
  final double maxWidthFactor;

  @override
  RenderSmartScaleToFit createRenderObject(BuildContext context) {
    return RenderSmartScaleToFit(
      minChildWidth,
      maxWidthFactor,
      Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSmartScaleToFit renderObject,
  ) {
    renderObject
      ..minChildWidth = minChildWidth
      ..maxWidthFactor = maxWidthFactor
      ..textDirection = Directionality.of(context);
  }
}

class RenderSmartScaleToFit extends RenderProxyBox {
  RenderSmartScaleToFit(
    this._minChildWidth,
    this._maxWidthFactor,
    this._textDirection,
  );

  double? _minChildWidth;
  double _maxWidthFactor;
  TextDirection _textDirection;
  double _scale = 1;
  Offset _offset = Offset.zero;

  set minChildWidth(double? value) {
    if (_minChildWidth != value) {
      _minChildWidth = value;
      markNeedsLayout();
    }
  }

  set maxWidthFactor(double value) {
    if (_maxWidthFactor != value) {
      _maxWidthFactor = value;
      markNeedsLayout();
    }
  }

  set textDirection(TextDirection value) {
    if (_textDirection != value) {
      _textDirection = value;
      markNeedsLayout();
    }
  }

  double _available(BoxConstraints constraints) {
    return constraints.maxWidth * _maxWidthFactor;
  }

  BoxConstraints _childConstraints(BoxConstraints constraints) {
    final available = _available(constraints);
    final minWidth = _minChildWidth;
    if (minWidth == null || !available.isFinite) {
      return const BoxConstraints();
    }
    return BoxConstraints.tightFor(
      width: available > minWidth ? available : minWidth,
    );
  }

  double _scaleFor(BoxConstraints constraints, Size childSize) {
    final available = _available(constraints);
    if (!available.isFinite || childSize.width <= available) {
      return 1;
    }
    return available / childSize.width;
  }

  Offset _offsetFor(Size own, Size scaledChild) {
    final extra = own.width - scaledChild.width;
    return Offset(
      _textDirection == TextDirection.rtl ? extra : 0,
      (own.height - scaledChild.height) / 2,
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) {
      return constraints.smallest;
    }
    final childSize = child.getDryLayout(_childConstraints(constraints));
    return constraints.constrain(childSize * _scaleFor(constraints, childSize));
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final child = this.child;
    if (child == null) {
      return null;
    }
    final inner = _childConstraints(constraints);
    final value = child.getDryBaseline(inner, baseline);
    if (value == null) {
      return null;
    }
    final childSize = child.getDryLayout(inner);
    final scale = _scaleFor(constraints, childSize);
    final own = constraints.constrain(childSize * scale);
    return value * scale + _offsetFor(own, childSize * scale).dy;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final value = child?.getDistanceToActualBaseline(baseline);
    return value == null ? null : value * _scale + _offset.dy;
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_childConstraints(constraints), parentUsesSize: true);
    _scale = _scaleFor(constraints, child.size);
    final scaled = child.size * _scale;
    size = constraints.constrain(scaled);
    _offset = _offsetFor(size, scaled);
  }

  Matrix4 get _transform {
    return Matrix4.diagonal3Values(_scale, _scale, 1)
      ..setTranslationRaw(_offset.dx, _offset.dy, 0);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) {
      layer = null;
      return;
    }
    if (_scale == 1) {
      layer = null;
      context.paintChild(child, offset + _offset);
      return;
    }
    layer = context.pushTransform(
      needsCompositing,
      offset,
      _transform,
      (context, offset) => context.paintChild(child, offset),
      oldLayer: layer is TransformLayer ? layer as TransformLayer : null,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) {
      return false;
    }
    return result.addWithPaintTransform(
      transform: _transform,
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_transform);
  }
}

class SmartMaskedText extends SingleChildRenderObjectWidget {
  const SmartMaskedText({super.key, required this.room, super.child});

  final RenderBox? Function() room;

  @override
  RenderSmartMaskedText createRenderObject(BuildContext context) {
    return RenderSmartMaskedText(room, Directionality.of(context));
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSmartMaskedText renderObject,
  ) {
    renderObject
      ..room = room
      ..textDirection = Directionality.of(context);
  }
}

class RenderSmartMaskedText extends RenderProxyBox {
  RenderSmartMaskedText(this._room, this._textDirection);

  static const double minimumScale = 0.6;

  RenderBox? Function() _room;
  TextDirection _textDirection;
  final LayerHandle<ClipRectLayer> _clipLayer = LayerHandle<ClipRectLayer>();
  final LayerHandle<TransformLayer> _transformLayer =
      LayerHandle<TransformLayer>();

  set room(RenderBox? Function() value) {
    _room = value;
    markNeedsPaint();
  }

  set textDirection(TextDirection value) {
    if (_textDirection != value) {
      _textDirection = value;
      markNeedsPaint();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) {
      return constraints.smallest;
    }
    final height = child.getDryLayout(const BoxConstraints()).height;
    return constraints.constrain(Size(0, height));
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    return child?.getDryBaseline(const BoxConstraints(), baseline);
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(const BoxConstraints(), parentUsesSize: true);
    _baseline =
        child.getDistanceToBaseline(TextBaseline.alphabetic, onlyReal: true) ??
        child.size.height / 2;
    size = constraints.constrain(Size(0, child.size.height));
  }

  double _baseline = 0;

  ({Matrix4 transform, Rect? clip}) _placement() {
    final child = this.child!;
    final width = child.size.width;
    final box = _room();
    if (box == null || !box.attached || !box.hasSize || width <= 0) {
      return (transform: Matrix4.identity(), clip: null);
    }
    final left = MatrixUtils.transformPoint(
      box.getTransformTo(this),
      Offset.zero,
    ).dx;
    final room = box.size.width;
    var scale = width <= room ? 1.0 : room / width;
    final fits = scale >= minimumScale;
    if (!fits) {
      scale = minimumScale;
    }
    final drawn = width * scale;
    final alignEnd = !fits || _textDirection == TextDirection.rtl;
    final dx = alignEnd ? left + room - drawn : left;
    final dy = _baseline * (1 - scale);
    return (
      transform: Matrix4.diagonal3Values(scale, scale, 1)
        ..setTranslationRaw(dx, dy, 0),
      clip: fits ? null : Rect.fromLTWH(left, 0, room, size.height),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) {
      _clipLayer.layer = null;
      _transformLayer.layer = null;
      return;
    }
    final placement = _placement();
    void paintScaled(PaintingContext context, Offset offset) {
      _transformLayer.layer = context.pushTransform(
        needsCompositing,
        offset,
        placement.transform,
        (context, offset) => context.paintChild(child, offset),
        oldLayer: _transformLayer.layer,
      );
    }

    final clip = placement.clip;
    if (clip == null) {
      _clipLayer.layer = null;
      paintScaled(context, offset);
      return;
    }
    _clipLayer.layer = context.pushClipRect(
      needsCompositing,
      offset,
      clip,
      paintScaled,
      oldLayer: _clipLayer.layer,
    );
  }

  @override
  void dispose() {
    _clipLayer.layer = null;
    _transformLayer.layer = null;
    super.dispose();
  }

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return false;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_placement().transform);
  }
}
