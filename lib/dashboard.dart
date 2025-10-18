import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_system/firebase/firebase_service.dart';
import 'package:inventory_system/login_screen.dart';

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

  double _scale(double size) {
    final width = MediaQuery.of(context).size.width;
    return size * (width / 1200).clamp(0.5, 1.2);
  }

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

  Future<void> _sellItem(String itemId, String model) async {
    setState(() => _sellingItems[itemId] = true);
    try {
      await _firebaseService.sellItem(itemId);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sold one $model')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sale failed: ${_parseError(e)}')),
        );
    } finally {
      setState(() => _sellingItems.remove(itemId));
    }
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
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isIncrease ? 'Enter quantity to add:' : 'Set total quantity:'),
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
              radius: _scale(isMobile ? 16 : 20),
              child: Icon(icon, color: color, size: _scale(isMobile ? 18 : 24)),
            ),
            SizedBox(height: _scale(4)),
            Text(
              '$count',
              style: TextStyle(
                fontSize: _scale(isMobile ? 14 : 20),
                fontWeight: isLow ? FontWeight.w900 : FontWeight.bold,
                color: isLow ? Colors.red.shade700 : color.shade800,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _scale(isMobile ? 8 : 12),
                color: Colors.grey,
              ),
            ),
            if (isLow)
              Text(
                'LOW',
                style: TextStyle(
                  fontSize: _scale(6),
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
      padding: EdgeInsets.all(_scale(isMobile ? 14 : 20)),
      margin: EdgeInsets.symmetric(
        horizontal: _scale(isMobile ? 10 : 20),
        vertical: _scale(isMobile ? 14 : 8),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_scale(15)),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            blurRadius: _scale(10),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: _scale(14)),
            child: Text(
              'Filter Inventory',
              style: TextStyle(
                fontSize: _scale(isMobile ? 17 : 20),
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
                SizedBox(height: _scale(14)),
                _buildFilter(
                  'Size',
                  _selectedSize,
                  category,
                  (v) => setState(() => _selectedSize = v),
                ),
                SizedBox(height: _scale(14)),
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
                    padding: EdgeInsets.symmetric(horizontal: _scale(4)),
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
                    padding: EdgeInsets.symmetric(horizontal: _scale(4)),
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
                    padding: EdgeInsets.symmetric(horizontal: _scale(4)),
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
        final items = {
          allOption,
          ...dataItems,
        }.toList(); // Use Set to remove duplicates
        final selected = (value != null && items.contains(value))
            ? value
            : allOption;

        return DropdownButtonFormField<String>(
          value: selected,
          decoration: InputDecoration(
            labelText: field,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: _scale(15),
            ),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_scale(8)),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: _scale(12),
              vertical: _scale(14),
            ),
          ),
          icon: Icon(Icons.keyboard_arrow_down, size: _scale(26)),
          items: items
              .map<DropdownMenuItem<String>>(
                (v) => DropdownMenuItem<String>(
                  value: v,
                  child: Text(
                    v,
                    style: TextStyle(
                      fontSize: _scale(16),
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
                padding: EdgeInsets.all(_scale(40)),
                child: Center(
                  child: Text(
                    'No $category items match filters',
                    style: TextStyle(
                      fontSize: _scale(16),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(bottom: _scale(15)),
          itemCount: items.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _buildFilterRow(category, isMobile);
            final item = items[index - 1];
            return _ItemCard(
              item: item,
              isLow: item.stock <= _lowStockThreshold,
              isSelling: _sellingItems[item.id] == true,
              onSell: () => _sellItem(item.id, item.model),
              onSet: () =>
                  _showStockDialog(item.id, item.model, item.stock, false),
              onAdd: () =>
                  _showStockDialog(item.id, item.model, item.stock, true),
              scale: _scale,
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
              SizedBox(height: _scale(20)),
              Text(
                'Initializing...',
                style: TextStyle(
                  fontSize: _scale(16),
                  color: Colors.teal.shade800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text(
          'Inventory Dashboard',
          style: TextStyle(
            fontSize: _scale(isMobile ? 18 : 24),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal.shade800,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_scale(50)),
          child: TabBar(
            controller: _tabController,
            isScrollable: isMobile,
            tabAlignment: isMobile ? TabAlignment.start : TabAlignment.fill,
            tabs: _tabs
                .map(
                  (t) => Tab(
                    child: Text(
                      t,
                      style: TextStyle(fontSize: _scale(isMobile ? 14 : 18)),
                    ),
                  ),
                )
                .toList(),
            labelColor: Colors.teal.shade800,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.teal.shade500,
            indicatorWeight: _scale(3),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal.shade700),
              child: Text(
                'Relax Decor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _scale(26),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Colors.redAccent,
                size: _scale(24),
              ),
              title: Text('Logout', style: TextStyle(fontSize: _scale(18))),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(_scale(isMobile ? 12 : 20)),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: _scale(isMobile ? 14 : 20),
                horizontal: _scale(5),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_scale(15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.2),
                    blurRadius: _scale(10),
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
}

class _ItemCard extends StatelessWidget {
  final FurnitureItem item;
  final bool isLow, isSelling, isMobile;
  final VoidCallback onSell, onSet, onAdd;
  final double Function(double) scale;

  const _ItemCard({
    required this.item,
    required this.isLow,
    required this.isSelling,
    required this.onSell,
    required this.onSet,
    required this.onAdd,
    required this.scale,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final stockColor = isLow ? Colors.red.shade700 : Colors.teal.shade700;

    return Card(
      elevation: scale(4),
      margin: EdgeInsets.symmetric(
        horizontal: scale(isMobile ? 12 : 24),
        vertical: scale(8),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(scale(12)),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(
          horizontal: scale(isMobile ? 14 : 20),
          vertical: scale(12),
        ),
        leading: Container(
          width: scale(isMobile ? 45 : 55),
          height: scale(isMobile ? 45 : 55),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(scale(8)),
          ),
          child: Icon(
            Icons.palette_outlined,
            size: scale(isMobile ? 28 : 35),
            color: Colors.teal.shade400,
          ),
        ),
        title: Text(
          item.model,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: scale(isMobile ? 16 : 20),
          ),
        ),
        subtitle: isMobile
            ? null
            : Text(
                '${item.design} | ${item.color} | ${item.size}',
                style: TextStyle(
                  fontSize: scale(14),
                  color: Colors.grey.shade600,
                ),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: scale(10),
                vertical: scale(6),
              ),
              decoration: BoxDecoration(
                color: isLow
                    ? const Color(0xFFFFCDD2)
                    : stockColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(scale(8)),
                border: Border.all(color: stockColor),
              ),
              child: Text(
                '${item.stock}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: scale(isMobile ? 13 : 16),
                  color: stockColor,
                ),
              ),
            ),
            SizedBox(width: scale(8)),
            SizedBox(
              height: scale(36),
              child: OutlinedButton(
                onPressed: onSet,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: scale(10)),
                ),
                child: Text(
                  'SET',
                  style: TextStyle(
                    fontSize: scale(isMobile ? 11 : 13),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: scale(8)),
            SizedBox(
              height: scale(36),
              child: ElevatedButton(
                onPressed: item.stock > 0 && !isSelling ? onSell : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLow
                      ? Colors.red.shade600
                      : Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: scale(10)),
                ),
                child: isSelling
                    ? SizedBox(
                        width: scale(15),
                        height: scale(15),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'SELL',
                        style: TextStyle(
                          fontSize: scale(isMobile ? 11 : 13),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(scale(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(height: scale(18)),
                Text(
                  'Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: scale(17),
                    color: Colors.teal.shade800,
                  ),
                ),
                SizedBox(height: scale(12)),
                Text(
                  'Price: Rs ${item.price}',
                  style: TextStyle(
                    fontSize: scale(16),
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                SizedBox(height: scale(6)),
                Text(
                  'Design: ${item.design}',
                  style: TextStyle(fontSize: scale(15)),
                ),
                Text(
                  'Color: ${item.color}',
                  style: TextStyle(fontSize: scale(15)),
                ),
                Text(
                  'Size: ${item.size}',
                  style: TextStyle(fontSize: scale(15)),
                ),
                SizedBox(height: scale(16)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: Icon(Icons.add_business, size: scale(22)),
                    label: Text(
                      'Add Stock',
                      style: TextStyle(
                        fontSize: scale(17),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: scale(14)),
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
