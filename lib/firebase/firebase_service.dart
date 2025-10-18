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

  FirebaseService({required String appId}) : _appId = appId;

  CollectionReference<Map<String, dynamic>> get _inventoryCollectionRef {
    return _db
        .collection('artifacts')
        .doc(_appId)
        .collection('public')
        .doc('data')
        .collection('inventory_items');
  }

  // REAL RELAX DECOR INVENTORY DATA
  final List<Map<String, dynamic>> _realInventoryData = [
    // ========== SOFAS ==========
    // Carol Sofa 3 Seater
    {
      'category': 'Sofa',
      'model': 'Carol Sofa 3 Seater',
      'design': 'Carol',
      'size': '188x92x90cm',
      'color': 'Black & Red Contros',
      'price': 600.0,
      'stock': 10,
    },
    {
      'category': 'Sofa',
      'model': 'Carol Sofa 3 Seater',
      'design': 'Carol',
      'size': '188x92x90cm',
      'color': 'Black & White Contros',
      'price': 600.0,
      'stock': 8,
    },
    {
      'category': 'Sofa',
      'model': 'Carol Sofa 3 Seater',
      'design': 'Carol',
      'size': '188x92x90cm',
      'color': 'Grey & White Contros',
      'price': 600.0,
      'stock': 12,
    },

    // Carol Sofa 2 Seater
    {
      'category': 'Sofa',
      'model': 'Carol Sofa 2 Seater',
      'design': 'Carol',
      'size': '156x92x90cm',
      'color': 'Black & Red Contros',
      'price': 600.0,
      'stock': 7,
    },
    {
      'category': 'Sofa',
      'model': 'Carol Sofa 2 Seater',
      'design': 'Carol',
      'size': '156x92x90cm',
      'color': 'Black & White Contros',
      'price': 600.0,
      'stock': 9,
    },
    {
      'category': 'Sofa',
      'model': 'Carol Sofa 2 Seater',
      'design': 'Carol',
      'size': '156x92x90cm',
      'color': 'Grey & White Contros',
      'price': 600.0,
      'stock': 11,
    },

    // Carol Corner Sofa
    {
      'category': 'Sofa',
      'model': 'Carol Corner Sofa',
      'design': 'Carol Corner',
      'size': '210x210cm',
      'color': 'Black & Red Contros',
      'price': 650.0,
      'stock': 6,
    },
    {
      'category': 'Sofa',
      'model': 'Carol Corner Sofa',
      'design': 'Carol Corner',
      'size': '210x210cm',
      'color': 'Black & White Contros',
      'price': 650.0,
      'stock': 5,
    },
    {
      'category': 'Sofa',
      'model': 'Carol Corner Sofa',
      'design': 'Carol Corner',
      'size': '210x210cm',
      'color': 'Grey & White Contros',
      'price': 650.0,
      'stock': 8,
    },

    // Anton Sofa (Sofa+Bed+Storage)
    {
      'category': 'Sofa',
      'model': 'Anton Sofa',
      'design': 'Anton',
      'size': '275x202cm',
      'color': 'Cream',
      'price': 720.0,
      'stock': 4,
    },
    {
      'category': 'Sofa',
      'model': 'Anton Sofa',
      'design': 'Anton',
      'size': '275x202cm',
      'color': 'Grey',
      'price': 720.0,
      'stock': 6,
    },

    // Bostan 3 Seater (Sofa+Bed+Storage)
    {
      'category': 'Sofa',
      'model': 'Bostan 3 Seater',
      'design': 'Bostan',
      'size': '245x150cm',
      'color': 'Grey',
      'price': 450.0,
      'stock': 15,
    },
    {
      'category': 'Sofa',
      'model': 'Bostan 3 Seater',
      'design': 'Bostan',
      'size': '245x150cm',
      'color': 'Black',
      'price': 450.0,
      'stock': 12,
    },
    {
      'category': 'Sofa',
      'model': 'Bostan 3 Seater',
      'design': 'Bostan',
      'size': '245x150cm',
      'color': 'Cream',
      'price': 450.0,
      'stock': 10,
    },

    // Artic Sofa (Sofa+Bed+Storage)
    {
      'category': 'Sofa',
      'model': 'Artic Sofa',
      'design': 'Artic',
      'size': '265x230cm',
      'color': 'Dark Grey',
      'price': 700.0,
      'stock': 8,
    },
    {
      'category': 'Sofa',
      'model': 'Artic Sofa',
      'design': 'Artic',
      'size': '265x230cm',
      'color': 'Light Grey',
      'price': 700.0,
      'stock': 7,
    },
    {
      'category': 'Sofa',
      'model': 'Artic Sofa',
      'design': 'Artic',
      'size': '265x230cm',
      'color': 'Black',
      'price': 700.0,
      'stock': 9,
    },
    {
      'category': 'Sofa',
      'model': 'Artic Sofa',
      'design': 'Artic',
      'size': '265x230cm',
      'color': 'Cream',
      'price': 700.0,
      'stock': 6,
    },

    // Relax Sofa (Sofa+Bed+Storage)
    {
      'category': 'Sofa',
      'model': 'Relax Sofa',
      'design': 'Relax',
      'size': '250x150cm',
      'color': 'Light Grey',
      'price': 440.0,
      'stock': 14,
    },
    {
      'category': 'Sofa',
      'model': 'Relax Sofa',
      'design': 'Relax',
      'size': '250x150cm',
      'color': 'Dark Grey',
      'price': 440.0,
      'stock': 11,
    },
    {
      'category': 'Sofa',
      'model': 'Relax Sofa',
      'design': 'Relax',
      'size': '250x150cm',
      'color': 'Black',
      'price': 440.0,
      'stock': 13,
    },
    {
      'category': 'Sofa',
      'model': 'Relax Sofa',
      'design': 'Relax',
      'size': '250x150cm',
      'color': 'Cream',
      'price': 440.0,
      'stock': 10,
    },

    // Antario Sofa (Sofa+Bed+Storage)
    {
      'category': 'Sofa',
      'model': 'Antario Sofa',
      'design': 'Antario',
      'size': '296x200cm',
      'color': 'Grey',
      'price': 630.0,
      'stock': 7,
    },
    {
      'category': 'Sofa',
      'model': 'Antario Sofa',
      'design': 'Antario',
      'size': '296x200cm',
      'color': 'Black',
      'price': 630.0,
      'stock': 8,
    },
    {
      'category': 'Sofa',
      'model': 'Antario Sofa',
      'design': 'Antario',
      'size': '296x200cm',
      'color': 'Black with White Contros',
      'price': 630.0,
      'stock': 5,
    },

    // Handerson Sofa - With Bed Function
    {
      'category': 'Sofa',
      'model': 'Handerson (with Bed)',
      'design': 'Handerson',
      'size': '317x253cm',
      'color': 'Grey',
      'price': 820.0,
      'stock': 4,
    },
    {
      'category': 'Sofa',
      'model': 'Handerson (with Bed)',
      'design': 'Handerson',
      'size': '317x253cm',
      'color': 'Black',
      'price': 820.0,
      'stock': 3,
    },

    // Handerson Sofa - Without Bed Function
    {
      'category': 'Sofa',
      'model': 'Handerson (no Bed)',
      'design': 'Handerson',
      'size': '317x253cm',
      'color': 'Grey',
      'price': 700.0,
      'stock': 6,
    },
    {
      'category': 'Sofa',
      'model': 'Handerson (no Bed)',
      'design': 'Handerson',
      'size': '317x253cm',
      'color': 'Black',
      'price': 700.0,
      'stock': 5,
    },

    // Enzo Sofa
    {
      'category': 'Sofa',
      'model': 'Enzo Sofa',
      'design': 'Enzo',
      'size': '270x165cm',
      'color': 'Grey',
      'price': 700.0,
      'stock': 8,
    },
    {
      'category': 'Sofa',
      'model': 'Enzo Sofa',
      'design': 'Enzo',
      'size': '270x165cm',
      'color': 'Black',
      'price': 700.0,
      'stock': 7,
    },

    // Loca Sofa
    {
      'category': 'Sofa',
      'model': 'Loca Sofa',
      'design': 'Loca',
      'size': '265x165cm',
      'color': 'Grey',
      'price': 680.0,
      'stock': 9,
    },
    {
      'category': 'Sofa',
      'model': 'Loca Sofa',
      'design': 'Loca',
      'size': '265x165cm',
      'color': 'Cream',
      'price': 680.0,
      'stock': 6,
    },

    // Ibiza Sofa
    {
      'category': 'Sofa',
      'model': 'Ibiza Sofa',
      'design': 'Ibiza',
      'size': '312x223cm',
      'color': 'Grey',
      'price': 810.0,
      'stock': 5,
    },
    {
      'category': 'Sofa',
      'model': 'Ibiza Sofa',
      'design': 'Ibiza',
      'size': '312x223cm',
      'color': 'Cream',
      'price': 810.0,
      'stock': 4,
    },

    // ========== BEDS (Sample - replace with your real data) ==========
    {
      'category': 'Bed',
      'model': 'Cloud Dreamer',
      'design': 'Platform',
      'size': 'Queen',
      'color': 'Gray',
      'price': 1200.0,
      'stock': 15,
    },
    {
      'category': 'Bed',
      'model': 'Urban Slumber',
      'design': 'Storage',
      'size': 'King',
      'color': 'White',
      'price': 950.0,
      'stock': 8,
    },
    {
      'category': 'Bed',
      'model': 'Rustic Retreat',
      'design': 'Four Poster',
      'size': 'Full',
      'color': 'Oak',
      'price': 1500.0,
      'stock': 5,
    },

    // ========== DINING TABLES (Sample - replace with your real data) ==========
    {
      'category': 'Dining Table',
      'model': 'Modern Oval',
      'design': 'Glass Top',
      'size': '6-Seater',
      'color': 'Clear',
      'price': 800.0,
      'stock': 12,
    },
    {
      'category': 'Dining Table',
      'model': 'Farmhouse Wood',
      'design': 'Solid Wood',
      'size': '8-Seater',
      'color': 'Brown',
      'price': 1500.0,
      'stock': 20,
    },
    {
      'category': 'Dining Table',
      'model': 'Compact Circle',
      'design': 'Pedestal',
      'size': '4-Seater',
      'color': 'White',
      'price': 450.0,
      'stock': 18,
    },

    // ========== TV TABLES (Sample - replace with your real data) ==========
    {
      'category': 'TV Table',
      'model': 'Industrial Media',
      'design': 'Metal Frame',
      'size': '70 inch',
      'color': 'Black',
      'price': 350.0,
      'stock': 25,
    },
    {
      'category': 'TV Table',
      'model': 'Floating Console',
      'design': 'Wall Mount',
      'size': '55 inch',
      'color': 'White',
      'price': 250.0,
      'stock': 15,
    },
    {
      'category': 'TV Table',
      'model': 'Classic Stand',
      'design': 'Cabinet',
      'size': '65 inch',
      'color': 'Cherry',
      'price': 400.0,
      'stock': 10,
    },

    // ========== WARDROBES - RELAX DECOR ==========
    // Side Mirror - White Color (4 sizes)
    {
      'category': 'Wardrobe',
      'model': 'Side Mirror Wardrobe',
      'design': 'Side Mirror',
      'size': '120x200x58cm',
      'color': 'White',
      'price': 650.0,
      'stock': 8,
    },
    {
      'category': 'Wardrobe',
      'model': 'Side Mirror Wardrobe',
      'design': 'Side Mirror',
      'size': '150x200x58cm',
      'color': 'White',
      'price': 750.0,
      'stock': 10,
    },
    {
      'category': 'Wardrobe',
      'model': 'Side Mirror Wardrobe',
      'design': 'Side Mirror',
      'size': '180x215x58cm',
      'color': 'White',
      'price': 850.0,
      'stock': 12,
    },
    {
      'category': 'Wardrobe',
      'model': 'Side Mirror Wardrobe',
      'design': 'Side Mirror',
      'size': '200x215x58cm',
      'color': 'White',
      'price': 950.0,
      'stock': 9,
    },

    // Side Mirror - Black Color (4 sizes)
    {
      'category': 'Wardrobe',
      'model': 'Side Mirror Wardrobe',
      'design': 'Side Mirror',
      'size': '120x200x58cm',
      'color': 'Black',
      'price': 650.0,
      'stock': 7,
    },
    {
      'category': 'Wardrobe',
      'model': 'Side Mirror Wardrobe',
      'design': 'Side Mirror',
      'size': '150x200x58cm',
      'color': 'Black',
      'price': 750.0,
      'stock': 9,
    },
    {
      'category': 'Wardrobe',
      'model': 'Side Mirror Wardrobe',
      'design': 'Side Mirror',
      'size': '180x215x58cm',
      'color': 'Black',
      'price': 850.0,
      'stock': 11,
    },
    {
      'category': 'Wardrobe',
      'model': 'Side Mirror Wardrobe',
      'design': 'Side Mirror',
      'size': '200x215x58cm',
      'color': 'Black',
      'price': 950.0,
      'stock': 8,
    },

    // Side Mirror - Grey Color (4 sizes)
    {
      'category': 'Wardrobe',
      'model': 'Side Mirror Wardrobe',
      'design': 'Side Mirror',
      'size': '120x200x58cm',
      'color': 'Grey',
      'price': 650.0,
      'stock': 6,
    },
    {
      'category': 'Wardrobe',
      'model': 'Side Mirror Wardrobe',
      'design': 'Side Mirror',
      'size': '150x200x58cm',
      'color': 'Grey',
      'price': 750.0,
      'stock': 8,
    },
    {
      'category': 'Wardrobe',
      'model': 'Side Mirror Wardrobe',
      'design': 'Side Mirror',
      'size': '180x215x58cm',
      'color': 'Grey',
      'price': 850.0,
      'stock': 10,
    },
    {
      'category': 'Wardrobe',
      'model': 'Side Mirror Wardrobe',
      'design': 'Side Mirror',
      'size': '200x215x58cm',
      'color': 'Grey',
      'price': 950.0,
      'stock': 7,
    },

    // Center Mirror - Black Color (4 sizes)
    {
      'category': 'Wardrobe',
      'model': 'Center Mirror Wardrobe',
      'design': 'Center Mirror',
      'size': '120x200x58cm',
      'color': 'Black',
      'price': 680.0,
      'stock': 9,
    },
    {
      'category': 'Wardrobe',
      'model': 'Center Mirror Wardrobe',
      'design': 'Center Mirror',
      'size': '150x200x58cm',
      'color': 'Black',
      'price': 780.0,
      'stock': 11,
    },
    {
      'category': 'Wardrobe',
      'model': 'Center Mirror Wardrobe',
      'design': 'Center Mirror',
      'size': '180x215x58cm',
      'color': 'Black',
      'price': 880.0,
      'stock': 13,
    },
    {
      'category': 'Wardrobe',
      'model': 'Center Mirror Wardrobe',
      'design': 'Center Mirror',
      'size': '200x215x58cm',
      'color': 'Black',
      'price': 980.0,
      'stock': 10,
    },

    // Center Mirror - White Color (4 sizes)
    {
      'category': 'Wardrobe',
      'model': 'Center Mirror Wardrobe',
      'design': 'Center Mirror',
      'size': '120x200x58cm',
      'color': 'White',
      'price': 680.0,
      'stock': 8,
    },
    {
      'category': 'Wardrobe',
      'model': 'Center Mirror Wardrobe',
      'design': 'Center Mirror',
      'size': '150x200x58cm',
      'color': 'White',
      'price': 780.0,
      'stock': 10,
    },
    {
      'category': 'Wardrobe',
      'model': 'Center Mirror Wardrobe',
      'design': 'Center Mirror',
      'size': '180x215x58cm',
      'color': 'White',
      'price': 880.0,
      'stock': 12,
    },
    {
      'category': 'Wardrobe',
      'model': 'Center Mirror Wardrobe',
      'design': 'Center Mirror',
      'size': '200x215x58cm',
      'color': 'White',
      'price': 980.0,
      'stock': 9,
    },

    // Center Mirror - Grey Color (4 sizes)
    {
      'category': 'Wardrobe',
      'model': 'Center Mirror Wardrobe',
      'design': 'Center Mirror',
      'size': '120x200x58cm',
      'color': 'Grey',
      'price': 680.0,
      'stock': 7,
    },
    {
      'category': 'Wardrobe',
      'model': 'Center Mirror Wardrobe',
      'design': 'Center Mirror',
      'size': '150x200x58cm',
      'color': 'Grey',
      'price': 780.0,
      'stock': 9,
    },
    {
      'category': 'Wardrobe',
      'model': 'Center Mirror Wardrobe',
      'design': 'Center Mirror',
      'size': '180x215x58cm',
      'color': 'Grey',
      'price': 880.0,
      'stock': 11,
    },
    {
      'category': 'Wardrobe',
      'model': 'Center Mirror Wardrobe',
      'design': 'Center Mirror',
      'size': '200x215x58cm',
      'color': 'Grey',
      'price': 980.0,
      'stock': 8,
    },

    // Internal Side - White Color (4 sizes)
    {
      'category': 'Wardrobe',
      'model': 'Internal Side Wardrobe',
      'design': 'Internal Side',
      'size': '120x200x58cm',
      'color': 'White',
      'price': 620.0,
      'stock': 10,
    },
    {
      'category': 'Wardrobe',
      'model': 'Internal Side Wardrobe',
      'design': 'Internal Side',
      'size': '150x200x58cm',
      'color': 'White',
      'price': 720.0,
      'stock': 12,
    },
    {
      'category': 'Wardrobe',
      'model': 'Internal Side Wardrobe',
      'design': 'Internal Side',
      'size': '180x215x58cm',
      'color': 'White',
      'price': 820.0,
      'stock': 14,
    },
    {
      'category': 'Wardrobe',
      'model': 'Internal Side Wardrobe',
      'design': 'Internal Side',
      'size': '200x215x58cm',
      'color': 'White',
      'price': 920.0,
      'stock': 11,
    },
  ];

  /// Checks if the inventory collection is empty and seeds it with REAL RELAX DECOR data if necessary.
  Future<void> seedInventoryIfEmpty() async {
    try {
      final snapshot = await _inventoryCollectionRef.limit(1).get();
      if (snapshot.docs.isEmpty) {
        debugPrint('🔄 Inventory empty. Seeding RELAX DECOR data...');
        final batch = _db.batch();
        for (var itemData in _realInventoryData) {
          final docRef = _inventoryCollectionRef.doc();
          batch.set(docRef, itemData);
        }
        await batch.commit();
        debugPrint(
          '✅ Seeded ${_realInventoryData.length} items (35 Sofas + samples for other categories)',
        );
      } else {
        debugPrint('✓ Inventory already contains data. Skipping seed.');
      }
    } catch (e) {
      debugPrint('❌ Error seeding inventory: $e');
      rethrow;
    }
  }

  /// Streams inventory filtered by category and optional attributes (design, color, size).
  Stream<List<FurnitureItem>> streamInventory(
    String categoryName, {
    String? design,
    String? color,
    String? size,
  }) {
    Query query = _inventoryCollectionRef.where(
      'category',
      isEqualTo: categoryName,
    );

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
    return _inventoryCollectionRef
        .where('category', isEqualTo: categoryName)
        .snapshots()
        .map((snapshot) {
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
    final itemRef = _inventoryCollectionRef.doc(itemId);
    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(itemRef);
      if (!doc.exists) throw Exception('Item not found');
      final currentStock = (doc.data() as Map<String, dynamic>)['stock'] as int;
      if (currentStock > 0) {
        transaction.update(itemRef, {'stock': currentStock - 1});
      } else {
        throw Exception('Item is out of stock!');
      }
    });
  }

  Future<void> updateStock(String itemId, int newQuantity) async {
    if (newQuantity < 0) throw Exception('Stock quantity cannot be negative.');
    final itemRef = _inventoryCollectionRef.doc(itemId);
    await itemRef.update({'stock': newQuantity});
  }

  Future<void> increaseStock(String itemId, int increaseAmount) async {
    if (increaseAmount <= 0)
      throw Exception('Increase amount must be positive.');
    final itemRef = _inventoryCollectionRef.doc(itemId);
    await itemRef.update({'stock': FieldValue.increment(increaseAmount)});
  }

  Stream<int> streamTotalStock(String categoryName) {
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
