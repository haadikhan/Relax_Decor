import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_system/firebase/firebase_service.dart';
import 'package:inventory_system/login_screen.dart';
import 'package:inventory_system/sales_screen.dart';
import 'package:inventory_system/sales_report_screen.dart';
import 'package:inventory_system/stock_history_screen.dart';

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

  FirebaseService get firebaseService => _firebaseService;

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
    if (!isIncrease) {
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    }

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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$model set to $qty')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${_parseError(e)}')));
      }
    }
  }

  Future<void> _increaseStock(String id, String model, int qty) async {
    try {
      await _firebaseService.increaseStock(id, qty);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Added $qty to $model')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${_parseError(e)}')));
      }
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
              // ignore: deprecated_member_use
              backgroundColor: color.withOpacity(isLow ? 0.2 : 0.1),
              radius: isMobile ? 16 : 20,
              child: Icon(icon, color: color, size: isMobile ? 18 : 24),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: isMobile ? 14 : 18,
                fontWeight: isLow ? FontWeight.w900 : FontWeight.bold,
                color: isLow ? Colors.red.shade700 : color.shade800,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: isMobile ? 9 : 12, color: Colors.grey),
            ),
            if (isLow)
              Text(
                'LOW',
                style: TextStyle(
                  fontSize: isMobile ? 7 : 9,
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
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: isMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Filter Inventory',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
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
                const SizedBox(height: 12),
                _buildFilter(
                  'Size',
                  _selectedSize,
                  category,
                  (v) => setState(() => _selectedSize = v),
                ),
                const SizedBox(height: 12),
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
              fontSize: 14,
            ),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, size: 24),
          items: items
              .map<DropdownMenuItem<String>>(
                (v) => DropdownMenuItem<String>(
                  value: v,
                  child: Text(
                    v,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
              onSell: () => _sellItem(item),
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
            fontSize: isMobile ? 18 : 24,
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
                        fontSize: isMobile ? 13 : (isTablet ? 15 : 16),
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
      drawer: _buildDrawer(isMobile),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 8 : 16),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 10 : 12,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
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
                ),
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: _tabs
                        .map((c) => _buildTabContent(c, isMobile))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(bool isMobile) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal.shade700),
            child: const Text(
              'Mob World',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.orange, size: 26),
            title: const Text('Stock History', style: TextStyle(fontSize: 18)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StockHistoryScreen(firebaseService: _firebaseService),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics, color: Colors.blue, size: 26),
            title: const Text('Sales Report', style: TextStyle(fontSize: 18)),
            onTap: () {
              Navigator.pop(context);
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
// Add this to the END of home_screen.dart file (after _HomeScreenState class)

class _ItemCard extends StatefulWidget {
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

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  bool _isExpanded = false;

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
    final Map<String, Map<String, String>> categoryImages = {
      'Sofa': {
        'Antario':
            'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=1200',
        'Anton':
            'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?w=1200',
        'Artic':
            'https://images.unsplash.com/photo-1540574163026-643ea20ade25?w=1200',
        'Bostan':
            'https://images.unsplash.com/photo-1567016432779-094069958ea5?w=1200',
        'Carol':
            'https://images.unsplash.com/photo-1550581190-9c1c48d21d6c?w=1200',
        'Carol Corner':
            'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=1200',
        'Enzo':
            'https://images.unsplash.com/photo-1598300188706-f9c3926fe0c0?w=1200',
        'Handerson':
            'https://images.unsplash.com/photo-1506439773649-6e0eb8cfb237?w=1200',
        'Ibiza':
            'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=1200',
        'Loca':
            'https://images.unsplash.com/photo-1550254478-ead40cc54513?w=1200',
        'Relax':
            'https://images.unsplash.com/photo-1484101403633-562f891dc89a?w=1200',
      },
      'Bed': {
        'Sleigh':
            'https://www.amareliving.com/wp-content/uploads/2022/04/chestefield-sleigh-ottoman-storage-bed-450x450.jpg',
        'Panel':
            'https://images.unsplash.com/photo-1540518614846-7eded433c457?w=1200',
        'Hilton':
            'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=1200',
        'Florida':
            'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=1200',
        'Divan':
            'https://images.unsplash.com/photo-1566417713940-fe7c737a9ef2?w=1200',
        'Mattress':
            'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=1200',
        'Gas Lift':
            'https://images.unsplash.com/photo-1615874959474-d609969a20ed?w=1200',
        'Platform':
            'https://images.unsplash.com/photo-1505693314120-0d443867891c?w=1200',
        'Storage':
            'https://images.unsplash.com/photo-1540518614846-7eded433c457?w=1200',
        'Four Poster':
            'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=1200',
      },
      'Dining Table': {
        'Glass Top':
            'https://images.unsplash.com/photo-1617806118233-18e1de247200?w=1200',
        'Solid Wood':
            'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?w=1200',
        'Pedestal':
            'https://images.unsplash.com/photo-1617806118062-17c3006f30ca?w=1200',
      },
      'TV Table': {
        'Metal Frame':
            'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=1200',
        'Wall Mount':
            'https://images.unsplash.com/photo-1565182999561-18d7dc61c393?w=1200',
        'Cabinet':
            'https://images.unsplash.com/photo-1581539250439-c96689b516dd?w=1200',
      },
      'Wardrobe': {
        'Side Mirror':
            'https://images.unsplash.com/photo-1595428774223-ef52624120d2?w=1200',
        'Center Mirror':
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=1200',
        'Inside Mirror':
            'https://images.unsplash.com/photo-1566417713940-fe7c737a9ef2?w=1200',
        'Internal Side':
            'https://images.unsplash.com/photo-1566417713940-fe7c737a9ef2?w=1200',
      },
    };
    return categoryImages[category]?[design] ??
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=1200';
  }

  void _showEditPriceDialog(BuildContext context) {
    final controller = TextEditingController(
      text: widget.item.price.toStringAsFixed(0),
    );
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.euro, color: Colors.green.shade700, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Edit Price',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product: ${widget.item.model}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Current Price: €${widget.item.price.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'New Price (€)',
                hintText: 'Enter price',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.euro, color: Colors.green.shade600),
                suffixText: 'EUR',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null && newPrice > 0) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Updating price...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                try {
                  final firebaseService = context
                      .findAncestorStateOfType<_HomeScreenState>()
                      ?.firebaseService;
                  if (firebaseService != null) {
                    await firebaseService.updateItemPrice(
                      widget.item.id,
                      newPrice,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Price updated to €${newPrice.toStringAsFixed(0)}',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update price: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid price'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            child: const Text('Update Price'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 8 : 16,
        vertical: 6,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.item.design != null
                      ? Image.network(
                          _getCategoryImage(
                            widget.item.category,
                            widget.item.design!,
                          ),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: Icon(
                                    _getCategoryIcon(widget.item.category),
                                    size: 50,
                                    color: Colors.teal.shade400,
                                  ),
                                ),
                              ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey.shade200,
                              child: Center(
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.teal.shade400,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(
                              _getCategoryIcon(widget.item.category),
                              size: 50,
                              color: Colors.teal.shade400,
                            ),
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 10,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.model,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 3, color: Colors.black87),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.item.design} • ${widget.item.color} • ${widget.item.size}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            shadows: const [
                              Shadow(blurRadius: 2, color: Colors.black87),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isLow
                            ? Colors.red.shade600
                            : Colors.teal.shade600,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        '${widget.item.stock}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        '€${widget.item.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: widget.item.stock > 0 && !widget.isSelling
                          ? widget.onSell
                          : null,
                      icon: widget.isSelling
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.shopping_cart, size: 16),
                      label: Text(
                        widget.isSelling ? 'SELLING' : 'SELL',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isLow
                            ? Colors.red.shade600
                            : Colors.teal.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 36,
                  width: 70,
                  child: OutlinedButton(
                    onPressed: widget.onSet,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'SET',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 36,
                  width: 120,
                  child: OutlinedButton(
                    onPressed: widget.onAdd,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'ADD STOCK',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isExpanded ? Icons.remove : Icons.add,
                    size: 18,
                    color: Colors.teal.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isExpanded ? 'Show Less Details' : 'Show More Details',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    Icons.inventory_2,
                    'Model',
                    widget.item.model,
                    Colors.teal.shade700,
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    Icons.design_services,
                    'Design',
                    widget.item.design ?? 'N/A',
                    Colors.indigo.shade700,
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    Icons.palette,
                    'Color',
                    widget.item.color ?? 'N/A',
                    Colors.purple.shade700,
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    Icons.straighten,
                    'Size',
                    widget.item.size ?? 'N/A',
                    Colors.orange.shade700,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          Icons.euro,
                          'Price',
                          '€${widget.item.price.toStringAsFixed(0)}',
                          Colors.green.shade700,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showEditPriceDialog(context),
                        icon: Icon(
                          Icons.edit,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        tooltip: 'Edit Price',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  if (widget.item.lastUpdatedBy != null &&
                      widget.item.lastUpdatedAt != null) ...[
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      Icons.person,
                      'Updated By',
                      widget.item.lastUpdatedBy!,
                      Colors.grey.shade600,
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onAdd,
                      icon: const Icon(Icons.add_business, size: 18),
                      label: const Text(
                        'Add More Stock',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
