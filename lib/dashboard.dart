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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Added $qty to $model')));
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

// CONTINUE IN PART 2...// Add this to the END of home_screen.dart file (after _HomeScreenState class)

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
            'https://images.dfs.co.uk/i/dfs/sanantonio_zg_superclub_fossil_view1',
        'Anton':
            'https://quildinc.co.uk/cdn/shop/products/s-l1600_39bd43a4-81ec-4a7b-b89a-c349f3a9abd5_2048x2048.jpg?v=1618049170',
        'Artic':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRn3AGOWMOtF6TD7V8a9b0oJW80yI4iCGcELxGAht2wKqZyAJwiUP55weLsp91RhSEbjn0&usqp=CAU',
        'Bostan':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRn3AGOWMOtF6TD7V8a9b0oJW80yI4iCGcELxGAht2wKqZyAJwiUP55weLsp91RhSEbjn0&usqp=CAU',
        'Carol':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQUADue-_tBo5mOuTqKCPGsoCyu2PjtlwlQKA&s',
        'Carol Corner':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQUADue-_tBo5mOuTqKCPGsoCyu2PjtlwlQKA&s',
        'Enzo':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSsx_WMyAnrRNv9nF3IhgCy5xQ-f5tuSLc7dA&s',
        'Handerson':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSoWt2y_fcbSINwB2RHFXQhahRA4M2wtiEh0A&s',
        'Ibiza':
            'https://imperialliving.com.cy/cdn/shop/files/Ibiza_Sofa_4.webp?v=1743601631',
        'Loca':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSvzuDVAhf7tr6mw_gvnJ3MsS_BRDitoZ-izw&s',
        'Relax':
            'https://imperialliving.com.cy/cdn/shop/files/Lisboa_Relax_Sofa_1.webp?v=1743601631',
      },
      'Bed': {
        'Sleigh':
            'https://www.heavenlybeds.co.uk/cdn/shop/files/new-scroll-naples-19-1_34ca72be-fafc-41f9-8b04-87066113be2d.png?v=1759913544&width=460',
        'Panel':
            'https://www.luxelivinginteriors.co.za/cdn/shop/files/d8a0e26f74364edb5e1c9e4ef81aa568.jpg?v=1712532135',
        'Hilton':
            'https://newlookhome.eu/cdn/shop/files/1_8d971cdd-c5b9-47cd-8a9a-d7f94883c3cd.jpg?v=1738085760&width=2048',
        'Florida':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQihl0Efz8PDCmYQRlGeCopr7zk3Q6qijcXlA&s',
        'Divan':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTk4Ax2U5_FLmuvQam6sg0hUHIw1bUTmq5kwA&s',
        'Mattress':
            'https://cdn.thewirecutter.com/wp-content/media/2024/03/foam-mattress-2048px-6701.jpg?auto=webp&quality=75&width=1024',
        'Gas Lift':
            'https://bestinbeds.com.au/cdn/shop/files/Barcelona-Gas-Lift-Bed-Walnut.jpg?v=1733717711',
        'Platform':
            'https://images.unsplash.com/photo-1505693314120-0d443867891c?w=1200',
        'Storage':
            'https://lofthome.com/cdn/shop/collections/storage-beds.jpg?v=1729409988',
        'Four Poster':
            'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=1200',
      },
      'Dining Table': {
        'Glass Top':
            'https://m.media-amazon.com/images/I/91y0RhC5uIL._AC_UF894,1000_QL80_.jpg',
        'Solid Wood':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTpQVYxJHxvRF0vI5B_nCXG5WK8vRKYNg6QTw&s',
        'Pedestal': 'https://m.media-amazon.com/images/I/91EXiD1TIXL.jpg',
      },
      'TV Table': {
        'Metal Frame':
            'https://static-01.daraz.pk/p/5039a23c1c47ddf372eb136b9a724c68.jpg',
        'Wall Mount':
            'https://efurniture.pk/cdn/shop/files/4_b6dfb02d-0dde-4848-ae17-20fa55ebfff4.jpg?v=1751531486',
        'Cabinet':
            'https://img.drz.lazcdn.com/static/pk/p/250544e1df17b36e7a11ca7883de14ae.jpg_720x720q80.jpg',
      },
      'Wardrobe': {
        'Side Mirror':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT4uIIpTEpFz-EYrjgcjIurhfOuznuFX_SrosewxB0wKOt0SbBr7V4oIIvmU8iIBC3Rf1w&usqp=CAU',
        'Center Mirror':
            'https://i.ebayimg.com/images/g/nSAAAOSwz6tnkqMK/s-l1200.jpg',
        'Inside Mirror':
            'https://www.wakefit.co/blog/wp-content/uploads/2025/03/Untitled-1000-x-1000-px-4.png',
        'Internal Side':
            'https://m.media-amazon.com/images/I/61JxkpNDXyL._UF350,350_QL80_.jpg',
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
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: widget.isMobile
            ? double.infinity
            : 600, // Max width on desktop
      ),
      child: Card(
        elevation: 3,
        margin: EdgeInsets.symmetric(
          horizontal: widget.isMobile ? 8 : 16,
          vertical: 6,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Container(
              height: widget.isMobile
                  ? 180
                  : 280, // Fixed height based on device
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
                            fit: BoxFit.cover, // Changed from BoxFit.fill
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
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
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
