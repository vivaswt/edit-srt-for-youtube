import 'package:flutter/material.dart';

extension WrapWithExtensionForMultiChild on List<Widget> {
  Widget wrapWithColumn({
    Key? key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
    double spacing = 0.0,
  }) => Column(
    key: key,
    mainAxisAlignment: mainAxisAlignment,
    mainAxisSize: mainAxisSize,
    crossAxisAlignment: crossAxisAlignment,
    textDirection: textDirection,
    verticalDirection: verticalDirection,
    textBaseline: textBaseline,
    spacing: spacing,
    children: this,
  );

  /// Wraps the widget in a [Row].
  Widget wrapWithRow({
    Key? key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
    double spacing = 0.0,
  }) => Row(
    key: key,
    mainAxisAlignment: mainAxisAlignment,
    mainAxisSize: mainAxisSize,
    crossAxisAlignment: crossAxisAlignment,
    textDirection: textDirection,
    verticalDirection: verticalDirection,
    textBaseline: textBaseline,
    spacing: spacing,
    children: this,
  );

  /// Wraps the widget in a [Wrap].
  Widget wrapWithWrap({
    Key? key,
    Axis direction = Axis.horizontal,
    WrapAlignment alignment = WrapAlignment.start,
    double spacing = 0.0,
    WrapAlignment runAlignment = WrapAlignment.start,
    double runSpacing = 0.0,
    WrapCrossAlignment crossAxisAlignment = WrapCrossAlignment.start,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    Clip clipBehavior = Clip.none,
  }) => Wrap(
    key: key,
    direction: direction,
    alignment: alignment,
    spacing: spacing,
    runAlignment: runAlignment,
    runSpacing: runSpacing,
    crossAxisAlignment: crossAxisAlignment,
    textDirection: textDirection,
    verticalDirection: verticalDirection,
    clipBehavior: clipBehavior,
    children: this,
  );
}

extension WrapWithExtension on Widget {
  /// Wraps the widget in a [Column].
  Widget wrapWithColumn({
    Key? key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
  }) => Column(
    key: key,
    mainAxisAlignment: mainAxisAlignment,
    mainAxisSize: mainAxisSize,
    crossAxisAlignment: crossAxisAlignment,
    textDirection: textDirection,
    verticalDirection: verticalDirection,
    textBaseline: textBaseline,
    children: [this],
  );

  /// Wraps the widget in a [Row].
  Widget wrapWithRow({
    Key? key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
  }) => Row(
    key: key,
    mainAxisAlignment: mainAxisAlignment,
    mainAxisSize: mainAxisSize,
    crossAxisAlignment: crossAxisAlignment,
    textDirection: textDirection,
    verticalDirection: verticalDirection,
    textBaseline: textBaseline,
    children: [this],
  );

  /// Wraps the widget in a [Padding].
  Widget wrapWithPadding({required EdgeInsetsGeometry padding, Key? key}) =>
      Padding(key: key, padding: padding, child: this);

  /// Wraps the widget in an [Align].
  Widget wrapWithAlign({
    Key? key,
    AlignmentGeometry alignment = Alignment.center,
    double? widthFactor,
    double? heightFactor,
  }) => Align(
    key: key,
    alignment: alignment,
    widthFactor: widthFactor,
    heightFactor: heightFactor,
    child: this,
  );

  /// Wraps the widget in a [SizedBox].
  Widget wrapWithSizedBox({Key? key, double? width, double? height}) =>
      SizedBox(key: key, width: width, height: height, child: this);

  /// Wraps the widget in a [Center].
  Widget wrapWithCenter({
    Key? key,
    double? widthFactor,
    double? heightFactor,
  }) => Center(
    key: key,
    widthFactor: widthFactor,
    heightFactor: heightFactor,
    child: this,
  );

  /// Wraps the widget in a [Container].
  Widget wrapWithContainer({
    Key? key,
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? padding,
    Color? color,
    Decoration? decoration,
    Decoration? foregroundDecoration,
    double? width,
    double? height,
    BoxConstraints? constraints,
    EdgeInsetsGeometry? margin,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    Clip clipBehavior = Clip.none,
  }) => Container(
    key: key,
    alignment: alignment,
    padding: padding,
    color: color,
    decoration: decoration,
    foregroundDecoration: foregroundDecoration,
    width: width,
    height: height,
    constraints: constraints,
    margin: margin,
    transform: transform,
    transformAlignment: transformAlignment,
    clipBehavior: clipBehavior,
    child: this,
  );

  /// Wraps the widget in an [Expanded].
  Widget wrapWithExpanded({Key? key, int flex = 1}) =>
      Expanded(key: key, flex: flex, child: this);

  /// Wraps the widget in an [IntrinsicHeight].
  Widget wrapWithIntrinsicHeight({Key? key}) =>
      IntrinsicHeight(key: key, child: this);

  /// Wraps the widget in an [IntrinsicWidth].
  Widget wrapWithIntrinsicWidth({Key? key}) =>
      IntrinsicWidth(key: key, child: this);

  /// Wraps the widget in a [Wrap].
  Widget wrapWithWrap({
    Key? key,
    Axis direction = Axis.horizontal,
    WrapAlignment alignment = WrapAlignment.start,
    double spacing = 0.0,
    WrapAlignment runAlignment = WrapAlignment.start,
    double runSpacing = 0.0,
    WrapCrossAlignment crossAxisAlignment = WrapCrossAlignment.start,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    Clip clipBehavior = Clip.none,
  }) => Wrap(
    key: key,
    direction: direction,
    alignment: alignment,
    spacing: spacing,
    runAlignment: runAlignment,
    runSpacing: runSpacing,
    crossAxisAlignment: crossAxisAlignment,
    textDirection: textDirection,
    verticalDirection: verticalDirection,
    clipBehavior: clipBehavior,
    children: [this],
  );

  /// Wraps the widget in an [InputDecorator].
  Widget wrapWithInputDecorator({
    Key? key,
    required InputDecoration decoration,
    TextStyle? baseStyle,
    TextAlign? textAlign,
    TextAlignVertical? textAlignVertical,
    bool isFocused = false,
    bool isHovering = false,
    bool expands = false,
    bool isEmpty = false,
  }) => InputDecorator(
    key: key,
    decoration: decoration,
    baseStyle: baseStyle,
    textAlign: textAlign,
    textAlignVertical: textAlignVertical,
    isFocused: isFocused,
    isHovering: isHovering,
    expands: expands,
    isEmpty: isEmpty,
    child: this,
  );

  /// Wraps the widget in a [Card].
  Widget wrapWithCard({
    Key? key,
    Color? color,
    Color? shadowColor,
    Color? surfaceTintColor,
    double? elevation,
    ShapeBorder? shape,
    bool borderOnForeground = true,
    EdgeInsetsGeometry? margin,
    Clip? clipBehavior,
    bool semanticContainer = true,
  }) => Card(
    key: key,
    color: color,
    shadowColor: shadowColor,
    surfaceTintColor: surfaceTintColor,
    elevation: elevation,
    shape: shape,
    borderOnForeground: borderOnForeground,
    margin: margin,
    clipBehavior: clipBehavior,
    semanticContainer: semanticContainer,
    child: this,
  );

  /// Wraps the widget in an [InkWell].
  Widget wrapWithInkWell({
    Key? key,
    void Function()? onTap,
    void Function()? onDoubleTap,
    void Function()? onLongPress,
    void Function(TapDownDetails)? onTapDown,
    void Function(TapUpDetails)? onTapUp,
    void Function()? onTapCancel,
    void Function(bool)? onHighlightChanged,
    void Function(bool)? onHover,
    MouseCursor? mouseCursor,
    Color? focusColor,
    Color? hoverColor,
    Color? highlightColor,
    WidgetStateProperty<Color?>? overlayColor,
    Color? splashColor,
    InteractiveInkFeatureFactory? splashFactory,
    double? radius,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    bool enableFeedback = true,
    bool excludeFromSemantics = false,
    FocusNode? focusNode,
    bool canRequestFocus = true,
    void Function(bool)? onFocusChange,
    bool autofocus = false,
    WidgetStatesController? statesController,
  }) => InkWell(
    key: key,
    onTap: onTap,
    onDoubleTap: onDoubleTap,
    onLongPress: onLongPress,
    onTapDown: onTapDown,
    onTapUp: onTapUp,
    onTapCancel: onTapCancel,
    onHighlightChanged: onHighlightChanged,
    onHover: onHover,
    mouseCursor: mouseCursor,
    focusColor: focusColor,
    hoverColor: hoverColor,
    highlightColor: highlightColor,
    overlayColor: overlayColor,
    splashColor: splashColor,
    splashFactory: splashFactory,
    radius: radius,
    borderRadius: borderRadius,
    customBorder: customBorder,
    enableFeedback: enableFeedback,
    excludeFromSemantics: excludeFromSemantics,
    focusNode: focusNode,
    canRequestFocus: canRequestFocus,
    onFocusChange: onFocusChange,
    autofocus: autofocus,
    statesController: statesController,
    child: this,
  );

  /// Wraps the widget in an [RadioGroup].
  Widget wrapWithRadioGroup<T>({
    Key? key,
    T? groupValue,
    required ValueChanged<T?> onChanged,
  }) => RadioGroup(
    key: key,
    groupValue: groupValue,
    onChanged: onChanged,
    child: this,
  );
}
