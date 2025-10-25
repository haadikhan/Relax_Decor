import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final String? lastUpdatedBy; // NEW: Track who updated
  final DateTime? lastUpdatedAt; // NEW: Track when updated

  FurnitureItem({
    required this.id,
    required this.category,
    required this.model,
    required this.stock,
    required this.price,
    this.design,
    this.color,
    this.size,
    this.lastUpdatedBy, // NEW
    this.lastUpdatedAt, // NEW
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
      lastUpdatedBy: data['lastUpdatedBy'] as String?, // NEW
      lastUpdatedAt:
          data['lastUpdatedAt'] !=
              null // NEW
          ? (data['lastUpdatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}

// NEW: Stock Update Record Model
class StockUpdateRecord {
  final String id;
  final String itemId;
  final String category;
  final String model;
  final String updatedBy;
  final DateTime updatedAt;
  final int previousStock;
  final int newStock;
  final int changeAmount;
  final String updateType; // 'set' or 'increase'
  final String? design;
  final String? color;
  final String? size;

  StockUpdateRecord({
    required this.id,
    required this.itemId,
    required this.category,
    required this.model,
    required this.updatedBy,
    required this.updatedAt,
    required this.previousStock,
    required this.newStock,
    required this.changeAmount,
    required this.updateType,
    this.design,
    this.color,
    this.size,
  });

  factory StockUpdateRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockUpdateRecord(
      id: doc.id,
      itemId: data['itemId'] as String,
      category: data['category'] as String,
      model: data['model'] as String,
      updatedBy: data['updatedBy'] as String,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      previousStock: (data['previousStock'] as num).toInt(),
      newStock: (data['newStock'] as num).toInt(),
      changeAmount: (data['changeAmount'] as num).toInt(),
      updateType: data['updateType'] as String,
      design: data['design'] as String?,
      color: data['color'] as String?,
      size: data['size'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'itemId': itemId,
      'category': category,
      'model': model,
      'updatedBy': updatedBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'previousStock': previousStock,
      'newStock': newStock,
      'changeAmount': changeAmount,
      'updateType': updateType,
      'design': design,
      'color': color,
      'size': size,
    };
  }
}

// Sales Record Model
class SalesRecord {
  final String id;
  final String itemId;
  final String category;
  final String model;
  final double price;
  final int quantity;
  final double totalAmount;
  final DateTime saleDate;
  final String? design;
  final String? color;
  final String? size;

  SalesRecord({
    required this.id,
    required this.itemId,
    required this.category,
    required this.model,
    required this.price,
    required this.quantity,
    required this.totalAmount,
    required this.saleDate,
    this.design,
    this.color,
    this.size,
  });

  factory SalesRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SalesRecord(
      id: doc.id,
      itemId: data['itemId'] as String,
      category: data['category'] as String,
      model: data['model'] as String,
      price: (data['price'] as num).toDouble(),
      quantity: (data['quantity'] as num).toInt(),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      saleDate: (data['saleDate'] as Timestamp).toDate(),
      design: data['design'] as String?,
      color: data['color'] as String?,
      size: data['size'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'itemId': itemId,
      'category': category,
      'model': model,
      'price': price,
      'quantity': quantity,
      'totalAmount': totalAmount,
      'saleDate': Timestamp.fromDate(saleDate),
      'design': design,
      'color': color,
      'size': size,
    };
  }
}

// Monthly Sales Summary Model
class MonthlySalesSummary {
  final String category;
  final int totalItemsSold;
  final double totalRevenue;
  final int year;
  final int month;

  MonthlySalesSummary({
    required this.category,
    required this.totalItemsSold,
    required this.totalRevenue,
    required this.year,
    required this.month,
  });
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

  // Sales collection reference
  CollectionReference<Map<String, dynamic>> get _salesCollectionRef {
    return _db
        .collection('artifacts')
        .doc(_appId)
        .collection('public')
        .doc('data')
        .collection('sales_records');
  }

  // NEW: Stock updates collection reference
  CollectionReference<Map<String, dynamic>> get _stockUpdatesCollectionRef {
    return _db
        .collection('artifacts')
        .doc(_appId)
        .collection('public')
        .doc('data')
        .collection('stock_updates');
  }

  // REAL RELAX DECOR INVENTORY DATA
  final List<Map<String, dynamic>> _realInventoryData = [
    // ========== SOFAS ==========
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
      'model': 'Carol Sofa 2 Seater',
      'design': 'Carol',
      'size': '140x92x90cm',
      'color': 'Black & Red Contros',
      'price': 500.0,
      'stock': 8,
    },
    {
      'category': 'Sofa',
      'model': 'Anton Sofa 3 Seater',
      'design': 'Anton',
      'size': '190x95x88cm',
      'color': 'Grey',
      'price': 650.0,
      'stock': 12,
    },
    {
      'category': 'Sofa',
      'model': 'Anton Sofa 2 Seater',
      'design': 'Anton',
      'size': '145x95x88cm',
      'color': 'Grey',
      'price': 550.0,
      'stock': 6,
    },
    {
      'category': 'Sofa',
      'model': 'Bostan Sofa 3 Seater',
      'design': 'Bostan',
      'size': '195x90x85cm',
      'color': 'Beige',
      'price': 700.0,
      'stock': 15,
    },
    {
      'category': 'Sofa',
      'model': 'Artic Sofa 3 Seater',
      'design': 'Artic',
      'size': '185x93x87cm',
      'color': 'Dark Brown',
      'price': 750.0,
      'stock': 9,
    },
    {
      'category': 'Sofa',
      'model': 'Relax Sofa 3 Seater',
      'design': 'Relax',
      'size': '192x94x86cm',
      'color': 'Light Grey',
      'price': 680.0,
      'stock': 11,
    },
    {
      'category': 'Sofa',
      'model': 'Antario Sofa 3 Seater',
      'design': 'Antario',
      'size': '198x96x89cm',
      'color': 'Navy Blue',
      'price': 720.0,
      'stock': 7,
    },
    {
      'category': 'Sofa',
      'model': 'Handerson Sofa 3 Seater',
      'design': 'Handerson',
      'size': '188x92x90cm',
      'color': 'Black',
      'price': 690.0,
      'stock': 14,
    },
    {
      'category': 'Sofa',
      'model': 'Enzo Sofa 3 Seater',
      'design': 'Enzo',
      'size': '190x95x88cm',
      'color': 'Cream',
      'price': 710.0,
      'stock': 8,
    },
    {
      'category': 'Sofa',
      'model': 'Loca Sofa 3 Seater',
      'design': 'Loca',
      'size': '185x93x87cm',
      'color': 'Charcoal',
      'price': 670.0,
      'stock': 13,
    },
    {
      'category': 'Sofa',
      'model': 'Ibiza Sofa 3 Seater',
      'design': 'Ibiza',
      'size': '192x94x86cm',
      'color': 'White',
      'price': 730.0,
      'stock': 10,
    },
    {
      'category': 'Sofa',
      'model': 'Carol Corner Sofa',
      'design': 'Carol Corner',
      'size': '220x220x90cm',
      'color': 'Black & Red Contros',
      'price': 1200.0,
      'stock': 5,
    },
    // ========== BEDS ==========
    {
      'category': 'Bed',
      'model': 'Platform Bed King',
      'design': 'Platform',
      'size': '180x200cm',
      'color': 'Oak Finish',
      'price': 450.0,
      'stock': 8,
    },
    {
      'category': 'Bed',
      'model': 'Storage Bed Queen',
      'design': 'Storage',
      'size': '160x200cm',
      'color': 'Walnut Finish',
      'price': 550.0,
      'stock': 6,
    },
    {
      'category': 'Bed',
      'model': 'Four Poster Bed King',
      'design': 'Four Poster',
      'size': '180x200cm',
      'color': 'Dark Mahogany',
      'price': 850.0,
      'stock': 3,
    },
    // ========== DINING TABLES ==========
    {
      'category': 'Dining Table',
      'model': 'Glass Top Dining Table',
      'design': 'Glass Top',
      'size': '140x80x75cm',
      'color': 'Clear Glass',
      'price': 350.0,
      'stock': 7,
    },
    {
      'category': 'Dining Table',
      'model': 'Solid Wood Dining Table',
      'design': 'Solid Wood',
      'size': '160x90x75cm',
      'color': 'Teak Finish',
      'price': 480.0,
      'stock': 5,
    },
    {
      'category': 'Dining Table',
      'model': 'Pedestal Dining Table',
      'design': 'Pedestal',
      'size': '150x85x75cm',
      'color': 'White Marble',
      'price': 520.0,
      'stock': 4,
    },
    // ========== TV TABLES ==========
    {
      'category': 'TV Table',
      'model': 'Metal Frame TV Stand',
      'design': 'Metal Frame',
      'size': '120x40x50cm',
      'color': 'Black Metal',
      'price': 120.0,
      'stock': 10,
    },
    {
      'category': 'TV Table',
      'model': 'Wall Mount TV Cabinet',
      'design': 'Wall Mount',
      'size': '140x35x45cm',
      'color': 'White',
      'price': 180.0,
      'stock': 8,
    },
    {
      'category': 'TV Table',
      'model': 'Cabinet TV Table',
      'design': 'Cabinet',
      'size': '160x45x55cm',
      'color': 'Cherry Wood',
      'price': 220.0,
      'stock': 6,
    },
    // ========== WARDROBES ==========
    {
      'category': 'Wardrobe',
      'model': 'Side Mirror Wardrobe',
      'design': 'Side Mirror',
      'size': '180x60x220cm',
      'color': 'High Gloss White',
      'price': 420.0,
      'stock': 4,
    },
    {
      'category': 'Wardrobe',
      'model': 'Center Mirror Wardrobe',
      'design': 'Center Mirror',
      'size': '200x65x225cm',
      'color': 'Walnut Finish',
      'price': 480.0,
      'stock': 3,
    },
    {
      'category': 'Wardrobe',
      'model': 'Internal Side Wardrobe',
      'design': 'Internal Side',
      'size': '220x70x230cm',
      'color': 'Oak Finish',
      'price': 520.0,
      'stock': 5,
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
              .where((value) => value != null && value.isNotEmpty)
              .map((value) => value!)
              .toSet()
              .toList();

          final defaultName =
              'All ${fieldName[0].toUpperCase()}${fieldName.substring(1)}s';
          values.sort();
          return [defaultName, ...values];
        });
  }

  // MODIFIED: Updated sellItem to record sales with price
  Future<void> sellItem(String itemId, int quantity, FurnitureItem item) async {
    await _db.runTransaction((transaction) async {
      final itemRef = _inventoryCollectionRef.doc(itemId);
      final doc = await transaction.get(itemRef);

      if (!doc.exists) throw Exception('Item not found');

      final currentStock = (doc.data() as Map<String, dynamic>)['stock'] as int;
      if (currentStock >= quantity) {
        // Update inventory stock
        transaction.update(itemRef, {'stock': currentStock - quantity});

        // Record the sale
        final salesRecord = SalesRecord(
          id: '', // Will be auto-generated
          itemId: itemId,
          category: item.category,
          model: item.model,
          price: item.price,
          quantity: quantity,
          totalAmount: item.price * quantity,
          saleDate: DateTime.now(),
          design: item.design,
          color: item.color,
          size: item.size,
        );

        final salesDocRef = _salesCollectionRef.doc();
        transaction.set(salesDocRef, salesRecord.toFirestore());
      } else {
        throw Exception(
          'Not enough stock! Available: $currentStock, Requested: $quantity',
        );
      }
    });
  }

  // NEW: Get current user email
  String? getCurrentUserEmail() {
    return FirebaseAuth.instance.currentUser?.email;
  }

  // MODIFIED: Update stock with user tracking
  Future<void> updateStock(String itemId, int newQuantity) async {
    if (newQuantity < 0) throw Exception('Stock quantity cannot be negative.');

    final itemRef = _inventoryCollectionRef.doc(itemId);
    final userEmail = getCurrentUserEmail() ?? 'Unknown User';
    final now = DateTime.now();

    await _db.runTransaction((transaction) async {
      // Get current item data
      final doc = await transaction.get(itemRef);
      if (!doc.exists) throw Exception('Item not found');

      final currentData = doc.data() as Map<String, dynamic>;
      final previousStock = (currentData['stock'] as num).toInt();

      // Update inventory
      transaction.update(itemRef, {
        'stock': newQuantity,
        'lastUpdatedBy': userEmail,
        'lastUpdatedAt': Timestamp.fromDate(now),
      });

      // Record stock update
      final stockUpdateRecord = StockUpdateRecord(
        id: '', // Auto-generated
        itemId: itemId,
        category: currentData['category'] as String,
        model: currentData['model'] as String,
        updatedBy: userEmail,
        updatedAt: now,
        previousStock: previousStock,
        newStock: newQuantity,
        changeAmount: newQuantity - previousStock,
        updateType: 'set',
        design: currentData['design'] as String?,
        color: currentData['color'] as String?,
        size: currentData['size'] as String?,
      );

      final updateDocRef = _stockUpdatesCollectionRef.doc();
      transaction.set(updateDocRef, stockUpdateRecord.toFirestore());
    });
  }

  // MODIFIED: Increase stock with user tracking
  Future<void> increaseStock(String itemId, int increaseAmount) async {
    if (increaseAmount <= 0) {
      throw Exception('Increase amount must be positive.');
    }

    final itemRef = _inventoryCollectionRef.doc(itemId);
    final userEmail = getCurrentUserEmail() ?? 'Unknown User';
    final now = DateTime.now();

    await _db.runTransaction((transaction) async {
      // Get current item data
      final doc = await transaction.get(itemRef);
      if (!doc.exists) throw Exception('Item not found');

      final currentData = doc.data() as Map<String, dynamic>;
      final previousStock = (currentData['stock'] as num).toInt();
      final newStock = previousStock + increaseAmount;

      // Update inventory
      transaction.update(itemRef, {
        'stock': FieldValue.increment(increaseAmount),
        'lastUpdatedBy': userEmail,
        'lastUpdatedAt': Timestamp.fromDate(now),
      });

      // Record stock update
      final stockUpdateRecord = StockUpdateRecord(
        id: '', // Auto-generated
        itemId: itemId,
        category: currentData['category'] as String,
        model: currentData['model'] as String,
        updatedBy: userEmail,
        updatedAt: now,
        previousStock: previousStock,
        newStock: newStock,
        changeAmount: increaseAmount,
        updateType: 'increase',
        design: currentData['design'] as String?,
        color: currentData['color'] as String?,
        size: currentData['size'] as String?,
      );

      final updateDocRef = _stockUpdatesCollectionRef.doc();
      transaction.set(updateDocRef, stockUpdateRecord.toFirestore());
    });
  }

  Stream<int> streamTotalStock(String categoryName) {
    return _inventoryCollectionRef
        .where('category', isEqualTo: categoryName)
        .snapshots()
        .map(
          // ignore: avoid_types_as_parameter_names
          (snapshot) => snapshot.docs.fold(0, (sum, doc) {
            return sum + (doc.data()['stock'] as num).toInt();
          }),
        );
  }

  // NEW: Get all stock updates
  Stream<List<StockUpdateRecord>> getStockUpdates() {
    return _stockUpdatesCollectionRef
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StockUpdateRecord.fromFirestore(doc))
              .toList(),
        );
  }

  // NEW: Get stock updates for a specific item
  Stream<List<StockUpdateRecord>> getStockUpdatesForItem(String itemId) {
    return _stockUpdatesCollectionRef
        .where('itemId', isEqualTo: itemId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StockUpdateRecord.fromFirestore(doc))
              .toList(),
        );
  }

  // Get sales records for a specific month
  Stream<List<SalesRecord>> getMonthlySales(int year, int month) {
    // Calculate start and end of the month
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(
      year,
      month + 1,
      1,
    ).subtract(const Duration(days: 1));

    return _salesCollectionRef
        .where(
          'saleDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('saleDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('saleDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SalesRecord.fromFirestore(doc))
              .toList(),
        );
  }

  // Get monthly sales summary by category
  Stream<List<MonthlySalesSummary>> getMonthlySalesSummary(
    int year,
    int month,
  ) {
    return getMonthlySales(year, month).map((salesRecords) {
      final Map<String, MonthlySalesSummary> summaryMap = {};

      for (final record in salesRecords) {
        final key = record.category;
        if (!summaryMap.containsKey(key)) {
          summaryMap[key] = MonthlySalesSummary(
            category: key,
            totalItemsSold: 0,
            totalRevenue: 0,
            year: year,
            month: month,
          );
        }

        final current = summaryMap[key]!;
        summaryMap[key] = MonthlySalesSummary(
          category: key,
          totalItemsSold: current.totalItemsSold + record.quantity,
          totalRevenue: current.totalRevenue + record.totalAmount,
          year: year,
          month: month,
        );
      }

      return summaryMap.values.toList();
    });
  }

  // Get total monthly revenue
  Stream<double> getTotalMonthlyRevenue(int year, int month) {
    return getMonthlySales(year, month).map((salesRecords) {
      // ignore: avoid_types_as_parameter_names
      return salesRecords.fold(0.0, (sum, record) => sum + record.totalAmount);
    });
  }

  Stream<List<SalesRecord>> getCategoryMonthlySales(
    String category,
    int year,
    int month,
  ) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(
      year,
      month + 1,
      1,
    ).subtract(const Duration(days: 1));

    return _salesCollectionRef
        .where('category', isEqualTo: category)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SalesRecord.fromFirestore(doc))
              .toList(),
        );
  }
}
