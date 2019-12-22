import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

Iterable<E> mapIndexed<E, T>(
    Iterable<T> items, E Function(int index, T item) f) sync* {
  var index = 0;
  for (final item in items) {
    yield f(index, item);
    index++;
  }
}

/// Only wraps set in an unmodifiable set
/// if it is not already an unmodifiable set
UnmodifiableSetView<T> unmodifiableSet<T>(Set<T> set) {
  if (set is UnmodifiableSetView<T>) {
    return set;
  }
  return UnmodifiableSetView(set);
}

/// Only wraps list in an unmodifiable list
/// if it is not already an unmodifiable list
UnmodifiableListView<T> unmodifiableList<T>(List<T> list) {
  if (list is UnmodifiableListView<T>) {
    return list;
  }
  return UnmodifiableListView(list);
}

class ValueListenableBuilder2<A, B> extends StatelessWidget {
  ValueListenableBuilder2(
    this.first,
    this.second, {
    Key key,
    this.builder,
    this.child,
  }) : super(key: key);

  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget child;
  final Widget Function(BuildContext context, A a, B b, Widget child) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (_, a, __) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, __) {
            return builder(context, a, b, child);
          },
        );
      },
    );
  }
}
