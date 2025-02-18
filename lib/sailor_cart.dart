library sailor_cart;

import 'dart:collection';

import 'package:flutter/foundation.dart';

@immutable
class SailorPrice {
  final double value;
  final double taxRate;
  final bool taxInclusive;
  final bool percentage;

  const SailorPrice({
    required this.value,
    required this.taxInclusive,
    required this.taxRate,
    this.percentage = false,
  });

  SailorPrice copyWith({
    double? value,
    bool? taxInclusive,
    double? taxRate,
    bool? percentage,
  }) {
    return SailorPrice(
      value: value ?? this.value,
      taxInclusive: taxInclusive ?? this.taxInclusive,
      taxRate: taxRate ?? this.taxRate,
      percentage: percentage ?? this.percentage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SailorPrice &&
        other.value == value &&
        other.taxInclusive == taxInclusive &&
        other.taxRate == taxRate &&
        other.percentage == percentage;
  }

  @override
  int get hashCode {
    return value.hashCode ^
        taxInclusive.hashCode ^
        taxRate.hashCode ^
        percentage.hashCode;
  }

  @override
  String toString() =>
      'SailorPrice(value: $value, taxInclusive: $taxInclusive, taxRate: $taxRate, percentage: $percentage)';

  factory SailorPrice.fromJson(Map<String, dynamic> json) {
    return SailorPrice(
      value: json['value'],
      taxInclusive: json['taxInclusive'],
      taxRate: json['taxRate'],
      percentage: json['percentage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'taxInclusive': taxInclusive,
      'taxRate': taxRate,
      'percentage': percentage,
    };
  }

  double get total {
    if (taxInclusive) {
      return value;
    }

    if (percentage) {
      return value + (value * taxRate / 100);
    }

    return value + taxRate;
  }

  double get tax {
    if (taxInclusive) {
      return value - (value / (1 + taxRate / 100));
    }

    if (percentage) {
      return value * taxRate / 100;
    }

    return taxRate;
  }

  double get subtotal {
    if (taxInclusive) {
      return value - tax;
    }

    return value;
  }
}

@immutable
class SailorCartProduct {
  final String id;
  final List<SailorCartAddon> addons;
  final SailorPrice price;
  final int quantity;
  final bool draft;

  const SailorCartProduct({
    required this.id,
    required this.addons,
    required this.price,
    required this.quantity,
    this.draft = false,
  });

  SailorCartProduct copyWith({
    String? id,
    List<SailorCartAddon>? addons,
    SailorPrice? price,
    int? quantity,
    bool? draft,
  }) {
    return SailorCartProduct(
      id: id ?? this.id,
      addons: addons ?? this.addons,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      draft: draft ?? this.draft,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SailorCartProduct &&
        other.id == id &&
        listEquals(other.addons, addons) &&
        other.price == price &&
        other.quantity == quantity &&
        other.draft == draft;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        addons.hashCode ^
        price.hashCode ^
        quantity.hashCode ^
        draft.hashCode;
  }

  @override
  String toString() =>
      'SailorCartProduct(id: $id, addons: $addons, price: $price, quantity: $quantity, draft: $draft)';

  factory SailorCartProduct.fromJson(Map<String, dynamic> json) {
    return SailorCartProduct(
      id: json['id'],
      addons: List<SailorCartAddon>.from(
        json['addons']?.map((x) => SailorCartAddon.fromJson(x)) ?? [],
      ),
      price: SailorPrice.fromJson(json['price']),
      quantity: json['quantity'],
      draft: json['draft'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'addons': addons.map((x) => x.toJson()).toList(),
      'price': price.toJson(),
      'quantity': quantity,
      'draft': draft,
    };
  }

  double get total {
    final addonsTotal =
        addons.fold<double>(0, (sum, addon) => sum + addon.total);
    final baseTotal = price.total;
    return (baseTotal + addonsTotal) * quantity;
  }

  double get tax {
    final addonsTax = addons.fold<double>(0, (sum, addon) => sum + addon.tax);
    final baseTax = price.tax;
    return (baseTax + addonsTax) * quantity;
  }

  double get subtotal {
    final addonsSubtotal =
        addons.fold<double>(0, (sum, addon) => sum + addon.subtotal);
    final baseSubtotal = price.subtotal;
    return (baseSubtotal + addonsSubtotal) * quantity;
  }
}

@immutable
abstract class SailorCartAddon {
  final String id;
  final SailorPrice price;

  const SailorCartAddon({
    required this.id,
    required this.price,
  });

  double get total => price.total;

  double get tax => price.tax;

  double get subtotal => price.subtotal;

  factory SailorCartAddon.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'single':
        return SailorCartSingleAddon.fromJson(json);
      case 'multiple':
        return SailorCartMultipleAddon.fromJson(json);
      case 'counter':
        return SailorCartCounterAddon.fromJson(json);
      default:
        throw Exception('Invalid addon type');
    }
  }

  Map<String, dynamic> toJson();
}

@immutable
class SailorCartSingleAddon extends SailorCartAddon {
  final String group;
  final bool selected;

  const SailorCartSingleAddon({
    required super.id,
    required super.price,
    required this.group,
    this.selected = false,
  });

  SailorCartSingleAddon copyWith({
    String? id,
    SailorPrice? price,
    String? group,
    bool? selected,
  }) {
    return SailorCartSingleAddon(
      id: id ?? super.id,
      price: price ?? super.price,
      group: group ?? this.group,
      selected: selected ?? this.selected,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SailorCartSingleAddon &&
        other.id == id &&
        other.price == price &&
        other.group == group &&
        other.selected == selected;
  }

  @override
  int get hashCode {
    return id.hashCode ^ price.hashCode ^ group.hashCode ^ selected.hashCode;
  }

  @override
  String toString() =>
      'SailorCartSingleAddon(id: $id, price: $price, group: $group, selected: $selected)';

  factory SailorCartSingleAddon.fromJson(Map<String, dynamic> json) {
    if (json['type'] != 'single') {
      throw Exception('Invalid addon type');
    }

    return SailorCartSingleAddon(
      id: json['id'],
      price: SailorPrice.fromJson(json['price']),
      group: json['group'],
      selected: json['selected'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'price': price.toJson(),
      'group': group,
      'selected': selected,
      'type': 'single',
    };
  }
}

@immutable
class SailorCartMultipleAddon extends SailorCartAddon {
  const SailorCartMultipleAddon({
    required super.id,
    required super.price,
  });

  SailorCartMultipleAddon copyWith({
    String? id,
    SailorPrice? price,
  }) {
    return SailorCartMultipleAddon(
      id: id ?? super.id,
      price: price ?? super.price,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SailorCartMultipleAddon &&
        other.id == id &&
        other.price == price;
  }

  @override
  int get hashCode {
    return id.hashCode ^ price.hashCode;
  }

  @override
  String toString() => 'SailorCartMultipleAddon(id: $id, price: $price)';

  factory SailorCartMultipleAddon.fromJson(Map<String, dynamic> json) {
    if (json['type'] != 'multiple') {
      throw Exception('Invalid addon type');
    }

    return SailorCartMultipleAddon(
      id: json['id'],
      price: SailorPrice.fromJson(json['price']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'price': price.toJson(),
      'type': 'multiple',
    };
  }
}

@immutable
class SailorCartCounterAddon extends SailorCartAddon {
  final int min;
  final int max;
  final int quantity;

  const SailorCartCounterAddon({
    required super.id,
    required super.price,
    required this.min,
    required this.max,
    this.quantity = 0,
  });

  SailorCartCounterAddon copyWith({
    String? id,
    SailorPrice? price,
    int? min,
    int? max,
    int? quantity,
  }) {
    return SailorCartCounterAddon(
      id: id ?? super.id,
      price: price ?? super.price,
      min: min ?? this.min,
      max: max ?? this.max,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SailorCartCounterAddon &&
        other.id == id &&
        other.price == price &&
        other.min == min &&
        other.max == max &&
        other.quantity == quantity;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        price.hashCode ^
        min.hashCode ^
        max.hashCode ^
        quantity.hashCode;
  }

  @override
  String toString() =>
      'SailorCartCounterAddon(id: $id, price: $price, min: $min, max: $max, quantity: $quantity)';

  factory SailorCartCounterAddon.fromJson(Map<String, dynamic> json) {
    if (json['type'] != 'counter') {
      throw Exception('Invalid addon type');
    }

    return SailorCartCounterAddon(
      id: json['id'],
      price: SailorPrice.fromJson(json['price']),
      min: json['min'],
      max: json['max'],
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'price': price.toJson(),
      'min': min,
      'max': max,
      'quantity': quantity,
      'type': 'counter',
    };
  }

  @override
  double get total => price.total * quantity;

  @override
  double get tax => price.tax * quantity;

  @override
  double get subtotal => price.subtotal * quantity;
}

@immutable
class SailorCartState {
  final List<SailorCartProduct> products;

  const SailorCartState({
    required this.products,
  });

  SailorCartState copyWith({
    List<SailorCartProduct>? products,
  }) {
    return SailorCartState(
      products: products ?? this.products,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SailorCartState && listEquals(other.products, products);
  }

  @override
  int get hashCode => products.hashCode;

  @override
  String toString() => 'SailorCartState(products: $products)';

  factory SailorCartState.fromJson(Map<String, dynamic> json) {
    return SailorCartState(
      products: List<SailorCartProduct>.from(
        json['products']?.map((x) => SailorCartProduct.fromJson(x)) ?? [],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'products': products.map((x) => x.toJson()).toList(),
    };
  }
}

class SailorCart<T, E> extends ChangeNotifier {
  final SailorCartProduct Function(T) productAdapter;
  final SailorCartAddon Function(E) addonAdapter;

  SailorCart({
    required this.productAdapter,
    required this.addonAdapter,
  });

  SailorCartState _state = const SailorCartState(products: []);

  UnmodifiableListView<SailorCartProduct> get products =>
      UnmodifiableListView(_state.products.where((p) => !p.draft));

  void addProduct(T product) {
    final exists =
        _state.products.any((p) => p == productAdapter(product));

    if (!exists) {
      _state = _state.copyWith(
        products: List.from(_state.products)..add(productAdapter(product)),
      );

      notifyListeners();
      return;
    }

    final newProduct = _state.products.map((p) {
      if (p == productAdapter(product)) {
        return p.copyWith(
          quantity: p.quantity + 1,
        );
      }
      return p;
    }).toList();

    _state = _state.copyWith(
      products: newProduct,
    );

    notifyListeners();
  }

  void removeProduct(T product) {
    final existing = _state.products.firstWhere(
      (p) => p.id == productAdapter(product).id,
    );

    if (existing.quantity == 1) {
      _state = _state.copyWith(
        products: List.from(_state.products)
          ..removeWhere((p) => p == productAdapter(product)),
      );

      notifyListeners();
      return;
    }

    final newProducts = _state.products.map((p) {
      if (p.id == productAdapter(product).id) {
        return p.copyWith(
          quantity: p.quantity - 1,
        );
      }
      return p;
    }).toList();

    _state = _state.copyWith(
      products: newProducts,
    );

    notifyListeners();
  }

  bool get isEmpty => _state.products.isEmpty;

  bool hasProduct(T product) {
    return _state.products.any((p) => p == productAdapter(product));
  }

  SailorCartProduct? getProduct(T product, [bool searchDraft = false]) {
    SailorCartProduct? result;

    final id = productAdapter(product).id;
    for (var p in _state.products) {
      if (p.id == id && (searchDraft || !p.draft)) {
        result = p;
        break;
      }
    }

    return result;
  }

  void addAddon(T product, E addon) {
    switch (addonAdapter(addon)) {
      case SailorCartSingleAddon _:
        addSingleAddon(product, addon);
        break;
      case SailorCartMultipleAddon _:
        addMultipleAddon(product, addon);
        break;
      case SailorCartCounterAddon _:
        addCounterAddon(product, addon);
        break;
      default:
        throw Exception('Invalid addon type');
    }
  }

  void addCounterAddon(T product, E addon) {
    var target = getProduct(product);
    target ??= productAdapter(product).copyWith(draft: true);

    final addonProduct = addonAdapter(addon) as SailorCartCounterAddon;
    final exists = target.addons.any((a) => a.id == addonProduct.id);
    if (!exists) {
      final newProduct = target.copyWith(
        addons: List.from(target.addons)
          ..add(
            addonProduct.copyWith(
                quantity:
                    addonProduct.quantity == 0 ? 1 : addonProduct.quantity),
          ),
      );

      _state = _state.copyWith(
        products: List.from(_state.products)
          ..removeWhere((p) => p.id == target!.id)
          ..add(newProduct),
      );
      notifyListeners();
      return;
    }

    final newProduct = target.copyWith(
      addons: List.from(target.addons)
          .map((a) {
            if (a.id == addonProduct.id) {
              return a.copyWith(
                quantity: a.quantity + 1,
              );
            }
            return a;
          })
          .toList()
          .cast(),
    );

    _state = _state.copyWith(
      products: List.from(_state.products)
        ..removeWhere((p) => p.id == target!.id)
        ..add(newProduct),
    );

    notifyListeners();
  }

  void addSingleAddon(T product, E addon) {
    var target = getProduct(product);
    target ??= productAdapter(product).copyWith(draft: true);

    var addonProduct = addonAdapter(addon) as SailorCartSingleAddon;
    addonProduct = addonProduct.copyWith(selected: true);

    final newProduct = target.copyWith(
      addons: List.from(target.addons)
        ..removeWhere(
            (a) => a is SailorCartSingleAddon && a.group == addonProduct.group)
        ..add(addonProduct),
    );

    _state = _state.copyWith(
      products: List.from(_state.products)
        ..removeWhere((p) => p.id == target!.id)
        ..add(newProduct),
    );

    notifyListeners();
  }

  void addMultipleAddon(T product, E addon) {
    var target = getProduct(product);
    target ??= productAdapter(product).copyWith(draft: true);

    final addonProduct = addonAdapter(addon) as SailorCartMultipleAddon;
    final exists = target.addons.any((a) => a.id == addonProduct.id);
    if (!exists) {
      final newProduct = target.copyWith(
        addons: List.from(target.addons)..add(addonProduct),
      );

      _state = _state.copyWith(
        products: List.from(_state.products)
          ..removeWhere((p) => p.id == target!.id)
          ..add(newProduct),
      );
      notifyListeners();
      return;
    }

    final newProduct = target.copyWith(
      addons: List.from(target.addons)
        ..removeWhere((a) => a.id == addonProduct.id),
    );

    _state = _state.copyWith(
      products: List.from(_state.products)
        ..removeWhere((p) => p.id == target!.id)
        ..add(newProduct),
    );

    notifyListeners();
  }

  void removeAddon(T product, E addon) {
    final target = getProduct(product);
    if (target == null) {
      return;
    }

    final addonProduct = addonAdapter(addon);
    final existingAddon = target.addons
        .firstWhere((a) => a.id == addonProduct.id, orElse: () => addonProduct);

    if (existingAddon is! SailorCartCounterAddon ||
        existingAddon.quantity == 1) {
      final newProduct = target.copyWith(
        addons: List.from(target.addons)
          ..removeWhere((a) => a.id == addonProduct.id),
      );

      _state = _state.copyWith(
        products: List.from(_state.products)
          ..removeWhere((p) => p.id == target.id)
          ..add(newProduct),
      );

      notifyListeners();
      return;
    }

    final newProduct = target.copyWith(
      addons: List.from(target.addons)
          .map((a) {
            if (a.id == addonProduct.id) {
              return a.copyWith(
                quantity: a.quantity - 1,
              );
            }
            return a;
          })
          .toList()
          .cast(),
    );

    _state = _state.copyWith(
      products: List.from(_state.products)
        ..removeWhere((p) => p.id == target.id)
        ..add(newProduct),
    );

    notifyListeners();
  }

  void promoteDraftProduct(T product) {
    final target = getProduct(product, true);
    if (target == null) {
      return;
    }

    final newProduct = target.copyWith(draft: false);

    _state = _state.copyWith(
      products: List.from(_state.products)
        ..removeWhere((p) => p.id == target.id)
        ..add(newProduct),
    );

    notifyListeners();
  }
}
