import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

bool _isFlutterClass(InterfaceElement element, String name) =>
    element.name == name &&
    element.library.uri.toString().startsWith('package:flutter/');

bool _isOrExtends(InterfaceElement element, String name) =>
    _isFlutterClass(element, name) ||
    element.allSupertypes.any((t) => _isFlutterClass(t.element, name));

/// Flutter `Widget`이거나 그 하위 타입인지.
bool isWidgetType(DartType? type) =>
    type is InterfaceType && _isOrExtends(type.element, 'Widget');

/// 위젯 클래스 또는 `State` 클래스인지.
bool isWidgetOrStateClass(InterfaceElement? element) =>
    element != null &&
    (_isOrExtends(element, 'Widget') || _isOrExtends(element, 'State'));
