import 'package:collection/collection.dart';

Iterable<E> mapIndexed<E, T>(
    Iterable<T> items, E Function(int index, T item) f) sync* {
  var index = 0;

  for (final item in items) {
    yield f(index, item);
    index = index + 1;
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
