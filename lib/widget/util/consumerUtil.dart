import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class ValueNotifierConsumer<T> extends StatelessWidget {
  final Widget Function(BuildContext context, T val, Widget child) builder;
  final Widget child;

  const ValueNotifierConsumer({Key key, this.builder, this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ValueNotifier<T>>(
      builder: (context, valueNotifier, _) =>
          builder(context, valueNotifier.value, child),
    );
  }
}

class MultiValueNotifierConsumer<T, U> extends StatelessWidget {
  final Widget Function(BuildContext context, T val, U val2, Widget child)
      builder;
  final Widget child;

  const MultiValueNotifierConsumer({Key key, this.builder, this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ValueNotifier<T>>(
      builder: (context, valueNotifier, _) => Consumer<ValueNotifier<U>>(
        builder: (context, valueNotifier2, _) =>
            builder(context, valueNotifier.value, valueNotifier2.value, child),
      ),
    );
  }
}

class ProviderWithValueNotifierConsumer<T> extends StatelessWidget {
  final Widget Function(BuildContext context, T val, Widget child) builder;
  final Widget child;
  final ValueNotifier<T> valueNotifier;
  final ValueBuilder<ValueNotifier<T>> valueNotifierBuilder;

  const ProviderWithValueNotifierConsumer(
      {Key key, this.builder, this.child, this.valueNotifierBuilder})
      : valueNotifier = null,
        super(key: key);

  const ProviderWithValueNotifierConsumer.value(
      {Key key, this.builder, this.child, this.valueNotifier})
      : valueNotifierBuilder = null,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (valueNotifier != null) {
      return ChangeNotifierProvider<ValueNotifier<T>>.value(
        value: valueNotifier,
        child: ValueNotifierConsumer<T>(builder: builder),
      );
    } else {
      return ChangeNotifierProvider<ValueNotifier<T>>(
        builder: valueNotifierBuilder,
        child: ValueNotifierConsumer<T>(builder: builder),
      );
    }
  }
}
