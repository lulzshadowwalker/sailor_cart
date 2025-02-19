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
  group('customer simulations', () {
    test('customer simulation no.1', () {
      /**
     * Simulation no. 1:
     * 1. Add a product without addons.
     * 2. Add a product with three addon types (single, multiple, counter).
     * 3. Re-add the product from step 1 (should increment its quantity).
     * 4. Re-add a counter addon for the product from step 2 (should add a new product since they do not have the same addons).
     * 5. Add a different addon to the product from step 2 (should create a new product entry).
     * 6. Remove the product from step 1 (should decrement its quantity).
     * 7. Remove the product from step 2 (should remove it completely if quantity is 1).
     */

      // Create the cart instance.
      final cart = SailorCart<MyProduct, MyAddon>(
        productAdapter: (product) => SailorCartProduct<MyProduct>(
          price: SailorPrice(
            value: product.price,
            taxRate: product.taxRate,
            taxInclusive: product.taxInclusive,
          ),
          quantity: 1,
          addons: const [],
          reference: product,
          referenceId: product.id,
        ),
        addonAdapter: (addon) {
          switch (addon.type) {
            case 'single':
              return SailorCartSingleAddon<MyAddon>(
                id: addon.id,
                price: SailorPrice(
                  value: addon.price,
                  taxRate: addon.taxRate,
                  taxInclusive: addon.taxInclusive,
                ),
                group: 'example-group',
                reference: addon,
              );
            case 'multiple':
              return SailorCartMultipleAddon<MyAddon>(
                id: addon.id,
                price: SailorPrice(
                  value: addon.price,
                  taxRate: addon.taxRate,
                  taxInclusive: addon.taxInclusive,
                ),
                reference: addon,
              );
            case 'counter':
              return SailorCartCounterAddon<MyAddon>(
                id: addon.id,
                min: addon.min ?? 0,
                max: addon.max ?? 10,
                price: SailorPrice(
                  value: addon.price,
                  taxRate: addon.taxRate,
                  taxInclusive: addon.taxInclusive,
                ),
                quantity: addon.quantity,
                reference: addon,
              );
            default:
              throw Exception('Unknown addon type');
          }
        },
      );

      // Define products.
      final prodWithoutAddons = MyProduct(
        id: 'product1',
        price: 10,
        taxRate: 0.1,
        taxInclusive: true,
      );
      final prodWithAddons = MyProduct(
        id: 'product2',
        price: 10,
        taxRate: 0.1,
        taxInclusive: true,
      );

      // Define addons.
      final singleAddon = MyAddon(
        id: 'addon1',
        price: 5,
        taxRate: 0.1,
        taxInclusive: true,
        type: 'single',
      );
      final multipleAddon = MyAddon(
        id: 'addon2',
        price: 5,
        taxRate: 0.1,
        taxInclusive: true,
        type: 'multiple',
      );
      final counterAddon = MyAddon(
        id: 'addon3',
        price: 5,
        taxRate: 0.1,
        taxInclusive: true,
        type: 'counter',
        quantity: 2,
      );

      // Step 1: Add product without addons.
      final prod1Entry = cart.addProduct(prodWithoutAddons);
      expect(prod1Entry.quantity, equals(1));

      // Step 2: Add product with addons.
      cart.addAddon(prodWithAddons, singleAddon);
      cart.addAddon(prodWithAddons, multipleAddon);
      cart.addAddon(prodWithAddons, counterAddon);
      final draftProd2 = cart.promoteDraftProduct(prodWithAddons);
      expect(draftProd2, isNotNull);
      final finalizedProd2 = cart.getProductById(draftProd2!.id);
      expect(finalizedProd2, isNotNull);
      expect(
        finalizedProd2!.addons
            .any((a) => a is SailorCartSingleAddon && a.id == singleAddon.id),
        isTrue,
      );
      expect(
        finalizedProd2.addons.any(
            (a) => a is SailorCartMultipleAddon && a.id == multipleAddon.id),
        isTrue,
      );
      final initialCounter = finalizedProd2.addons.firstWhere(
              (a) => a is SailorCartCounterAddon && a.id == counterAddon.id)
          as SailorCartCounterAddon;
      expect(initialCounter.quantity, equals(counterAddon.quantity));

      // Step 3: Re-add product without addons (should increment quantity).
      final prod1Updated = cart.addProduct(prodWithoutAddons);
      final updatedProd1 = cart.getProductById(prod1Updated.id);
      expect(updatedProd1, isNotNull);
      expect(updatedProd1!.quantity, equals(2));

      // Step 4: Re-add the counter addon for the product with addons. (should add a new product since they do not have the same addons)
      cart.addAddon(prodWithAddons, counterAddon);
      final promoted = cart.promoteDraftProduct(prodWithAddons);
      final updatedProd2 = cart.getProductById(finalizedProd2.id);
      expect(updatedProd2, isNotNull);
      final updatedCounter = updatedProd2!.addons.firstWhere(
              (a) => a is SailorCartCounterAddon && a.id == counterAddon.id)
          as SailorCartCounterAddon;
      expect(updatedCounter.quantity, equals(counterAddon.quantity));
      expect(promoted, isNotNull);
      expect(promoted!.quantity, 1);
      expect(promoted.addons.length, equals(1));

      // Step 5: Add a new addon combination to the product with addons.
      final newSingleAddon = MyAddon(
        id: 'addon4',
        price: 7,
        taxRate: 0.1,
        taxInclusive: true,
        type: 'single',
      );
      cart.addAddon(prodWithAddons, newSingleAddon);
      cart.promoteDraftProduct(prodWithAddons);
      // Assuming the new addon combination creates a separate product entry,
      // verify that the new single addon is present.
      final prod2Final = cart.getProductById(finalizedProd2.id);
      expect(prod2Final, isNotNull);
      // expect(
      //   prod2Final!.addons.any(
      //       (a) => a is SailorCartSingleAddon && a.id == newSingleAddon.id),
      //   isTrue,
      // );

      // Step 6: Remove product without addons (should decrement quantity).
      cart.removeProductById(updatedProd1!.id);
      final prod1AfterRemoval = cart.getProductById(updatedProd1.id);
      // expect(prod1AfterRemoval, isNotNull);
      // expect(prod1AfterRemoval!.quantity, equals(1));

      // Step 7: Remove product with addons (should remove it if quantity is 1).
      cart.removeProductById(finalizedProd2.id);
      expect(cart.getProductById(finalizedProd2.id), isNull);

      final product3 = MyProduct(
        id: 'product3',
        price: 10,
        taxRate: 0.1,
        taxInclusive: true,
      );

      cart.addAddon(product3, singleAddon);
      final product3Finalized = cart.promoteDraftProduct(product3);
      expect(product3Finalized, isNotNull);
      expect(product3Finalized!.addons.length, equals(1));
      expect(product3Finalized.quantity, equals(1));

      cart.addAddon(product3, singleAddon);
      final product3Updated = cart.promoteDraftProduct(product3);
      expect(product3Updated, isNotNull);
      expect(product3Updated!.addons.length, equals(1));
      expect(product3Updated.quantity, equals(2));
    });
  });

  group('cart tests', () {
    late SailorCart cart;

    setUp(() {
      cart = SailorCart<MyProduct, MyAddon>(
        productAdapter: (product) => SailorCartProduct<MyProduct>(
          price: SailorPrice(
            value: product.price,
            taxRate: product.taxRate,
            taxInclusive: product.taxInclusive,
          ),
          quantity: 1,
          addons: const [],
          reference: product,
          referenceId: product.id,
        ),
        addonAdapter: (addon) {
          switch (addon.type) {
            case 'single':
              return SailorCartSingleAddon<MyAddon>(
                id: addon.id,
                price: SailorPrice(
                  value: addon.price,
                  taxRate: addon.taxRate,
                  taxInclusive: addon.taxInclusive,
                ),
                group: 'example-group',
                reference: addon,
              );
            case 'multiple':
              return SailorCartMultipleAddon<MyAddon>(
                id: addon.id,
                price: SailorPrice(
                  value: addon.price,
                  taxRate: addon.taxRate,
                  taxInclusive: addon.taxInclusive,
                ),
                reference: addon,
              );
            case 'counter':
              return SailorCartCounterAddon<MyAddon>(
                id: addon.id,
                min: addon.min,
                max: addon.max,
                price: SailorPrice(
                  value: addon.price,
                  taxRate: addon.taxRate,
                  taxInclusive: addon.taxInclusive,
                ),
                quantity: addon.quantity,
                reference: addon,
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

    test('equal products', () {
      final product1 = SailorCartProduct(
        price: const SailorPrice(value: 10, taxRate: 0.1, taxInclusive: true),
        quantity: 1,
        addons: const [
          SailorCartMultipleAddon(
            id: 'addon',
            price: SailorPrice(value: 5, taxRate: 0.1, taxInclusive: true),
            reference: null,
          ),
        ],
        reference: MyProduct(
          id: 'product',
          price: 10,
          taxRate: 0.1,
          taxInclusive: true,
        ),
        referenceId: 'product',
      );

      final product2 = SailorCartProduct(
        price: const SailorPrice(value: 10, taxRate: 0.1, taxInclusive: true),
        quantity: 1,
        addons: const [
          SailorCartMultipleAddon(
            id: 'addon',
            price: SailorPrice(value: 5, taxRate: 0.1, taxInclusive: true),
            reference: null,
          ),
        ],
        reference: MyProduct(
          id: 'product',
          price: 10,
          taxRate: 0.1,
          taxInclusive: true,
        ),
        referenceId: 'product',
      );

      expect(product1.copyWith(id: product2.id), equals(product2));
    });

    test('not equal products', () {
      final product1 = SailorCartProduct(
        price: const SailorPrice(value: 10, taxRate: 0.1, taxInclusive: true),
        quantity: 1,
        addons: const [
          SailorCartMultipleAddon(
            id: 'addon',
            price: SailorPrice(value: 5, taxRate: 0.1, taxInclusive: true),
            reference: null,
          ),
        ],
        reference: MyProduct(
          id: 'product',
          price: 10,
          taxRate: 0.1,
          taxInclusive: true,
        ),
        referenceId: 'product',
      );

      final product2 = SailorCartProduct(
        price: const SailorPrice(value: 10, taxRate: 0.1, taxInclusive: true),
        quantity: 1,
        addons: const [
          SailorCartMultipleAddon(
            id: 'addon',
            price: SailorPrice(value: 5, taxRate: 0.1, taxInclusive: true),
            reference: null,
          ),
          SailorCartMultipleAddon(
            id: 'addon2',
            price: SailorPrice(value: 5, taxRate: 0.1, taxInclusive: true),
            reference: null,
          ),
        ],
        reference: MyProduct(
          id: 'product',
          price: 10,
          taxRate: 0.1,
          taxInclusive: true,
        ),
        referenceId: 'product',
      );

      expect(product1, isNot(equals(product2)));
    });

    test('addons list equality', () {
      const addon1 = SailorCartMultipleAddon(
        id: 'addon',
        price: SailorPrice(value: 5, taxRate: 0.1, taxInclusive: true),
        reference: null,
      );

      const addon2 = SailorCartMultipleAddon(
        id: 'addon',
        price: SailorPrice(value: 5, taxRate: 0.1, taxInclusive: true),
        reference: null,
      );

      final list = [addon1];
      final list2 = [addon2];

      expect(list, contains(addon2));
      expect(list, equals(list2));
    });

    test('addons list not equal', () {
      const addon1 = SailorCartMultipleAddon(
        id: 'addon',
        price: SailorPrice(value: 5, taxRate: 0.1, taxInclusive: true),
        reference: null,
      );

      const addon2 = SailorCartMultipleAddon(
        id: 'addon2',
        price: SailorPrice(value: 5, taxRate: 0.1, taxInclusive: true),
        reference: null,
      );

      final list = [addon1];
      final list2 = [addon2];

      expect(list, isNot(equals(list2)));
    });

    test('clear removes all products from the cart', () {
      bool notified = false;
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      cart.addListener(() => notified = true);
      cart.addProduct(product);
      cart.clear();

      expect(cart.isEmpty, isTrue);
      expect(notified, isTrue);
    });

    test(
        'getDraft returns null when a draft for the given product does not already exist',
        () {
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      final draft = cart.getDraft(product);

      expect(draft, isNull);
    });

    test(
        'getDraft returns an existing draft product when a draft for the given product already exists',
        () {
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      final draft1 = cart.getOrCreateDraft(product);
      final draft2 = cart.getDraft(product);

      expect(draft1, isNotNull);
      expect(draft2, isNotNull);
      expect(draft1, equals(draft2));
    });

    test(
        'getOrCreateDraft returns a draft product when a draft for the given product does not already exist',
        () {
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      final draft = cart.getOrCreateDraft(product);

      expect(draft, isNotNull);
      expect(draft.referenceId, product.id);
      expect(draft.price.value, 10);
      expect(draft.price.taxRate, 0.1);
      expect(draft.price.taxInclusive, isTrue);
      expect(draft.draft, isTrue);
    });

    test(
        'getOrCreateDraft returns an existing draft product when a draft for the given product already exists',
        () {
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      final draft1 = cart.getOrCreateDraft(product);
      final draft2 = cart.getOrCreateDraft(product);

      expect(draft1, isNotNull);
      expect(draft2, isNotNull);
      expect(draft1, equals(draft2));
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

    test('it increments a product in the cart', () {
      bool notified = false;
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      cart.addListener(() => notified = true);
      cart.addProduct(product);
      cart.addProduct(product);

      expect(cart.products.length, 1);
      expect(cart.products.first.quantity, 2);
      expect(notified, isTrue);
    });

    test(
        'it does not increment a product in the cart when addons are different and instead adds a new product',
        () {
      bool notified = false;
      final product1 =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      final product2 =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      final addon1 = MyAddon(
          id: 'addon1',
          price: 5,
          taxRate: 0.1,
          taxInclusive: true,
          type: 'multiple');
      cart.addListener(() => notified = true);
      cart.addAddon(product1, addon1);
      cart.promoteDraftProduct(product1);

      cart.addProduct(product2);

      expect(cart.products.length, 2);
      expect(cart.products.first.quantity, 1);
      expect(cart.products.last.quantity, 1);
      expect(notified, isTrue);
    });

    test('it decrements a product in the cart', () {
      bool notified = false;
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      cart.addListener(() => notified = true);
      final cartProduct = cart.addProduct(product);
      cart.addProduct(product);
      cart.removeProductById(cartProduct.id);

      expect(cart.products.length, 1);
      expect(cart.products.first.quantity, 1);
      expect(notified, isTrue);
    });

    test('it removes a product from the cart by id', () {
      bool notified = false;
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      cart.addListener(() => notified = true);
      final eartProduct = cart.addProduct(product);
      cart.removeProductById(eartProduct.id);

      expect(cart.isEmpty, isTrue);
      expect(cart.products.length, 0);
      expect(notified, isTrue);
    });

    test('getProductById returns the product with the given id', () {
      final product =
          MyProduct(id: 'product', price: 10, taxRate: 0.1, taxInclusive: true);
      final foundProduct = cart.addProduct(product);

      expect(foundProduct, isNotNull);
      expect(foundProduct.referenceId, product.id);
    });

    test('getProduct returns null when the product is not in the cart', () {
      final foundProduct = cart.getProductById('not-found');

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
      cart.addAddon(product, addon);
      cart.promoteDraftProduct(product);

      expect(cart.products.first.addons.length, 1);
      expect(cart.products.first.addons.first.price.value, 5);
      expect(cart.products.first.addons.first.price.taxRate, 0.1);
      expect(cart.products.first.addons.first.price.taxInclusive, isTrue);
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
      cart.addAddon(product, addon);
      cart.promoteDraftProduct(product);

      expect(cart.products.first.addons.length, 1);
      expect(cart.products.first.addons.first.price.value, 5);
      expect(cart.products.first.addons.first.price.taxRate, 0.1);
      expect(cart.products.first.addons.first.price.taxInclusive, isTrue);
      expect(notified, isTrue);
    });

    test(
        'it can select an addon of type multiple\'s quantity for an existing addon',
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
      cart.addAddon(product, addon);
      cart.promoteDraftProduct(product);

      expect(cart.products.first.addons.length, 1);
      expect(cart.products.first.addons.first.price.value, 5);
      expect(cart.products.first.addons.first.price.taxRate, 0.1);
      expect(cart.products.first.addons.first.price.taxInclusive, isTrue);
      expect(notified, isTrue);
    });

    test(
        'it can select and then deselect addon of type multiple\'s quantity for an existing addon',
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
      cart.addAddon(product, addon);
      cart.addAddon(product, addon);
      cart.promoteDraftProduct(product);

      expect(cart.products.first.addons.length, 0);
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
      cart.addAddon(product, addon1);
      cart.addAddon(product, addon2);
      cart.promoteDraftProduct(product);

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
      cart.addAddon(product, addon);
      cart.promoteDraftProduct(product);

      expect(cart.products.first.addons.length, 1);
      final cartAddon =
          cart.products.first.addons.first as SailorCartCounterAddon;
      expect(cartAddon.price.value, 5);
      expect(cartAddon.price.taxRate, 0.1);
      expect(cartAddon.price.taxInclusive, isTrue);
      expect(cartAddon.quantity, 1);
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
      cart.addAddon(product, addon);
      cart.addAddon(product, addon);
      cart.promoteDraftProduct(product);

      expect(cart.products.first.addons.length, 1);
      final cartAddon =
          cart.products.first.addons.first as SailorCartCounterAddon;
      expect(cartAddon.price.value, 5);
      expect(cartAddon.price.taxRate, 0.1);
      expect(cartAddon.price.taxInclusive, isTrue);
      expect(cartAddon.quantity, 2);
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
      cart.addAddon(product, addon);
      cart.addAddon(product, addon);
      cart.removeAddon(product, addon);
      cart.promoteDraftProduct(product);

      expect(cart.products.first.addons.length, 1);
      final cartAddon =
          cart.products.first.addons.first as SailorCartCounterAddon;
      expect(cartAddon.price.value, 5);
      expect(cartAddon.price.taxRate, 0.1);
      expect(cartAddon.price.taxInclusive, isTrue);
      expect(cartAddon.quantity, 1);
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

      final draft = cart.getDraft(product);
      expect(draft, isNotNull);
      expect(draft!.addons.length, 1);
      final draftAddon = draft.addons.first as SailorCartCounterAddon;
      expect(draftAddon.price.value, 5);
      expect(draftAddon.price.taxRate, 0.1);
      expect(draftAddon.price.taxInclusive, isTrue);
      expect(draftAddon.quantity, 1);
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
      expect(cart.products.first.referenceId, product.id);
      expect(cart.products.first.addons.length, 1);
      final cartAddon =
          cart.products.first.addons.first as SailorCartCounterAddon;
      expect(cartAddon.price.value, 5);
      expect(cartAddon.price.taxRate, 0.1);
      expect(cartAddon.price.taxInclusive, isTrue);
      expect(cartAddon.quantity, 1);
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

    // ignore: unused_local_variable
    const basericePercentage = SailorPrice(
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
      reference: null,
    );

    const addon2 = SailorCartMultipleAddon(
      id: 'addon_2',
      price: addonPriceInclusive,
      reference: null,
    );

    const addon3 = SailorCartMultipleAddon(
      id: 'addon_3',
      price: addonPricePercentage,
      reference: null,
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
      final product = SailorCartProduct(
        price: basePriceInclusive,
        addons: const [addon2, addon3],
        quantity: 2,
        reference: null,
        referenceId: 'foo',
      );

      const expectedTotal = ((220) + (55) + (30 + 3)) * 2;
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
      final product = SailorCartProduct(
        price: basePriceInclusive,
        addons: const [addon2],
        quantity: 1,
        reference: null,
        referenceId: 'foo',
      );

      const expectedTax = 20 + 5;
      expect(product.tax, closeTo(expectedTax, 0.0001));
    });

    test(
        'should calculate subtotal correctly with tax-exclusive price and addons',
        () {
      final product = SailorCartProduct(
        price: basePriceExclusive,
        addons: const [addon1, addon3],
        quantity: 1,
        reference: null,
        referenceId: 'foo',
      );

      const expectedSubtotal = 200 + 50 + 30;
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
      final product1 = SailorCartProduct(
        price: basePriceExclusive,
        addons: const [addon1, addon2],
        quantity: 1,
        reference: null,
        referenceId: 'foo',
      );

      final product2 = SailorCartProduct(
        price: basePriceExclusive,
        addons: const [addon1, addon2],
        quantity: 1,
        reference: null,
        referenceId: 'foo',
      );

      expect(product1.copyWith(id: product2.id), equals(product2));
    });

    test('should return false for different product objects', () {
      final product1 = SailorCartProduct(
        price: basePriceExclusive,
        addons: const [addon1],
        quantity: 1,
        reference: null,
        referenceId: 'foo',
      );

      final product2 = SailorCartProduct(
        price: basePriceExclusive,
        addons: const [addon1],
        quantity: 1,
        reference: null,
        referenceId: 'bar',
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
        reference: null,
      );

      expect(addon.total, 110.0); // (100 + 10
    });

    test('should calculate total correctly when tax is inclusive', () {
      const addon = SailorCartMultipleAddon(
        id: 'addon_2',
        price: priceInclusive,
        reference: null,
      );

      expect(addon.total, 110.0); // 110
    });

    test('should calculate total correctly with percentage tax', () {
      const addon = SailorCartMultipleAddon(
        id: 'addon_3',
        price: pricePercentage,
        reference: null,
      );

      expect(addon.total, 110.0); // 100 + (100 * 10%) = 110
    });

    test('should calculate tax correctly when tax is exclusive', () {
      const addon = SailorCartMultipleAddon(
        id: 'addon_4',
        price: priceExclusive,
        reference: null,
      );

      expect(addon.tax, 10.0); // 10
    });

    test('should calculate tax correctly when tax is inclusive', () {
      const addon = SailorCartMultipleAddon(
        id: 'addon_5',
        price: priceInclusive,
        reference: null,
      );

      expect(addon.tax,
          closeTo(10, 0.0001)); // 110 includes tax, so extracted tax is 10
    });

    test('should calculate tax correctly with percentage tax', () {
      const addon = SailorCartMultipleAddon(
        id: 'addon_6',
        price: pricePercentage,
        reference: null,
      );

      expect(addon.tax, 10.0);
    });

    test('should calculate subtotal correctly when tax is exclusive', () {
      const addon = SailorCartMultipleAddon(
        id: 'addon_7',
        price: priceExclusive,
        reference: null,
      );

      expect(addon.subtotal, 100.0); // 100
    });

    test('should calculate subtotal correctly when tax is inclusive', () {
      const addon = SailorCartMultipleAddon(
        id: 'addon_8',
        price: priceInclusive,
        reference: null,
      );

      expect(addon.subtotal,
          closeTo(100.0, 0.0001)); // Allowing a small margin of error
    });

    test('should calculate subtotal correctly with percentage tax', () {
      const addon = SailorCartMultipleAddon(
        id: 'addon_9',
        price: pricePercentage,
        reference: null,
      );

      expect(addon.subtotal, 100.0); // 100
    });

    test('should override equality correctly', () {
      const addon1 = SailorCartMultipleAddon(
        id: 'addon_10',
        price: priceExclusive,
        reference: null,
      );

      const addon2 = SailorCartMultipleAddon(
        id: 'addon_10',
        price: priceExclusive,
        reference: null,
      );

      expect(addon1, equals(addon2));
    });

    test('should return false for different addon objects', () {
      const addon1 = SailorCartMultipleAddon(
        id: 'addon_11',
        price: priceExclusive,
        reference: null,
      );

      const addon2 = SailorCartMultipleAddon(
        id: 'addon_12',
        price: priceExclusive,
        reference: null,
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
