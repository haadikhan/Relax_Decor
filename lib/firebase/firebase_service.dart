import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FurnitureItem {
  final String id;
  final String category;
  final String model;
  final int stock;
  final double price;
  final String? design;
  final String? color;
  final String? size;

  FurnitureItem({
    required this.id,
    required this.category,
    required this.model,
    required this.stock,
    required this.price,
    this.design,
    this.color,
    this.size,
  });

  factory FurnitureItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FurnitureItem(
      id: doc.id,
      category: data['category'] as String,
      model: data['model'] as String,
      stock: (data['stock'] as num).toInt(),
      price: (data['price'] as num).toDouble(),
      design: data['design'] as String?,
      color: data['color'] as String?,
      size: data['size'] as String?,
    );
  }
}

/// Service class to handle all interactions with Firestore.
class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _appId;

  // **CRITICAL FIX: Pass the App ID for correct Firestore Pathing**
  FirebaseService({required String appId}) : _appId = appId;

  // Getter to construct the correct collection reference for PUBLIC, SHARED data
  CollectionReference<Map<String, dynamic>> get _inventoryCollectionRef {
    // This path adheres to the Firebase Security Rules for shared/public data in the Canvas environment:
    // /artifacts/{appId}/public/data/inventory_items
    return _db
        .collection('artifacts')
        .doc(_appId)
        .collection('public')
        .doc('data')
        .collection('inventory_items');
  }

  // Mock inventory data to seed the database if it is empty.
  final List<Map<String, dynamic>> _mockInventoryData = [
    // Beds (Category: Bed)
    {
      'category': 'Bed',
      'model': 'Cloud Dreamer',
      'stock': 45,
      'price': 1200.00,
      'design': 'Platform',
      'color': 'Gray',
      'size': 'Queen',
    },
    {
      'category': 'Bed',
      'model': 'Urban Slumber',
      'stock': 15,
      'price': 950.00,
      'design': 'Storage',
      'color': 'White',
      'size': 'King',
    },
    {
      'category': 'Bed',
      'model': 'Rustic Retreat',
      'stock': 5,
      'price': 1500.00,
      'design': 'Four Poster',
      'color': 'Oak',
      'size': 'Full',
    },
    {
      'category': 'Bed',
      'model': 'Minimalist Frame',
      'stock': 0,
      'price': 700.00,
      'design': 'Platform',
      'color': 'Black',
      'size': 'Twin',
    }, // Zero quantity test
    // Sofas (Category: Sofa)
    {
      'category': 'Sofa',
      'model': 'Sectional Comfort',
      'stock': 35,
      'price': 2500.00,
      'design': 'L-Shape',
      'color': 'Navy Blue',
      'size': 'Large',
    },
    {
      'category': 'Sofa',
      'model': 'Loveseat Lounge',
      'stock': 20,
      'price': 1100.00,
      'design': 'Straight',
      'color': 'Beige',
      'size': 'Medium',
    },
    {
      'category': 'Sofa',
      'model': 'Velvet Chaise',
      'stock': 10,
      'price': 1800.00,
      'design': 'Recliner',
      'color': 'Emerald Green',
      'size': 'Small',
    },
    {
      'category': 'Sofa',
      'model': 'Modular Duo',
      'stock': 0,
      'price': 3000.00,
      'design': 'Modular',
      'color': 'Light Gray',
      'size': 'Extra Large',
    }, // Zero quantity test
    // Dining Table (Category: Dining Table)
    {
      'category': 'Dining Table',
      'model': 'Modern Oval',
      'stock': 25,
      'price': 800.00,
      'design': 'Glass Top',
      'color': 'Clear',
      'size': '6-Seater',
    },
    {
      'category': 'Dining Table',
      'model': 'Farmhouse Wood',
      'stock': 50,
      'price': 1500.00,
      'design': 'Solid Wood',
      'color': 'Brown',
      'size': '8-Seater',
    },
    {
      'category': 'Dining Table',
      'model': 'Compact Circle',
      'stock': 12,
      'price': 450.00,
      'design': 'Pedestal',
      'color': 'White',
      'size': '4-Seater',
    },

    // TV Table (Category: TV Table)
    {
      'category': 'TV Table',
      'model': 'Industrial Media',
      'stock': 40,
      'price': 350.00,
      'design': 'Metal Frame',
      'color': 'Black',
      'size': '70 inch',
    },
    {
      'category': 'TV Table',
      'model': 'Floating Console',
      'stock': 22,
      'price': 250.00,
      'design': 'Wall Mount',
      'color': 'White',
      'size': '55 inch',
    },
    {
      'category': 'TV Table',
      'model': 'Classic Stand',
      'stock': 8,
      'price': 400.00,
      'design': 'Cabinet',
      'color': 'Cherry',
      'size': '65 inch',
    },

    // Wardrobe (Category: Wardrobe)
    {
      'category': 'Wardrobe',
      'model': 'Sliding Door 3M',
      'stock': 18,
      'price': 900.00,
      'design': 'Sliding',
      'color': 'Mirror',
      'size': 'Triple',
    },
    {
      'category': 'Wardrobe',
      'model': 'Hinged Door 2M',
      'stock': 40,
      'price': 750.00,
      'design': 'Hinged',
      'color': 'Light Oak',
      'size': 'Double',
    },
    {
      'category': 'Wardrobe',
      'model': 'Corner Storage',
      'stock': 6,
      'price': 600.00,
      'design': 'Corner Unit',
      'color': 'Pine',
      'size': 'Single',
    },
  ];

  /// Checks if the inventory collection is empty and seeds it with mock data if necessary.
  Future<void> seedInventoryIfEmpty() async {
    try {
      // Use the correct collection reference
      final snapshot = await _inventoryCollectionRef.limit(1).get();
      if (snapshot.docs.isEmpty) {
        debugPrint('Inventory collection is empty. Seeding with mock data...');
        final batch = _db.batch();
        for (var itemData in _mockInventoryData) {
          final docRef = _inventoryCollectionRef
              .doc(); // Use the correct ref for new doc
          batch.set(docRef, itemData);
        }
        await batch.commit();
        debugPrint('Seeding complete.');
      }
    } catch (e) {
      // This is where the permission error was being caught earlier
      debugPrint('Error seeding inventory: $e');
      rethrow; // Re-throw the error so the caller knows the operation failed
    }
  }

  /// Streams inventory filtered by category and optional attributes (design, color, size).
  Stream<List<FurnitureItem>> streamInventory(
    String categoryName, {
    String? design,
    String? color,
    String? size,
  }) {
    // Use the correct collection reference
    Query query = _inventoryCollectionRef.where(
      'category',
      isEqualTo: categoryName,
    );

    // Apply filters if they are selected and not the default "All" option
    if (design != null && !design.startsWith('All ')) {
      query = query.where('design', isEqualTo: design);
    }
    if (color != null && !color.startsWith('All ')) {
      query = query.where('color', isEqualTo: color);
    }
    if (size != null && !size.startsWith('All ')) {
      query = query.where('size', isEqualTo: size);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => FurnitureItem.fromFirestore(doc)).toList(),
    );
  }

  /// Fetches distinct filter values (Design, Color, Size) for a given category.
  Stream<List<String>> streamDistinctValues(
    String categoryName,
    String fieldName,
  ) {
    // Use the correct collection reference
    return _inventoryCollectionRef
        .where('category', isEqualTo: categoryName)
        .snapshots()
        .map((snapshot) {
          // FIX for list_element_type_not_assignable:
          // 1. Filter out nulls/empty strings.
          // 2. Use .map((value) => value!) to assert the remaining elements are non-nullable String.
          final List<String> values = snapshot.docs
              .map((doc) => doc.data()[fieldName] as String?)
              .where((value) => value != null && value!.isNotEmpty)
              .map((value) => value!)
              .toSet()
              .toList();

          final defaultName =
              'All ${fieldName[0].toUpperCase()}${fieldName.substring(1)}s';
          values.sort();
          return [defaultName, ...values];
        });
  }

  Future<void> sellItem(String itemId) async {
    final itemRef = _inventoryCollectionRef.doc(itemId); // Use the correct ref
    // Note: Exceptions thrown inside runTransaction (like our 'Item is out of stock!')
    // are often wrapped by the Dart SDK, which is handled in the caller's catch block.
    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(itemRef);
      if (!doc.exists) throw Exception('Item not found');
      // The Firestore document uses int for stock, so it's safe to cast the number to int
      final currentStock = (doc.data() as Map<String, dynamic>)['stock'] as int;
      if (currentStock > 0) {
        transaction.update(itemRef, {'stock': currentStock - 1});
      } else {
        // Custom error for out of stock
        throw Exception('Item is out of stock!');
      }
    });
  }

  Future<void> updateStock(String itemId, int newQuantity) async {
    if (newQuantity < 0) throw Exception('Stock quantity cannot be negative.');
    final itemRef = _inventoryCollectionRef.doc(itemId); // Use the correct ref
    await itemRef.update({'stock': newQuantity});
  }

  Future<void> increaseStock(String itemId, int increaseAmount) async {
    if (increaseAmount <= 0)
      // ignore: curly_braces_in_flow_control_structures
      throw Exception('Increase amount must be positive.');
    final itemRef = _inventoryCollectionRef.doc(itemId); // Use the correct ref
    await itemRef.update({'stock': FieldValue.increment(increaseAmount)});
  }

  Stream<int> streamTotalStock(String categoryName) {
    // Use the correct collection reference
    return _inventoryCollectionRef
        .where('category', isEqualTo: categoryName)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.fold(0, (sum, doc) {
            return sum + (doc.data()['stock'] as num).toInt();
          }),
        );
  }
}
