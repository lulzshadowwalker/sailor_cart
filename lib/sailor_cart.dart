library sailor_cart;

import 'dart:collection';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

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
class SailorCartProduct<T> {
  final String id;
  final List<SailorCartAddon> addons;
  final SailorPrice price;
  final int quantity;
  final bool draft;
  final T reference;
  final String referenceId;

  SailorCartProduct({
    required this.addons,
    required this.price,
    required this.quantity,
    required this.reference,
    required this.referenceId,
    this.draft = false,
  }) : id = const Uuid().v4();

  const SailorCartProduct._internal({
    required this.id,
    required this.addons,
    required this.price,
    required this.quantity,
    required this.reference,
    required this.referenceId,
    required this.draft,
  });

  SailorCartProduct copyWith({
    String? id,
    List<SailorCartAddon>? addons,
    SailorPrice? price,
    int? quantity,
    bool? draft,
    T? reference,
    String? referenceId,
  }) {
    return SailorCartProduct._internal(
      id: id ?? this.id,
      addons: addons ?? this.addons,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      draft: draft ?? this.draft,
      reference: reference ?? this.reference,
      referenceId: referenceId ?? this.referenceId,
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
        other.draft == draft &&
        other.referenceId == referenceId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        addons.hashCode ^
        price.hashCode ^
        quantity.hashCode ^
        draft.hashCode ^
        referenceId.hashCode;
  }

  @override
  String toString() =>
      'SailorCartProduct(id: $id, addons: $addons, price: $price, quantity: $quantity, draft: $draft, referenceId: $referenceId)';

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
abstract class SailorCartAddon<T> {
  final String id;
  final SailorPrice price;
  final T reference;

  const SailorCartAddon({
    required this.id,
    required this.price,
    required this.reference,
  });

  double get total => price.total;

  double get tax => price.tax;

  double get subtotal => price.subtotal;
}

@immutable
class SailorCartSingleAddon<T> extends SailorCartAddon<T> {
  final String group;
  final bool selected;

  const SailorCartSingleAddon({
    required super.id,
    required super.price,
    required super.reference,
    required this.group,
    this.selected = false,
  });

  SailorCartSingleAddon copyWith({
    String? id,
    SailorPrice? price,
    String? group,
    bool? selected,
    T? reference,
  }) {
    return SailorCartSingleAddon(
      id: id ?? super.id,
      price: price ?? super.price,
      reference: reference ?? super.reference,
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
}

@immutable
class SailorCartMultipleAddon<T> extends SailorCartAddon<T> {
  const SailorCartMultipleAddon({
    required super.id,
    required super.price,
    required super.reference,
  });

  SailorCartMultipleAddon copyWith({
    String? id,
    SailorPrice? price,
    T? reference,
  }) {
    return SailorCartMultipleAddon(
      id: id ?? super.id,
      price: price ?? super.price,
      reference: reference ?? super.reference,
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
}

@immutable
class SailorCartCounterAddon<T> extends SailorCartAddon<T> {
  final int min;
  final int max;
  final int quantity;

  const SailorCartCounterAddon({
    required super.id,
    required super.price,
    required super.reference,
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
    T? reference,
  }) {
    return SailorCartCounterAddon(
      id: id ?? super.id,
      price: price ?? super.price,
      reference: reference ?? super.reference,
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

  SailorCartProduct addProduct(T product) {
    final adaptedProduct = productAdapter(product);
    dev.log(
      "[addProduct] Attempting to add product with referenceId: ${adaptedProduct.referenceId}",
      name: "SailorCart.addProduct",
    );

    final exists = _state.products.any(
      (p) =>
          //  NOTE: addProduct method should only be used to add products without addons.
          //  to add products with addons, use addAdddon then addDraftProduct methods.
          p.addons.isEmpty && p.referenceId == adaptedProduct.referenceId,
    );

    if (!exists) {
      dev.log(
        "[addProduct] Product does not exist. Adding new product.",
        name: "SailorCart.addProduct",
      );
      final newProduct = adaptedProduct;
      _state = _state.copyWith(
        products: List.from(_state.products)..add(newProduct),
      );
      notifyListeners();
      dev.log(
        "[addProduct] Product added. Total products: ${_state.products.length}",
        name: "SailorCart.addProduct",
      );
      return newProduct;
    }

    dev.log(
      "[addProduct] Product exists. Incrementing quantity.",
      name: "SailorCart.addProduct",
    );
    final newProducts = _state.products.map((p) {
      if (p.addons.isEmpty && p.referenceId == adaptedProduct.referenceId) {
        final updated = p.copyWith(quantity: p.quantity + 1);

        dev.log(
          "[addProduct] Incremented product ${p.id} quantity to ${updated.quantity}",
          name: "SailorCart.addProduct",
        );
        return updated;
      }
      return p;
    }).toList();

    _state = _state.copyWith(products: newProducts);
    notifyListeners();
    dev.log(
      "[addProduct] Updated product quantity. Total products: ${_state.products.length}",
      name: "SailorCart.addProduct",
    );

    return newProducts
        .firstWhere((p) => p.referenceId == adaptedProduct.referenceId);
  }

  void removeProductById(String id) {
    dev.log(
      "[removeProductById] Attempting to remove product with ID: $id",
      name: "SailorCart.removeProductById",
    );
    final existing = _state.products.firstWhere((p) => p.id == id);
    if (existing.quantity == 1) {
      dev.log(
        "[removeProductById] Quantity is 1. Removing product entirely.",
        name: "SailorCart.removeProductById",
      );
      _state = _state.copyWith(
        products: List.from(_state.products)..removeWhere((p) => p.id == id),
      );
      notifyListeners();
      dev.log(
        "[removeProductById] Product removed. Total products: ${_state.products.length}",
        name: "SailorCart.removeProductById",
      );
      return;
    }

    dev.log(
      "[removeProductById] Quantity greater than 1. Decrementing quantity.",
      name: "SailorCart.removeProductById",
    );
    final newProducts = _state.products.map((p) {
      if (p.id == id) {
        final updated = p.copyWith(quantity: p.quantity - 1);
        dev.log(
          "[removeProductById] Decremented product $id quantity to ${updated.quantity}",
          name: "SailorCart.removeProductById",
        );
        return updated;
      }
      return p;
    }).toList();

    _state = _state.copyWith(products: newProducts);
    notifyListeners();
    dev.log(
      "[removeProductById] Notified listeners after quantity decrement.",
      name: "SailorCart.removeProductById",
    );
  }

  bool get isEmpty {
    final empty = _state.products.isEmpty;
    dev.log(
      "[isEmpty] Cart is ${empty ? 'empty' : 'not empty'}.",
      name: "SailorCart.isEmpty",
    );
    return empty;
  }

  SailorCartProduct? getProductById(String id) {
    dev.log(
      "[getProductById] Searching for product with ID: $id",
      name: "SailorCart.getProductById",
    );
    final exists = _state.products.any((p) => p.id == id);
    if (exists) {
      final found = _state.products.firstWhere((p) => p.id == id && !p.draft);
      dev.log(
        "[getProductById] Found product with ID: $id",
        name: "SailorCart.getProductById",
      );
      return found;
    }
    dev.log(
      "[getProductById] No product found with ID: $id",
      name: "SailorCart.getProductById",
    );
    return null;
  }

  SailorCartProduct getOrCreateDraft(T product) {
    dev.log(
      "[getOrCreateDraft] Checking for existing draft for product: ${productAdapter(product).referenceId}",
      name: "SailorCart.getOrCreateDraft",
    );
    final exists = _state.products.any(
      (p) =>
          p.draft &&
          p.referenceId ==
              productAdapter(product).copyWith(draft: true).referenceId,
    );
    if (exists) {
      final draft = _state.products.firstWhere(
        (p) =>
            p.draft &&
            p.referenceId ==
                productAdapter(product).copyWith(draft: true).referenceId,
      );
      dev.log(
        "[getOrCreateDraft] Found existing draft with ID: ${draft.id}",
        name: "SailorCart.getOrCreateDraft",
      );
      return draft;
    }

    final newDraft = productAdapter(product).copyWith(draft: true);
    dev.log(
      "[getOrCreateDraft] Creating new draft for product: ${newDraft.referenceId}",
      name: "SailorCart.getOrCreateDraft",
    );
    _state = _state.copyWith(
      products: List.from(_state.products)..add(newDraft),
    );
    notifyListeners();
    dev.log(
      "[getOrCreateDraft] New draft created with ID: ${newDraft.id}",
      name: "SailorCart.getOrCreateDraft",
    );
    return newDraft;
  }

  SailorCartProduct? getDraft(T product) {
    dev.log(
      "[getDraft] Searching for draft of product: ${productAdapter(product).referenceId}",
      name: "SailorCart.getDraft",
    );
    final exists = _state.products.any(
      (p) =>
          p.draft &&
          p.referenceId ==
              productAdapter(product).copyWith(draft: true).referenceId,
    );
    if (exists) {
      final draft = _state.products.firstWhere(
        (p) =>
            p.draft &&
            p.referenceId ==
                productAdapter(product).copyWith(draft: true).referenceId,
      );
      dev.log(
        "[getDraft] Found draft with ID: ${draft.id}",
        name: "SailorCart.getDraft",
      );
      return draft;
    }
    dev.log(
      "[getDraft] No draft found for product: ${productAdapter(product).referenceId}",
      name: "SailorCart.getDraft",
    );
    return null;
  }

  void clear() {
    dev.log(
      "[clear] Clearing all non-draft products from cart.",
      name: "SailorCart.clear",
    );
    _state = _state.copyWith(
      products: _state.products.where((p) => p.draft).toList(),
    );
    notifyListeners();
    dev.log(
      "[clear] Cart cleared. Remaining products: ${_state.products.length}",
      name: "SailorCart.clear",
    );
  }

  void addAddon(T product, E addon) {
    dev.log(
      "[addAddon] Adding addon to product: ${productAdapter(product).referenceId}",
      name: "SailorCart.addAddon",
    );
    switch (addonAdapter(addon)) {
      case SailorCartSingleAddon _:
        dev.log("[addAddon] Detected single addon type.",
            name: "SailorCart.addAddon");
        addSingleAddon(product, addon);
        break;
      case SailorCartMultipleAddon _:
        dev.log("[addAddon] Detected multiple addon type.",
            name: "SailorCart.addAddon");
        addMultipleAddon(product, addon);
        break;
      case SailorCartCounterAddon _:
        dev.log("[addAddon] Detected counter addon type.",
            name: "SailorCart.addAddon");
        addCounterAddon(product, addon);
        break;
      default:
        dev.log("[addAddon] Invalid addon type provided.",
            name: "SailorCart.addAddon");
        throw Exception('Invalid addon type');
    }
  }

  void addCounterAddon(T product, E addon) {
    dev.log(
      "[addCounterAddon] Adding counter addon to product: ${productAdapter(product).referenceId}",
      name: "SailorCart.addCounterAddon",
    );
    final target = getOrCreateDraft(product);
    final addonProduct = addonAdapter(addon) as SailorCartCounterAddon;
    final exists = target.addons.any((a) => a.id == addonProduct.id);
    if (!exists) {
      dev.log(
        "[addCounterAddon] Counter addon not found in product. Adding new counter addon with quantity: ${addonProduct.quantity}",
        name: "SailorCart.addCounterAddon",
      );
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
          ..removeWhere((p) => p.id == target.id)
          ..add(newProduct),
      );
      notifyListeners();
      dev.log(
        "[addCounterAddon] New counter addon added. Notified listeners.",
        name: "SailorCart.addCounterAddon",
      );
      return;
    }
    dev.log(
      "[addCounterAddon] Counter addon exists. Incrementing its quantity.",
      name: "SailorCart.addCounterAddon",
    );
    final newProduct = target.copyWith(
      addons: List.from(target.addons)
          .map((a) {
            if (a.id == addonProduct.id) {
              final updated = a.copyWith(quantity: a.quantity + 1);
              dev.log(
                "[addCounterAddon] Incremented counter addon ${a.id} quantity to ${updated.quantity}",
                name: "SailorCart.addCounterAddon",
              );
              return updated;
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
    dev.log(
      "[addCounterAddon] Counter addon quantity incremented. Notified listeners.",
      name: "SailorCart.addCounterAddon",
    );
  }

  void addSingleAddon(T product, E addon) {
    dev.log(
      "[addSingleAddon] Adding single addon to product: ${productAdapter(product).referenceId}",
      name: "SailorCart.addSingleAddon",
    );
    final target = getOrCreateDraft(product);
    var addonProduct = addonAdapter(addon) as SailorCartSingleAddon;
    addonProduct = addonProduct.copyWith(selected: true);
    dev.log(
      "[addSingleAddon] Marked addon ${addonProduct.id} as selected.",
      name: "SailorCart.addSingleAddon",
    );
    final newProduct = target.copyWith(
      addons: List.from(target.addons)
        ..removeWhere(
            (a) => a is SailorCartSingleAddon && a.group == addonProduct.group)
        ..add(addonProduct),
    );
    _state = _state.copyWith(
      products: List.from(_state.products)
        ..removeWhere((p) => p.id == target.id)
        ..add(newProduct),
    );
    notifyListeners();
    dev.log(
      "[addSingleAddon] Single addon added. Notified listeners.",
      name: "SailorCart.addSingleAddon",
    );
  }

  void addMultipleAddon(T product, E addon) {
    dev.log(
      "[addMultipleAddon] Adding multiple addon to product: ${productAdapter(product).referenceId}",
      name: "SailorCart.addMultipleAddon",
    );
    final target = getOrCreateDraft(product);
    final addonProduct = addonAdapter(addon) as SailorCartMultipleAddon;
    final exists = target.addons.any((a) => a.id == addonProduct.id);
    if (!exists) {
      dev.log(
        "[addMultipleAddon] Multiple addon not present. Adding new multiple addon.",
        name: "SailorCart.addMultipleAddon",
      );
      final newProduct = target.copyWith(
        addons: List.from(target.addons)..add(addonProduct),
      );
      _state = _state.copyWith(
        products: List.from(_state.products)
          ..removeWhere((p) => p.id == target.id)
          ..add(newProduct),
      );
      notifyListeners();
      dev.log(
        "[addMultipleAddon] Multiple addon added. Notified listeners.",
        name: "SailorCart.addMultipleAddon",
      );
      return;
    }
    dev.log(
      "[addMultipleAddon] Multiple addon exists. Removing addon from product.",
      name: "SailorCart.addMultipleAddon",
    );
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
    dev.log(
      "[addMultipleAddon] Multiple addon removed. Notified listeners.",
      name: "SailorCart.addMultipleAddon",
    );
  }

  void removeAddon(T product, E addon) {
    dev.log(
      "[removeAddon] Removing addon from product: ${productAdapter(product).referenceId}",
      name: "SailorCart.removeAddon",
    );
    final target = getDraft(product);
    if (target == null) {
      dev.log(
        "[removeAddon] No draft found for product. Aborting removal.",
        name: "SailorCart.removeAddon",
      );
      return;
    }
    final addonProduct = addonAdapter(addon);
    final existingAddon = target.addons
        .firstWhere((a) => a.id == addonProduct.id, orElse: () => addonProduct);
    if (existingAddon is! SailorCartCounterAddon ||
        existingAddon.quantity == 1) {
      dev.log(
        "[removeAddon] Single unit of addon ${addonProduct.id} exists. Removing addon entirely.",
        name: "SailorCart.removeAddon",
      );
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
      dev.log(
        "[removeAddon] Addon removed. Notified listeners.",
        name: "SailorCart.removeAddon",
      );
      return;
    }
    dev.log(
      "[removeAddon] Multiple units of addon ${addonProduct.id} exist. Decrementing quantity.",
      name: "SailorCart.removeAddon",
    );
    final newProduct = target.copyWith(
      addons: List.from(target.addons)
          .map((a) {
            if (a.id == addonProduct.id) {
              final updated = a.copyWith(quantity: a.quantity - 1);
              dev.log(
                "[removeAddon] Decremented addon ${a.id} quantity to ${updated.quantity}",
                name: "SailorCart.removeAddon",
              );
              return updated;
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
    dev.log(
      "[removeAddon] Addon quantity decremented. Notified listeners.",
      name: "SailorCart.removeAddon",
    );
  }

  SailorCartProduct? promoteDraftProduct(T product) {
    dev.log(
      "[promoteDraftProduct] Promoting draft product for reference: ${productAdapter(product).referenceId}",
      name: "SailorCart.promoteDraftProduct",
    );
    final target = getDraft(product);
    if (target == null) {
      dev.log(
        "[promoteDraftProduct] No draft product found. Aborting promotion.",
        name: "SailorCart.promoteDraftProduct",
      );
      return null;
    }

    final existsWithSameAddons = _state.products.any((p) {
      if (p.draft) {
        return false;
      }

      if (p.referenceId != target.referenceId) {
        return false;
      }

      if (p.addons.length != target.addons.length) {
        return false;
      }

      return p.addons.every((a) => target.addons.any((b) => a.id == b.id));
    });
    if (existsWithSameAddons) {
      // increment quanttiy for existing product and remove draft product
      final newProducts = _state.products.map((p) {
        if (p.draft) {
          return p;
        }

        if (p.referenceId != target.referenceId) {
          return p;
        }

        if (p.addons.length != target.addons.length) {
          return p;
        }

        if (!p.addons.every((a) => target.addons.any((b) => a.id == b.id))) {
          return p;
        }

        return p.copyWith(quantity: p.quantity + 1);
      }).toList();

      _state = _state.copyWith(
        products: newProducts,
      );

      notifyListeners();
      dev.log(
        "[promoteDraftProduct] Product already exists. Incremented quantity. Notified listeners.",
        name: "SailorCart.promoteDraftProduct",
      );

      return newProducts.firstWhere((p) => p.referenceId == target.referenceId);
    }

    final newProduct = target.copyWith(draft: false);
    _state = _state.copyWith(
      products: List.from(_state.products)
        ..removeWhere((p) => p.id == target.id)
        ..add(newProduct),
    );
    notifyListeners();
    dev.log(
      "[promoteDraftProduct] Draft promoted. Notified listeners.",
      name: "SailorCart.promoteDraftProduct",
    );

    return newProduct;
  }
}
