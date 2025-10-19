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

// NEW: Sales Record Model
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

// NEW: Monthly Sales Summary Model
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

  // NEW: Sales collection reference
  CollectionReference<Map<String, dynamic>> get _salesCollectionRef {
    return _db
        .collection('artifacts')
        .doc(_appId)
        .collection('public')
        .doc('data')
        .collection('sales_records');
  }

  // REAL RELAX DECOR INVENTORY DATA (same as before)
  final List<Map<String, dynamic>> _realInventoryData = [
    // ... (your existing inventory data remains exactly the same)
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
    // ... (include all your existing inventory items)
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

  // NEW: Get sales records for a specific month
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

  // NEW: Get monthly sales summary by category
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

  // NEW: Get total monthly revenue
  Stream<double> getTotalMonthlyRevenue(int year, int month) {
    return getMonthlySales(year, month).map((salesRecords) {
      return salesRecords.fold(0.0, (sum, record) => sum + record.totalAmount);
    });
  }

  // NEW: Get sales records for a specific category in a month
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
}
