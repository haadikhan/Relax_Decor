import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_system/firebase/firebase_service.dart';
import 'package:inventory_system/login_screen.dart';
import 'package:inventory_system/sales_screen.dart';
import 'package:inventory_system/sales_report_screen.dart'; // Add this import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const _lowStockThreshold = 5;
  static const _tabs = ['Bed', 'Sofa', 'Dining Table', 'TV Table', 'Wardrobe'];

  late TabController _tabController;
  late FirebaseService _firebaseService;
  bool _isAuthReady = false;
  final Map<String, bool> _sellingItems = {};

  String? _selectedDesign = 'All Designs';
  String? _selectedColor = 'All Colors';
  String? _selectedSize = 'All Sizes';

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() {
            _selectedDesign = 'All Designs';
            _selectedColor = 'All Colors';
            _selectedSize = 'All Sizes';
          });
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    const appId = String.fromEnvironment('__app_id');
    _firebaseService = FirebaseService(
      appId: appId.isEmpty ? 'default-app-id' : appId,
    );
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        const token = String.fromEnvironment('__initial_auth_token');
        token.isNotEmpty
            ? await auth.signInWithCustomToken(token)
            : await auth.signInAnonymously();
      }
      await _firebaseService.seedInventoryIfEmpty();
    } catch (e) {
      debugPrint('Init error: $e');
    }
    setState(() => _isAuthReady = true);
  }

  // MODIFIED: Updated _sellItem to navigate to SalesScreen with the item
  Future<void> _sellItem(FurnitureItem item) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SalesScreen(item: item, firebaseService: _firebaseService),
      ),
    );
  }

  String _parseError(dynamic e) {
    if (e is FirebaseException) return e.message ?? 'Firestore error';
    if (e is PlatformException) return e.message ?? 'Platform error';
    final error = e.toString();
    if (error.contains('out of stock')) return 'Out of stock!';
    if (error.contains('Item not found')) return 'Item not found!';
    return error.split(':').last.trim();
  }

  void _logout() {
    FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _showStockDialog(
    String itemId,
    String model,
    int current,
    bool isIncrease,
  ) {
    final controller = TextEditingController(
      text: isIncrease ? '' : current.toString(),
    );
    if (!isIncrease)
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          '${isIncrease ? "Add" : "Set"} Stock for $model',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isIncrease ? 'Enter quantity to add:' : 'Set total quantity:',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(
                  isIncrease
                      ? Icons.add_shopping_cart
                      : Icons.inventory_2_outlined,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(controller.text);
              if (qty != null && qty >= 0) {
                Navigator.pop(context);
                isIncrease
                    ? _increaseStock(itemId, model, qty)
                    : _updateStock(itemId, model, qty);
              }
            },
            child: Text(isIncrease ? 'Add' : 'Set'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStock(String id, String model, int qty) async {
    try {
      await _firebaseService.updateStock(id, qty);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$model set to $qty')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${_parseError(e)}')));
    }
  }

  Future<void> _increaseStock(String id, String model, int qty) async {
    try {
      await _firebaseService.increaseStock(id, qty);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Added $qty to $model')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${_parseError(e)}')));
    }
  }

  Widget _buildStockItem(
    IconData icon,
    String label,
    Stream<int> stream,
    MaterialColor color,
    bool isMobile,
  ) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        final isLow = count <= _lowStockThreshold;
        return Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(isLow ? 0.2 : 0.1),
              radius: isMobile ? 18 : 24,
              child: Icon(icon, color: color, size: isMobile ? 20 : 28),
            ),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: isMobile ? 16 : 22,
                fontWeight: isLow ? FontWeight.w900 : FontWeight.bold,
                color: isLow ? Colors.red.shade700 : color.shade800,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 10 : 14,
                color: Colors.grey,
              ),
            ),
            if (isLow)
              Text(
                'LOW',
                style: TextStyle(
                  fontSize: isMobile ? 8 : 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.red.shade700,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilterRow(String category, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Filter Inventory',
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
          ),
          if (isMobile)
            Column(
              children: [
                _buildFilter(
                  'Design',
                  _selectedDesign,
                  category,
                  (v) => setState(() => _selectedDesign = v),
                ),
                const SizedBox(height: 16),
                _buildFilter(
                  'Size',
                  _selectedSize,
                  category,
                  (v) => setState(() => _selectedSize = v),
                ),
                const SizedBox(height: 16),
                _buildFilter(
                  'Color',
                  _selectedColor,
                  category,
                  (v) => setState(() => _selectedColor = v),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _buildFilter(
                      'Design',
                      _selectedDesign,
                      category,
                      (v) => setState(() => _selectedDesign = v),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _buildFilter(
                      'Size',
                      _selectedSize,
                      category,
                      (v) => setState(() => _selectedSize = v),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _buildFilter(
                      'Color',
                      _selectedColor,
                      category,
                      (v) => setState(() => _selectedColor = v),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFilter(
    String field,
    String? value,
    String category,
    ValueChanged<String?> onChanged,
  ) {
    return StreamBuilder<List<String>>(
      stream: _firebaseService.streamDistinctValues(
        category,
        field.toLowerCase(),
      ),
      builder: (context, snapshot) {
        final allOption = 'All ${field}s';
        final dataItems = snapshot.data ?? [];
        final items = {allOption, ...dataItems}.toList();
        final selected = (value != null && items.contains(value))
            ? value
            : allOption;

        return DropdownButtonFormField<String>(
          value: selected,
          decoration: InputDecoration(
            labelText: field,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, size: 28),
          items: items
              .map<DropdownMenuItem<String>>(
                (v) => DropdownMenuItem<String>(
                  value: v,
                  child: Text(
                    v,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }

  Widget _buildTabContent(String category, bool isMobile) {
    return StreamBuilder<List<FurnitureItem>>(
      stream: _firebaseService.streamInventory(
        category,
        design: _selectedDesign == 'All Designs' ? null : _selectedDesign,
        color: _selectedColor == 'All Colors' ? null : _selectedColor,
        size: _selectedSize == 'All Sizes' ? null : _selectedSize,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return ListView(
            children: [
              _buildFilterRow(category, isMobile),
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No $category items match filters',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: items.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _buildFilterRow(category, isMobile);
            final item = items[index - 1];
            return _ItemCard(
              item: item,
              isLow: item.stock <= _lowStockThreshold,
              isSelling: _sellingItems[item.id] == true,
              onSell: () => _sellItem(item), // MODIFIED: Pass the item object
              onSet: () =>
                  _showStockDialog(item.id, item.model, item.stock, false),
              onAdd: () =>
                  _showStockDialog(item.id, item.model, item.stock, true),
              isMobile: isMobile,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthReady) {
      return Scaffold(
        backgroundColor: Colors.teal.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.teal.shade600),
              const SizedBox(height: 24),
              Text(
                'Initializing...',
                style: TextStyle(fontSize: 18, color: Colors.teal.shade800),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text(
          'Inventory Dashboard',
          style: TextStyle(
            fontSize: isMobile ? 20 : 26,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal.shade800,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 48 : 56),
          child: TabBar(
            controller: _tabController,
            isScrollable: isMobile,
            tabAlignment: isMobile ? TabAlignment.start : TabAlignment.fill,
            tabs: _tabs
                .map(
                  (t) => Tab(
                    child: Text(
                      t,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : (isTablet ? 16 : 18),
                      ),
                    ),
                  ),
                )
                .toList(),
            labelColor: Colors.teal.shade800,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.teal.shade500,
            indicatorWeight: 3,
          ),
        ),
      ),
      drawer: _buildDrawer(isMobile), // MODIFIED: Use the drawer builder method
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 24),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 16 : 24,
                horizontal: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _buildStockItem(
                      Icons.bed,
                      'Beds',
                      _firebaseService.streamTotalStock('Bed'),
                      Colors.teal,
                      isMobile,
                    ),
                  ),
                  Expanded(
                    child: _buildStockItem(
                      Icons.chair_alt,
                      'Sofas',
                      _firebaseService.streamTotalStock('Sofa'),
                      Colors.indigo,
                      isMobile,
                    ),
                  ),
                  Expanded(
                    child: _buildStockItem(
                      Icons.restaurant,
                      'Dining',
                      _firebaseService.streamTotalStock('Dining Table'),
                      Colors.orange,
                      isMobile,
                    ),
                  ),
                  Expanded(
                    child: _buildStockItem(
                      Icons.tv,
                      'TV Tables',
                      _firebaseService.streamTotalStock('TV Table'),
                      Colors.purple,
                      isMobile,
                    ),
                  ),
                  Expanded(
                    child: _buildStockItem(
                      Icons.checkroom,
                      'Wardrobes',
                      _firebaseService.streamTotalStock('Wardrobe'),
                      Colors.brown,
                      isMobile,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs
                  .map((c) => _buildTabContent(c, isMobile))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Drawer builder method with Sales Report option
  Widget _buildDrawer(bool isMobile) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal.shade700),
            child: const Text(
              'Relax Decor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.analytics, color: Colors.blue, size: 26),
            title: const Text('Sales Report', style: TextStyle(fontSize: 18)),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SalesReportScreen(firebaseService: _firebaseService),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Colors.redAccent,
              size: 26,
            ),
            title: const Text('Logout', style: TextStyle(fontSize: 18)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final FurnitureItem item;
  final bool isLow, isSelling, isMobile;
  final VoidCallback onSell, onSet, onAdd;

  const _ItemCard({
    required this.item,
    required this.isLow,
    required this.isSelling,
    required this.onSell,
    required this.onSet,
    required this.onAdd,
    required this.isMobile,
  });

  static IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Sofa':
        return Icons.chair_alt;
      case 'Bed':
        return Icons.bed;
      case 'Dining Table':
        return Icons.restaurant;
      case 'TV Table':
        return Icons.tv;
      case 'Wardrobe':
        return Icons.checkroom;
      default:
        return Icons.category;
    }
  }

  static String _getCategoryImage(String category, String design) {
    // Example images - Replace these URLs with your actual product images
    final Map<String, Map<String, String>> categoryImages = {
      'Sofa': {
        'Carol':
            'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400',
        'Anton':
            'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400',
        'Bostan':
            'https://images.unsplash.com/photo-1540574163026-643ea20ade25?w=400',
        'Artic':
            'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?w=400',
        'Relax':
            'https://images.unsplash.com/photo-1550254478-ead40cc54513?w=400',
        'Antario':
            'https://images.unsplash.com/photo-1567016432779-094069958ea5?w=400',
        'Handerson':
            'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=400',
        'Enzo':
            'https://images.unsplash.com/photo-1558211583-803ea7c22743?w=400',
        'Loca':
            'https://images.unsplash.com/photo-1484101403633-562f891dc89a?w=400',
        'Ibiza':
            'https://images.unsplash.com/photo-1554995207-c18c203602cb?w=400',
        'Carol Corner':
            'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=400',
      },
      'Bed': {
        'Platform':
            'https://images.unsplash.com/photo-1505693314120-0d443867891c?w=400',
        'Storage':
            'https://images.unsplash.com/photo-1540518614846-7eded433c457?w=400',
        'Four Poster':
            'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=400',
      },
      'Dining Table': {
        'Glass Top':
            'https://images.unsplash.com/photo-1617806118233-18e1de247200?w=400',
        'Solid Wood':
            'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?w=400',
        'Pedestal':
            'https://images.unsplash.com/photo-1617806118062-17c3006f30ca?w=400',
      },
      'TV Table': {
        'Metal Frame':
            'https://images.unsplash.com/photo-1593359863503-f598de57d1eb?w=400',
        'Wall Mount':
            'https://images.unsplash.com/photo-1565182999561-18d7dc61c393?w=400',
        'Cabinet':
            'https://images.unsplash.com/photo-1581539250439-c96689b516dd?w=400',
      },
      'Wardrobe': {
        'Side Mirror':
            'https://images.unsplash.com/photo-1595428774223-ef52624120d2?w=400',
        'Center Mirror':
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
        'Internal Side':
            'https://images.unsplash.com/photo-1566417713940-fe7c737a9ef2?w=400',
      },
    };

    return categoryImages[category]?[design] ??
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400';
  }

  @override
  Widget build(BuildContext context) {
    final stockColor = isLow ? Colors.red.shade700 : Colors.teal.shade700;

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 10,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 20,
          vertical: 12,
        ),
        leading: Container(
          width: isMobile ? 48 : 60,
          height: isMobile ? 48 : 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.design != null
                ? Image.network(
                    _getCategoryImage(item.category, item.design!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      _getCategoryIcon(item.category),
                      size: isMobile ? 28 : 36,
                      color: Colors.teal.shade400,
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.teal.shade400,
                          ),
                        ),
                      );
                    },
                  )
                : Icon(
                    _getCategoryIcon(item.category),
                    size: isMobile ? 28 : 36,
                    color: Colors.teal.shade400,
                  ),
          ),
        ),
        title: Text(
          item.model,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isMobile ? 16 : 20,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${item.design} | ${item.color} | ${item.size}',
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '€${item.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 12,
                vertical: isMobile ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: isLow
                    ? const Color(0xFFFFCDD2)
                    : stockColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: stockColor),
              ),
              child: Text(
                '${item.stock}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 18,
                  color: stockColor,
                ),
              ),
            ),
            SizedBox(width: isMobile ? 6 : 10),
            SizedBox(
              height: isMobile ? 32 : 38,
              child: OutlinedButton(
                onPressed: onSet,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
                ),
                child: Text(
                  'SET',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: isMobile ? 6 : 10),
            SizedBox(
              height: isMobile ? 32 : 38,
              child: ElevatedButton(
                onPressed: item.stock > 0 && !isSelling ? onSell : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLow
                      ? Colors.red.shade600
                      : Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
                ),
                child: isSelling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'SELL',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 20),
                Text(
                  'Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.teal.shade800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Price: €${item.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Design: ${item.design}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Color: ${item.color}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Size: ${item.size}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_business, size: 24),
                    label: const Text(
                      'Add Stock',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
