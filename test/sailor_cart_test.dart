import 'package:flutter_test/flutter_test.dart';
import 'package:sailor_cart/sailor_cart.dart';

class MyProduct {
  final String id;
  final double price;
  final double taxRate;
  final bool taxInclusive;

  MyProduct({
    required this.id,
    required this.price,
    required this.taxRate,
    required this.taxInclusive,
  });
}

class MyAddon {
  final String id;
  final double price;
  final double taxRate;
  final bool taxInclusive;
  final String type;
  final int quantity;
  final int min;
  final int max;

  MyAddon({
    required this.id,
    required this.price,
    required this.taxRate,
    required this.taxInclusive,
    required this.type,
    this.quantity = 0,
    this.min = 0,
    this.max = 99,
  });
}

void main() {
  group('cart tests', () {
    late SailorCart cart;

    setUp(() {
      cart = SailorCart<MyProduct, MyAddon>(
        productAdapter: (product) => SailorCartProduct(
          id: product.id,
          price: SailorPrice(
            value: product.price,
            taxRate: product.taxRate,
            taxInclusive: product.taxInclusive,
          ),
          quantity: 1,
          addons: const [],
        ),
        addonAdapter: (addon) {
          switch (addon.type) {
            case 'single':
              //  TODO: Make quantity an optinal parameter
              return SailorCartSingleAddon(
                id: addon.id,
                price: SailorPrice(
                  value: addon.price,
                  taxRate: addon.taxRate,
                  taxInclusive: addon.taxInclusive,
                ),
                group: 'example-group',
                quantity: addon.quantity,
              );
            case 'multiple':
              return SailorCartMultipleAddon(
                id: addon.id,
                price: SailorPrice(
                  value: addon.price,
                  taxRate: addon.taxRate,
                  taxInclusive: addon.taxInclusive,
                ),
                quantity: addon.quantity,
              );
            case 'counter':
              return SailorCartCounterAddon(
                id: addon.id,
                min: addon.min,
                max: addon.max,
                price: SailorPrice(
                  value: addon.price,
                  taxRate: addon.taxRate,
                  taxInclusive: addon.taxInclusive,
                ),
                quantity: addon.quantity,
              );

            default:
              throw Exception('Unknown addon type');
          }
        },
      );
    });

    test('cart is initially empty', () {
      expect(cart.isEmpty, isTrue);
    });

    test('isEmpty is true when cart is empty', () {
      expect(cart.isEmpty, isTrue);
    });

    test('isEmpty is false when cart is not empty', () {
      cart.addProduct(MyProduct(
          id: 'product', price: 10, taxRate: 0.1, taxInclusive: true));
      expect(cart.isEmpty, isFalse);
    });

    test('it adds a product to the cart', () {
      bool notified = false;
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      cart.addListener(() => notified = true);
      cart.addProduct(product);

      expect(cart.isEmpty, isFalse);
      expect(cart.products.length, 1);
      expect(cart.products.first.price.value, 10);
      expect(cart.products.first.price.taxRate, 0.1);
      expect(cart.products.first.price.taxInclusive, isTrue);
      expect(notified, isTrue);
    });

    test('it removes a product from the cart by object', () {
      bool notified = false;
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      cart.addListener(() => notified = true);
      cart.addProduct(product);
      cart.removeProduct(product);

      expect(cart.isEmpty, isTrue);
      expect(cart.products.length, 0);
      expect(notified, isTrue);
    });

    test('hasProduct returns true when the product is in the cart', () {
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      cart.addProduct(product);

      expect(cart.hasProduct(product), isTrue);
    });

    test('hasProduct returns false when the product is not in the cart', () {
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);

      expect(cart.hasProduct(product), isFalse);
    });

    test('getProductById returns the product with the given id', () {
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      cart.addProduct(product);

      final foundProduct = cart.getProduct(product);

      expect(foundProduct, isNotNull);
      expect(foundProduct!.id, product.id);
    });

    test('getProductById returns null when the product is not in the cart', () {
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);

      final foundProduct = cart.getProduct(product);

      expect(foundProduct, isNull);
    });

    test('it can add an addon of type multiple to a product', () {
      bool notified = false;
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      final addon = MyAddon(
          id: 'addon',
          price: 5,
          taxRate: 0.1,
          taxInclusive: true,
          type: 'multiple');
      cart.addListener(() => notified = true);
      cart.addProduct(product);
      cart.addAddon(product, addon);

      expect(cart.products.first.addons.length, 1);
      expect(cart.products.first.addons.first.price.value, 5);
      expect(cart.products.first.addons.first.price.taxRate, 0.1);
      expect(cart.products.first.addons.first.price.taxInclusive, isTrue);
      expect(cart.products.first.addons.first.quantity, 1);
      expect(notified, isTrue);
    });

    test(
        'it can add an addon of type multiple to a product with a defined quantity',
        () {
      bool notified = false;
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      final addon = MyAddon(
          id: 'addon',
          price: 5,
          taxRate: 0.1,
          taxInclusive: true,
          type: 'multiple',
          quantity: 10);
      cart.addListener(() => notified = true);
      cart.addProduct(product);
      cart.addAddon(product, addon);

      expect(cart.products.first.addons.length, 1);
      expect(cart.products.first.addons.first.price.value, 5);
      expect(cart.products.first.addons.first.price.taxRate, 0.1);
      expect(cart.products.first.addons.first.price.taxInclusive, isTrue);
      expect(cart.products.first.addons.first.quantity, 10);
      expect(notified, isTrue);
    });

    test(
        'it can increment addon of type multiple\'s quantity for an existing addon',
        () {
      bool notified = false;
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      final addon = MyAddon(
          id: 'addon',
          price: 5,
          taxRate: 0.1,
          taxInclusive: true,
          type: 'multiple');
      cart.addListener(() => notified = true);
      cart.addProduct(product);
      cart.addAddon(product, addon);
      cart.addAddon(product, addon);

      expect(cart.products.first.addons.length, 1);
      expect(cart.products.first.addons.first.price.value, 5);
      expect(cart.products.first.addons.first.price.taxRate, 0.1);
      expect(cart.products.first.addons.first.price.taxInclusive, isTrue);
      expect(cart.products.first.addons.first.quantity, 2);
      expect(notified, isTrue);
    });

    test('it can remove an addon of type multiple from a product', () {
      bool notified = false;
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      final addon = MyAddon(
          id: 'addon',
          price: 5,
          taxRate: 0.1,
          taxInclusive: true,
          type: 'multiple');
      cart.addListener(() => notified = true);
      cart.addProduct(product);
      cart.addAddon(product, addon);
      cart.removeAddon(product, addon);

      expect(cart.products.length, 1);
      expect(cart.products.first.addons.length, 0);
      expect(notified, isTrue);
    });

    test(
        'it can decrement addon of type multiple\'s quantity for an existing addon',
        () {
      bool notified = false;
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      final addon = MyAddon(
          id: 'addon',
          price: 5,
          taxRate: 0.1,
          taxInclusive: true,
          type: 'multiple');
      cart.addListener(() => notified = true);
      cart.addProduct(product);
      cart.addAddon(product, addon);
      cart.addAddon(product, addon);
      cart.removeAddon(product, addon);

      expect(cart.products.first.addons.length, 1);
      expect(cart.products.first.addons.first.price.value, 5);
      expect(cart.products.first.addons.first.price.taxRate, 0.1);
      expect(cart.products.first.addons.first.price.taxInclusive, isTrue);
      expect(cart.products.first.addons.first.quantity, 1);
      expect(notified, isTrue);
    });

    test('it can select an addon of type (radio) for a product', () {
      bool notified = false;
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      final addon1 = MyAddon(
          id: 'addon1',
          price: 5,
          taxRate: 0.1,
          taxInclusive: true,
          type: 'single');
      final addon2 = MyAddon(
          id: 'addon2',
          price: 10,
          taxRate: 0.2,
          taxInclusive: true,
          type: 'single');
      cart.addListener(() => notified = true);
      cart.addProduct(product);
      cart.addAddon(product, addon1);
      cart.addAddon(product, addon2);

      expect(cart.products.first.addons.length, 1);
      expect(cart.products.first.addons.first.price.value, 10);
      expect(cart.products.first.addons.first.price.taxRate, 0.2);
      expect(cart.products.first.addons.first.price.taxInclusive, isTrue);

      cart.addAddon(product, addon1);
      expect(
          (cart.products.first.addons.first as SailorCartSingleAddon).selected,
          isTrue);
      expect(notified, isTrue);
    });

    test('it can add an addon of type counter to a product', () {
      bool notified = false;
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      final addon = MyAddon(
          id: 'addon',
          price: 5,
          taxRate: 0.1,
          taxInclusive: true,
          type: 'counter');
      cart.addListener(() => notified = true);
      cart.addProduct(product);
      cart.addAddon(product, addon);

      expect(cart.products.first.addons.length, 1);
      expect(cart.products.first.addons.first.price.value, 5);
      expect(cart.products.first.addons.first.price.taxRate, 0.1);
      expect(cart.products.first.addons.first.price.taxInclusive, isTrue);
      expect(cart.products.first.addons.first.quantity, 1);
      expect(notified, isTrue);
    });

    test('it can increment an addon of type counter to a product', () {
      bool notified = false;
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      final addon = MyAddon(
          id: 'addon',
          price: 5,
          taxRate: 0.1,
          taxInclusive: true,
          type: 'counter');
      cart.addListener(() => notified = true);
      cart.addProduct(product);
      cart.addAddon(product, addon);
      cart.addAddon(product, addon);

      expect(cart.products.first.addons.length, 1);
      expect(cart.products.first.addons.first.price.value, 5);
      expect(cart.products.first.addons.first.price.taxRate, 0.1);
      expect(cart.products.first.addons.first.price.taxInclusive, isTrue);
      expect(cart.products.first.addons.first.quantity, 2);
      expect(notified, isTrue);
    });

    test('it can removed an addon of type counter to a product', () {
      bool notified = false;
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      final addon = MyAddon(
          id: 'addon',
          price: 5,
          taxRate: 0.1,
          taxInclusive: true,
          type: 'counter');
      cart.addListener(() => notified = true);
      cart.addProduct(product);
      cart.addAddon(product, addon);
      cart.removeAddon(product, addon);

      expect(cart.products.first.addons.length, 0);
      expect(notified, isTrue);
    });

    test('it can decrement an addon of type counter from a product', () {
      bool notified = false;
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      final addon = MyAddon(
          id: 'addon',
          price: 5,
          taxRate: 0.1,
          taxInclusive: true,
          type: 'counter');
      cart.addListener(() => notified = true);
      cart.addProduct(product);
      cart.addAddon(product, addon);
      cart.addAddon(product, addon);
      cart.removeAddon(product, addon);

      expect(cart.products.first.addons.length, 1);
      expect(cart.products.first.addons.first.price.value, 5);
      expect(cart.products.first.addons.first.price.taxRate, 0.1);
      expect(cart.products.first.addons.first.price.taxInclusive, isTrue);
      expect(cart.products.first.addons.first.quantity, 1);
      expect(notified, isTrue);
    });

    test(
        'it creates a draft product when adding an addon of type counter to a non-existing product',
        () {
      bool notified = false;
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      final addon = MyAddon(
          id: 'addon',
          price: 5,
          taxRate: 0.1,
          taxInclusive: true,
          type: 'counter');
      cart.addListener(() => notified = true);
      cart.addAddon(product, addon);

      expect(cart.products.length, 0);

      final draft = cart.getProduct(product, true);
      expect(draft, isNotNull);
      expect(draft!.addons.length, 1);
      expect(draft.addons.first.price.value, 5);
      expect(draft.addons.first.price.taxRate, 0.1);
      expect(draft.addons.first.price.taxInclusive, isTrue);
      expect(draft.addons.first.quantity, 1);
      expect(notified, isTrue);
    });

    test(
        'it promotes a draft product to a full product when calling promote product',
        () {
      bool notified = false;
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      final addon = MyAddon(
          id: 'addon',
          price: 5,
          taxRate: 0.1,
          taxInclusive: true,
          type: 'counter');
      cart.addListener(() => notified = true);
      cart.addAddon(product, addon);
      cart.promoteDraftProduct(product);

      expect(cart.products.length, 1);
      expect(cart.products.first.id, product.id);
      expect(cart.products.first.addons.length, 1);
      expect(cart.products.first.addons.first.price.value, 5);
      expect(cart.products.first.addons.first.price.taxRate, 0.1);
      expect(cart.products.first.addons.first.price.taxInclusive, isTrue);
      expect(cart.products.first.addons.first.quantity, 1);
      expect(notified, isTrue);
    });
  });

  group('SailorCartProduct price calculations', () {
    const basePriceExclusive = SailorPrice(
      value: 200.0,
      taxRate: 10.0,
      taxInclusive: false,
    );

    const basePriceInclusive = SailorPrice(
      value: 220.0,
      taxRate: 10.0,
      taxInclusive: true,
    );

    const basePricePercentage = SailorPrice(
      value: 150.0,
      taxRate: 5.0,
      taxInclusive: false,
      percentage: true,
    );

    const addonPriceExclusive = SailorPrice(
      value: 50.0,
      taxRate: 5.0,
      taxInclusive: false,
    );

    const addonPriceInclusive = SailorPrice(
      value: 55.0,
      taxRate: 10.0,
      taxInclusive: true,
    );

    const addonPricePercentage = SailorPrice(
      value: 30.0,
      taxRate: 10.0,
      taxInclusive: false,
      percentage: true,
    );

    const addon1 = SailorCartMultipleAddon(
      id: 'addon_1',
      price: addonPriceExclusive,
      quantity: 2,
    );

    const addon2 = SailorCartMultipleAddon(
      id: 'addon_2',
      price: addonPriceInclusive,
      quantity: 1,
    );

    const addon3 = SailorCartMultipleAddon(
      id: 'addon_3',
      price: addonPricePercentage,
      quantity: 3,
    );

    //  FIX:
    // test('should calculate total correctly with tax-exclusive price and addons',
    //     () {
    //   const product = SailorCartProduct(
    //     id: 'product_1',
    //     price: basePriceExclusive,
    //     addons: [addon1, addon2],
    //     quantity: 2,
    //   );

    //   const expectedTotal = ((200 + 10) + (50 + 2.5) * 2 + 55) * 2;
    //   expect(product.total, closeTo(expectedTotal, 0.0001));
    // });

    test('should calculate total correctly with tax-inclusive price and addons',
        () {
      const product = SailorCartProduct(
        id: 'product_2',
        price: basePriceInclusive,
        addons: [addon2, addon3],
        quantity: 1,
      );

      const expectedTotal = 220 + 55 + (30 + 3) * 3;
      expect(product.total, closeTo(expectedTotal, 0.0001));
    });

    //  FIX:
    // test('should calculate total correctly with percentage-based tax', () {
    //   const product = SailorCartProduct(
    //     id: 'product_3',
    //     price: basePricePercentage,
    //     addons: [addon1, addon3],
    //     quantity: 3,
    //   );

    //   const expectedTotal = ((150 + 7.5) + (50 + 2.5) * 2 + (30 + 3) * 3) * 3;
    //   expect(product.total, closeTo(expectedTotal, 0.0001));
    // });

    //  FIX:
    // test('should calculate tax correctly with tax-exclusive price and addons',
    //     () {
    //   const product = SailorCartProduct(
    //     id: 'product_4',
    //     price: basePriceExclusive,
    //     addons: [addon1, addon3],
    //     quantity: 2,
    //   );

    //   const expectedTax = (10 + (50 * 0.05) * 2 + (30 * 0.1) * 3) * 2;
    //   expect(product.tax, closeTo(expectedTax, 0.0001));
    // });

    test('should calculate tax correctly with tax-inclusive price and addons',
        () {
      const product = SailorCartProduct(
        id: 'product_5',
        price: basePriceInclusive,
        addons: [addon2],
        quantity: 1,
      );

      const expectedTax = 20 + 5;
      expect(product.tax, closeTo(expectedTax, 0.0001));
    });

    test(
        'should calculate subtotal correctly with tax-exclusive price and addons',
        () {
      const product = SailorCartProduct(
        id: 'product_6',
        price: basePriceExclusive,
        addons: [addon1, addon3],
        quantity: 3,
      );

      const expectedSubtotal = ((200) + (50) * 2 + (30) * 3) * 3;
      expect(product.subtotal, closeTo(expectedSubtotal, 0.0001));
    });

    //  FIX:
    // test(
    //     'should calculate subtotal correctly with tax-inclusive price and addons',
    //     () {
    //   const product = SailorCartProduct(
    //     id: 'product_7',
    //     price: basePriceInclusive,
    //     addons: [addon2, addon3],
    //     quantity: 1,
    //   );

    //   const expectedSubtotal = (220 - 20) + (55 - 5) + ((30 - 3) * 3);
    //   expect(product.subtotal, closeTo(expectedSubtotal, 0.0001));
    // });

    test('should correctly override equality', () {
      const product1 = SailorCartProduct(
        id: 'product_8',
        price: basePriceExclusive,
        addons: [addon1, addon2],
        quantity: 1,
      );

      const product2 = SailorCartProduct(
        id: 'product_8',
        price: basePriceExclusive,
        addons: [addon1, addon2],
        quantity: 1,
      );

      expect(product1, equals(product2));
    });

    test('should return false for different product objects', () {
      const product1 = SailorCartProduct(
        id: 'product_9',
        price: basePriceExclusive,
        addons: [addon1],
        quantity: 1,
      );

      const product2 = SailorCartProduct(
        id: 'product_10',
        price: basePriceExclusive,
        addons: [addon1],
        quantity: 1,
      );

      expect(product1 == product2, false);
    });
  });

  group('SailorCartAddon price calculations', () {
    const priceExclusive = SailorPrice(
      value: 100.0,
      taxRate: 10.0,
      taxInclusive: false,
    );

    const priceInclusive = SailorPrice(
      value: 110.0,
      taxRate: 10.0,
      taxInclusive: true,
    );

    const pricePercentage = SailorPrice(
      value: 100.0,
      taxRate: 10.0,
      taxInclusive: false,
      percentage: true,
    );

    test('should calculate total correctly when tax is exclusive', () {
      const addon = SailorCartMultipleAddon(
        id: 'addon_1',
        price: priceExclusive,
        quantity: 2,
      );

      expect(addon.total, 220.0); // (100 + 10) * 2
    });

    test('should calculate total correctly when tax is inclusive', () {
      const addon = SailorCartMultipleAddon(
        id: 'addon_2',
        price: priceInclusive,
        quantity: 3,
      );

      expect(addon.total, 330.0); // 110 * 3
    });

    test('should calculate total correctly with percentage tax', () {
      const addon = SailorCartMultipleAddon(
        id: 'addon_3',
        price: pricePercentage,
        quantity: 1,
      );

      expect(addon.total, 110.0); // 100 + (100 * 10%) = 110
    });

    test('should calculate tax correctly when tax is exclusive', () {
      const addon = SailorCartMultipleAddon(
        id: 'addon_4',
        price: priceExclusive,
        quantity: 2,
      );

      expect(addon.tax, 20.0); // 10 * 2
    });

    test('should calculate tax correctly when tax is inclusive', () {
      const addon = SailorCartMultipleAddon(
        id: 'addon_5',
        price: priceInclusive,
        quantity: 1,
      );

      expect(addon.tax,
          closeTo(10, 0.0001)); // 110 includes tax, so extracted tax is 10
    });

    test('should calculate tax correctly with percentage tax', () {
      const addon = SailorCartMultipleAddon(
        id: 'addon_6',
        price: pricePercentage,
        quantity: 4,
      );

      expect(addon.tax, 40.0); // (100 * 10%) * 4 = 40
    });

    test('should calculate subtotal correctly when tax is exclusive', () {
      const addon = SailorCartMultipleAddon(
        id: 'addon_7',
        price: priceExclusive,
        quantity: 3,
      );

      expect(addon.subtotal, 300.0); // 100 * 3
    });

    test('should calculate subtotal correctly when tax is inclusive', () {
      const addon = SailorCartMultipleAddon(
        id: 'addon_8',
        price: priceInclusive,
        quantity: 5,
      );

      expect(addon.subtotal,
          closeTo(500.0, 0.0001)); // Allowing a small margin of error
    });

    test('should calculate subtotal correctly with percentage tax', () {
      const addon = SailorCartMultipleAddon(
        id: 'addon_9',
        price: pricePercentage,
        quantity: 2,
      );

      expect(addon.subtotal, 200.0); // 100 * 2
    });

    test('should override equality correctly', () {
      const addon1 = SailorCartMultipleAddon(
        id: 'addon_10',
        price: priceExclusive,
        quantity: 1,
      );

      const addon2 = SailorCartMultipleAddon(
        id: 'addon_10',
        price: priceExclusive,
        quantity: 1,
      );

      expect(addon1, equals(addon2));
    });

    test('should return false for different addon objects', () {
      const addon1 = SailorCartMultipleAddon(
        id: 'addon_11',
        price: priceExclusive,
        quantity: 1,
      );

      const addon2 = SailorCartMultipleAddon(
        id: 'addon_12',
        price: priceExclusive,
        quantity: 1,
      );

      expect(addon1 == addon2, false);
    });
  });

  group('SailorPrice', () {
    test('should correctly initialize with given values', () {
      const price = SailorPrice(
        value: 100.0,
        taxInclusive: false,
        taxRate: 10.0,
      );

      expect(price.value, 100.0);
      expect(price.taxInclusive, false);
      expect(price.taxRate, 10.0);
      expect(price.percentage, false);
    });

    test('should correctly calculate total for tax-exclusive prices', () {
      const price =
          SailorPrice(value: 100.0, taxInclusive: false, taxRate: 10.0);
      expect(price.total, 110.0);
    });

    test('should correctly calculate total for tax-inclusive prices', () {
      const price =
          SailorPrice(value: 110.0, taxInclusive: true, taxRate: 10.0);
      expect(price.total, 110.0);
    });

    test('should correctly calculate total for percentage-based taxes', () {
      const price = SailorPrice(
          value: 100.0, taxInclusive: false, taxRate: 10.0, percentage: true);
      expect(price.total, 110.0);
    });

    test('should correctly calculate subtotal for tax-exclusive prices', () {
      const price =
          SailorPrice(value: 100.0, taxInclusive: false, taxRate: 10.0);
      expect(price.subtotal, 100.0);
    });

    test('should correctly calculate subtotal for tax-inclusive prices', () {
      const price =
          SailorPrice(value: 110.0, taxInclusive: true, taxRate: 10.0);
      expect(price.subtotal, closeTo(100.0, 0.001));
    });

    test('should correctly calculate tax amount for tax-exclusive prices', () {
      const price =
          SailorPrice(value: 100.0, taxInclusive: false, taxRate: 10.0);
      expect(price.tax, 10.0);
    });

    test('should correctly calculate tax amount for tax-inclusive prices', () {
      const price =
          SailorPrice(value: 110.0, taxInclusive: true, taxRate: 10.0);
      expect(price.tax, closeTo(10.0, 0.001));
    });

    test('should correctly calculate tax amount for percentage-based taxes',
        () {
      const price = SailorPrice(
          value: 100.0, taxInclusive: false, taxRate: 10.0, percentage: true);
      expect(price.tax, 10.0);
    });

    test('should support copyWith() method', () {
      const price =
          SailorPrice(value: 100.0, taxInclusive: false, taxRate: 10.0);
      final updated = price.copyWith(value: 200.0, taxInclusive: true);

      expect(updated.value, 200.0);
      expect(updated.taxInclusive, true);
      expect(updated.taxRate, 10.0); // Should remain unchanged
    });

    test('should correctly implement equality', () {
      const price1 =
          SailorPrice(value: 100.0, taxInclusive: false, taxRate: 10.0);
      const price2 =
          SailorPrice(value: 100.0, taxInclusive: false, taxRate: 10.0);
      const price3 =
          SailorPrice(value: 200.0, taxInclusive: false, taxRate: 10.0);

      expect(price1, equals(price2));
      expect(price1, isNot(equals(price3)));
    });

    test('should correctly implement hashCode', () {
      const price1 =
          SailorPrice(value: 100.0, taxInclusive: false, taxRate: 10.0);
      const price2 =
          SailorPrice(value: 100.0, taxInclusive: false, taxRate: 10.0);

      expect(price1.hashCode, equals(price2.hashCode));
    });

    test('should return expected string representation', () {
      const price =
          SailorPrice(value: 100.0, taxInclusive: false, taxRate: 10.0);
      expect(
        price.toString(),
        'SailorPrice(value: 100.0, taxInclusive: false, taxRate: 10.0, percentage: false)',
      );
    });
  });
}
