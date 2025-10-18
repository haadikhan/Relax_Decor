import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_system/firebase/firebase_service.dart';
// import 'package:inventory_system/furniture_item.dart';
import 'package:inventory_system/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Constants
  static const _lowStockThreshold = 5;
  static const _tabs = ['Bed', 'Sofa', 'Dining Table', 'TV Table', 'Wardrobe'];

  // State variables
  late TabController _tabController;
  late FirebaseService _firebaseService;
  bool _isAuthReady = false;
  final Map<String, bool> _sellingItems = {};

  // Filter state
  String? _selectedDesign = 'All Designs';
  String? _selectedColor = 'All Colors';
  String? _selectedSize = 'All Sizes';

  // --- Responsive Size Helper ---
  // Scales a target size based on the current screen width relative to a large desktop width (1200px).
  double _responsiveSize(double desktopSize, double screenWidth) {
    const double referenceWidth = 1200.0;
    // Prevent sizes from becoming too small on very narrow screens by applying a minimum factor (0.4 = 40%).
    final scaleFactor = (screenWidth / referenceWidth).clamp(
      0.45,
      1.0,
    ); // Slightly increased min scale
    return desktopSize * scaleFactor;
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
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
      debugPrint('Initialization error: $e');
    }

    setState(() => _isAuthReady = true);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        // Reset filters when changing tabs
        _selectedDesign = 'All Designs';
        _selectedColor = 'All Colors';
        _selectedSize = 'All Sizes';
      });
    }
  }

  // --- Inventory Operations, Dialogs, and Helpers remain unchanged ---
  Future<void> _sellItem(String itemId, String model) async {
    setState(() => _sellingItems[itemId] = true);
    try {
      await _firebaseService.sellItem(itemId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sold one $model. Stock updated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sale failed: ${_parseError(e)}')),
        );
      }
    } finally {
      setState(() => _sellingItems.remove(itemId));
    }
  }

  String _parseError(dynamic e) {
    if (e is FirebaseException) return e.message ?? 'Firestore error';
    if (e is PlatformException) return e.message ?? 'Platform error';
    final error = e.toString();
    if (error.contains('out of stock')) return 'Item out of stock!';
    if (error.contains('Item not found')) return 'Item not found!';
    return error.split(':').last.trim();
  }

  void _logout(BuildContext context) {
    FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showSetStockDialog(String itemId, String model, int currentQuantity) {
    final controller = TextEditingController(text: currentQuantity.toString());
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Set Stock for $model',
          style: TextStyle(
            color: Colors.indigo.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter new total quantity:'),
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
                  Icons.inventory_2_outlined,
                  color: Colors.indigo.shade400,
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
              final quantity = int.tryParse(controller.text);
              if (quantity != null && quantity >= 0) {
                Navigator.pop(context);
                _updateStock(itemId, model, quantity);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Set Total'),
          ),
        ],
      ),
    );
  }

  void _showIncreaseStockDialog(String itemId, String model) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Increase Stock for $model',
          style: TextStyle(
            color: Colors.teal.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter quantity to add:'),
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
                  Icons.add_shopping_cart,
                  color: Colors.green.shade400,
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
              final quantity = int.tryParse(controller.text);
              if (quantity != null && quantity > 0) {
                Navigator.pop(context);
                _increaseStock(itemId, model, quantity);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStock(String itemId, String model, int quantity) async {
    try {
      await _firebaseService.updateStock(itemId, quantity);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$model stock set to $quantity')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${_parseError(e)}')),
        );
      }
    }
  }

  Future<void> _increaseStock(String itemId, String model, int quantity) async {
    try {
      await _firebaseService.increaseStock(itemId, quantity);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Added $quantity to $model')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Increase failed: ${_parseError(e)}')),
        );
      }
    }
  }
  // --- END Inventory Operations ---

  // --- Widget Builders ---

  Widget _buildLoadingScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    final loadingTextSize = _responsiveSize(16, screenWidth);
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.teal.shade600),
            SizedBox(height: _responsiveSize(20, screenWidth)),
            Text(
              'Initializing Secure Connection...',
              style: TextStyle(
                color: Colors.teal.shade800,
                fontSize: loadingTextSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final screenWidth = MediaQuery.of(context).size.width;
    // Increased base size from 24 to 26
    final drawerTitleSize = _responsiveSize(26, screenWidth);
    final listItemSize = _responsiveSize(18, screenWidth);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal.shade700),
            child: Text(
              'Relax Decor Tools',
              style: TextStyle(
                color: Colors.white,
                fontSize: drawerTitleSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Colors.redAccent,
              size: _responsiveSize(24, screenWidth),
            ),
            title: Text('Logout', style: TextStyle(fontSize: listItemSize)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStockStatusBar(bool isMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final paddingH = _responsiveSize(5, screenWidth);
    final paddingV = _responsiveSize(
      isMobile ? 14 : 20,
      screenWidth,
    ); // Increased vertical padding for space

    return Container(
      padding: EdgeInsets.symmetric(vertical: paddingV, horizontal: paddingH),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_responsiveSize(15, screenWidth)),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.2),
            blurRadius: _responsiveSize(10, screenWidth),
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
              screenWidth,
            ),
          ),
          Expanded(
            child: _buildStockItem(
              Icons.chair_alt,
              'Sofas',
              _firebaseService.streamTotalStock('Sofa'),
              Colors.indigo,
              isMobile,
              screenWidth,
            ),
          ),
          Expanded(
            child: _buildStockItem(
              Icons.restaurant,
              'Dining',
              _firebaseService.streamTotalStock('Dining Table'),
              Colors.orange,
              isMobile,
              screenWidth,
            ),
          ),
          Expanded(
            child: _buildStockItem(
              Icons.tv,
              'TV Tables',
              _firebaseService.streamTotalStock('TV Table'),
              Colors.purple,
              isMobile,
              screenWidth,
            ),
          ),
          Expanded(
            child: _buildStockItem(
              Icons.checkroom,
              'Wardrobes',
              _firebaseService.streamTotalStock('Wardrobe'),
              Colors.brown,
              isMobile,
              screenWidth,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockErrorItem(
    IconData icon,
    String label,
    bool isMobile,
    double screenWidth,
  ) {
    final iconSize = _responsiveSize(isMobile ? 18 : 24, screenWidth);
    final radius = _responsiveSize(isMobile ? 16 : 20, screenWidth);
    final countSize = _responsiveSize(
      isMobile ? 14 : 20,
      screenWidth,
    ); // Increased base size from 18 to 20
    final labelSize = _responsiveSize(isMobile ? 8 : 12, screenWidth);

    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.red.withOpacity(0.2),
          radius: radius,
          child: Icon(icon, color: Colors.red, size: iconSize),
        ),
        SizedBox(height: _responsiveSize(4, screenWidth)),
        Text(
          'ERR',
          style: TextStyle(
            fontSize: countSize,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: labelSize, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStockItem(
    IconData icon,
    String label,
    Stream<int> countStream,
    MaterialColor color,
    bool isMobile,
    double screenWidth,
  ) {
    final iconSize = _responsiveSize(isMobile ? 18 : 24, screenWidth);
    final radius = _responsiveSize(isMobile ? 16 : 20, screenWidth);
    // Increased base size from 18 to 20
    final countSize = _responsiveSize(isMobile ? 14 : 20, screenWidth);
    final labelSize = _responsiveSize(isMobile ? 8 : 12, screenWidth);
    final lowTagSize = _responsiveSize(6, screenWidth);

    return StreamBuilder<int>(
      stream: countStream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        final isLow = count <= _lowStockThreshold;
        final countColor = isLow ? Colors.red.shade700 : color.shade800;

        if (snapshot.hasError)
          return _buildStockErrorItem(icon, label, isMobile, screenWidth);

        return Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(isLow ? 0.2 : 0.1),
              radius: radius,
              child: Icon(icon, color: color, size: iconSize),
            ),
            SizedBox(height: _responsiveSize(4, screenWidth)),
            Text(
              '$count',
              style: TextStyle(
                fontSize: countSize,
                fontWeight: isLow ? FontWeight.w900 : FontWeight.bold,
                color: countColor,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: labelSize, color: Colors.grey),
            ),
            if (isLow)
              Text(
                'LOW',
                style: TextStyle(
                  fontSize: lowTagSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.red.shade700,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTabBar(bool isMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Increased base size from 14 to 16
    final fontSize = _responsiveSize(isMobile ? 14 : 16, screenWidth);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: _responsiveSize(3, screenWidth),
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(
          bottom: BorderSide(color: Colors.teal.shade100, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: isMobile,
        tabs: _tabs
            .map(
              (name) => Tab(
                child: Text(name, style: TextStyle(fontSize: fontSize)),
              ),
            )
            .toList(),
        labelColor: Colors.teal.shade800,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: Colors.teal.shade500,
        indicatorWeight: _responsiveSize(3, screenWidth),
      ),
    );
  }

  // --- FILTER ROW WIDGET ---
  Widget _buildFilterRow(String currentCategory, bool isMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = _responsiveSize(isMobile ? 12 : 20, screenWidth);
    final margin = _responsiveSize(isMobile ? 10 : 20, screenWidth);
    final titleSize = _responsiveSize(
      isMobile ? 16 : 18,
      screenWidth,
    ); // Increased base size from 16 to 18

    final filterWidgets = [
      _buildFilterDropdown(
        'Design',
        _selectedDesign,
        currentCategory,
        (v) => setState(() => _selectedDesign = v),
        isMobile,
        screenWidth,
      ),
      _buildFilterDropdown(
        'Size',
        _selectedSize,
        currentCategory,
        (v) => setState(() => _selectedSize = v),
        isMobile,
        screenWidth,
      ),
      _buildFilterDropdown(
        'Color',
        _selectedColor,
        currentCategory,
        (v) => setState(() => _selectedColor = v),
        isMobile,
        screenWidth,
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: _responsiveSize(14, screenWidth),
      ),
      margin: EdgeInsets.symmetric(
        horizontal: margin,
        vertical: _responsiveSize(8, screenWidth),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_responsiveSize(15, screenWidth)),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            blurRadius: _responsiveSize(10, screenWidth),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: _responsiveSize(12.0, screenWidth),
            ),
            child: Text(
              'Filter Inventory',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
          ),
          isMobile
              ? Column(
                  children:
                      filterWidgets
                          .expand(
                            (w) => [
                              w,
                              SizedBox(
                                height: _responsiveSize(10, screenWidth),
                              ),
                            ],
                          )
                          .toList()
                        ..removeLast(),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filterWidgets
                      .map(
                        (w) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: _responsiveSize(4.0, screenWidth),
                            ),
                            child: w,
                          ),
                        ),
                      )
                      .toList(),
                ),
        ],
      ),
    );
  }

  // --- FILTER DROPDOWN WIDGET ---
  Widget _buildFilterDropdown(
    String field,
    String? value,
    String category,
    ValueChanged<String?> onChanged,
    bool isMobile,
    double screenWidth,
  ) {
    final fontSize = _responsiveSize(
      isMobile ? 13 : 15,
      screenWidth,
    ); // Increased base size from 14 to 15
    final contentPadding = _responsiveSize(
      isMobile ? 12 : 14,
      screenWidth,
    ); // Increased content padding

    return StreamBuilder<List<String>>(
      stream: _firebaseService.streamDistinctValues(
        category,
        field.toLowerCase(),
      ),
      builder: (context, snapshot) {
        final items = snapshot.data ?? ['All ${field}s'];
        final firstItem = 'All ${field}s';
        if (!items.contains(firstItem)) {
          items.insert(0, firstItem);
        }
        final selectedValue = (value != null && items.contains(value))
            ? value
            : firstItem;

        return DropdownButtonFormField<String>(
          value: selectedValue,
          decoration: InputDecoration(
            labelText: field,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _responsiveSize(8, screenWidth),
              ),
              borderSide: BorderSide(color: Colors.teal.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _responsiveSize(8, screenWidth),
              ),
              borderSide: BorderSide(
                color: Colors.teal.shade600,
                width: _responsiveSize(2, screenWidth),
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: _responsiveSize(12, screenWidth),
              vertical: contentPadding,
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.teal.shade600,
            size: _responsiveSize(isMobile ? 22 : 26, screenWidth),
          ),
          items: items
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(v, style: TextStyle(fontSize: fontSize)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
  // --- END FILTER WIDGETS ---

  Widget _buildCategoryImageBanner(String category, bool isMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = _responsiveSize(isMobile ? 10 : 20, screenWidth);
    final bannerHeight = _responsiveSize(
      75,
      screenWidth,
    ); // Increased base height from 70
    final iconSize = _responsiveSize(
      35,
      screenWidth,
    ); // Increased base icon size from 30
    final fontSize = _responsiveSize(
      isMobile ? 18 : 22,
      screenWidth,
    ); // Increased base font size from 20
    final hSpace = _responsiveSize(15, screenWidth);

    final iconMap = {
      'Bed': Icons.bed,
      'Sofa': Icons.chair_alt,
      'Dining Table': Icons.restaurant,
      'TV Table': Icons.tv,
      'Wardrobe': Icons.checkroom,
    };
    final icon = iconMap[category] ?? Icons.category;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: _responsiveSize(10, screenWidth),
      ),
      child: Container(
        height: bannerHeight,
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: _responsiveSize(20, screenWidth),
        ),
        decoration: BoxDecoration(
          color: Colors.teal.shade100,
          borderRadius: BorderRadius.circular(_responsiveSize(15, screenWidth)),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.1),
              blurRadius: _responsiveSize(5, screenWidth),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: Colors.teal.shade800),
            SizedBox(width: hSpace),
            Text(
              '$category Collection',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(String category, bool isMobile) {
    final screenWidth = MediaQuery.of(context).size.width;

    return StreamBuilder<List<FurnitureItem>>(
      stream: _firebaseService.streamInventory(
        category,
        design: _selectedDesign,
        color: _selectedColor,
        size: _selectedSize,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );

        final items = snapshot.data ?? [];
        final itemCount = items.length + 2;

        if (items.isEmpty &&
            (_selectedDesign != 'All Designs' ||
                _selectedColor != 'All Colors' ||
                _selectedSize != 'All Sizes')) {
          return ListView(
            children: [
              _buildFilterRow(category, isMobile),
              _buildCategoryImageBanner(category, isMobile),
              Padding(
                padding: EdgeInsets.all(_responsiveSize(40.0, screenWidth)),
                child: Center(
                  child: Text(
                    'No $category items match current filters',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: _responsiveSize(16, screenWidth),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        if (items.isEmpty &&
            (_selectedDesign == 'All Designs' &&
                _selectedColor == 'All Colors' &&
                _selectedSize == 'All Sizes')) {
          return Center(
            child: Text(
              'No $category items in inventory',
              style: TextStyle(fontSize: _responsiveSize(16, screenWidth)),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(bottom: _responsiveSize(15, screenWidth)),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == 0) return _buildFilterRow(category, isMobile);
            if (index == 1)
              return _buildCategoryImageBanner(category, isMobile);

            final item = items[index - 2];
            return _FurnitureListItem(
              item: item,
              isLowStock: item.stock <= _lowStockThreshold,
              isSelling: _sellingItems[item.id] == true,
              onSell: () => _sellItem(item.id, item.model),
              onUpdateStock: () =>
                  _showSetStockDialog(item.id, item.model, item.stock),
              onIncreaseStock: () =>
                  _showIncreaseStockDialog(item.id, item.model),
              isMobile: isMobile,
              screenWidth: screenWidth, // Pass screen width for responsiveness
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthReady) return _buildLoadingScreen();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Increased base size from 22 to 24
    final appTitleSize = _responsiveSize(isMobile ? 20 : 24, screenWidth);
    final padding = _responsiveSize(
      isMobile ? 12 : 24,
      screenWidth,
    ); // Increased padding

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text('Real-Time Inventory Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal.shade800,
        elevation: 1,
        titleTextStyle: TextStyle(
          color: Colors.teal.shade900,
          fontSize: appTitleSize,
          fontWeight: FontWeight.w600,
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            _responsiveSize(52, screenWidth),
          ), // Increased height for larger tabs
          child: _buildTabBar(isMobile),
        ),
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(padding),
            child: _buildStockStatusBar(isMobile),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs
                  .map((category) => _buildTabContent(category, isMobile))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// Extracted Furniture List Item Widget (Refactored for full responsiveness)
class _FurnitureListItem extends StatelessWidget {
  final FurnitureItem item;
  final bool isLowStock;
  final bool isSelling;
  final VoidCallback onSell;
  final VoidCallback onUpdateStock;
  final VoidCallback onIncreaseStock;
  final bool isMobile;
  final double screenWidth; // Added screenWidth to maintain responsiveness

  const _FurnitureListItem({
    required this.item,
    required this.isLowStock,
    required this.isSelling,
    required this.onSell,
    required this.onUpdateStock,
    required this.onIncreaseStock,
    required this.isMobile,
    required this.screenWidth,
  });

  // Responsive Size Helper (Must be duplicated or passed, here we duplicate for simplicity)
  double _responsiveSize(double desktopSize, double screenWidth) {
    const double referenceWidth = 1200.0;
    final scaleFactor = (screenWidth / referenceWidth).clamp(
      0.45,
      1.0,
    ); // Using the same min scale
    return desktopSize * scaleFactor;
  }

  @override
  Widget build(BuildContext context) {
    final stockColor = isLowStock ? Colors.red.shade700 : Colors.teal.shade700;
    final hMargin = _responsiveSize(
      isMobile ? 12 : 24,
      screenWidth,
    ); // Increased horizontal margin
    final vMargin = _responsiveSize(
      8,
      screenWidth,
    ); // Increased vertical margin
    final tilePadding = _responsiveSize(
      isMobile ? 16 : 20,
      screenWidth,
    ); // Increased tile padding
    final titleSize = _responsiveSize(
      isMobile ? 18 : 20,
      screenWidth,
    ); // Increased base size from 18 to 20
    final subtitleSize = _responsiveSize(
      14,
      screenWidth,
    ); // Increased base size from 12 to 14

    return Card(
      elevation: _responsiveSize(4, screenWidth),
      margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: vMargin),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_responsiveSize(12, screenWidth)),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(
          horizontal: tilePadding,
          vertical: _responsiveSize(14, screenWidth),
        ),

        leading: _buildImagePlaceholder(),

        title: Text(
          item.model,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: titleSize),
        ),

        // Conditionally include subtitle (scaled)
        subtitle: isMobile
            ? null
            : Text(
                'Design: ${item.design ?? 'N/A'} | Color: ${item.color ?? 'N/A'} | Size: ${item.size ?? 'N/A'}',
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),

        trailing: isMobile
            ? _buildMobileTrailing(stockColor)
            : _buildDesktopTrailing(stockColor),

        children: [_buildExpansionContent()],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    final size = _responsiveSize(
      isMobile ? 45 : 55,
      screenWidth,
    ); // Increased size
    final iconSize = _responsiveSize(
      isMobile ? 28 : 35,
      screenWidth,
    ); // Increased icon size

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(_responsiveSize(8, screenWidth)),
      ),
      child: Icon(
        Icons.palette_outlined,
        size: iconSize,
        color: Colors.teal.shade400,
      ),
    );
  }

  // Responsive Trailing Widgets (uses scaled sizes)
  Widget _buildDesktopTrailing(Color stockColor) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildUpdateButton(),
      SizedBox(width: _responsiveSize(10, screenWidth)),
      _buildStockDisplay(stockColor),
      SizedBox(width: _responsiveSize(10, screenWidth)),
      _buildSellButton(stockColor),
    ],
  );

  // UPDATED: Now all elements are in a single horizontal row on mobile (Scaled)
  Widget _buildMobileTrailing(Color stockColor) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildStockDisplay(stockColor),
      SizedBox(width: _responsiveSize(8, screenWidth)),
      _buildUpdateButton(), // SET button
      SizedBox(width: _responsiveSize(8, screenWidth)),
      _buildSellButton(stockColor), // SELL button
    ],
  );

  // UPDATED: Scaled button size and padding
  Widget _buildUpdateButton() {
    final buttonHeight = _responsiveSize(
      32,
      screenWidth,
    ); // Increased base height from 28 to 32
    final buttonFontSize = _responsiveSize(
      isMobile ? 11 : 13,
      screenWidth,
    ); // Increased base font size from 11 to 13
    final hPadding = _responsiveSize(6, screenWidth); // Increased padding

    return SizedBox(
      height: buttonHeight,
      child: OutlinedButton(
        onPressed: onUpdateStock,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.indigo.shade700,
          side: BorderSide(
            color: Colors.indigo.shade400,
            width: _responsiveSize(1, screenWidth),
          ),
          padding: EdgeInsets.symmetric(horizontal: hPadding),
          minimumSize: Size(0, buttonHeight),
        ),
        child: Text(
          'SET',
          style: TextStyle(
            fontSize: buttonFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // UPDATED: Scaled button size and padding
  Widget _buildSellButton(Color color) {
    final buttonHeight = _responsiveSize(
      32,
      screenWidth,
    ); // Increased base height from 28 to 32
    final buttonFontSize = _responsiveSize(
      isMobile ? 11 : 13,
      screenWidth,
    ); // Increased base font size from 11 to 13
    final hPadding = _responsiveSize(6, screenWidth); // Increased padding
    final loadingSize = _responsiveSize(
      15,
      screenWidth,
    ); // Increased loading indicator size

    return SizedBox(
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: item.stock > 0 && !isSelling ? onSell : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLowStock
              ? Colors.red.shade600
              : Colors.teal.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: hPadding),
          minimumSize: Size(0, buttonHeight),
        ),
        child: isSelling
            ? SizedBox(
                width: loadingSize,
                height: loadingSize,
                child: CircularProgressIndicator(
                  strokeWidth: _responsiveSize(2, screenWidth),
                  color: Colors.white,
                ),
              )
            : Text(
                'SELL',
                style: TextStyle(
                  fontSize: buttonFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // Stock Display (Scaled)
  Widget _buildStockDisplay(Color color) {
    final fontSize = _responsiveSize(
      isMobile ? 12 : 16,
      screenWidth,
    ); // Increased base size from 14 to 16
    final hPadding = _responsiveSize(8, screenWidth); // Increased padding
    final vPadding = _responsiveSize(4, screenWidth); // Increased padding
    final radius = _responsiveSize(isLowStock ? 8 : 6, screenWidth);

    return Container(
      padding: EdgeInsets.symmetric(vertical: vPadding, horizontal: hPadding),
      decoration: BoxDecoration(
        color: isLowStock ? const Color(0xFFFFCDD2) : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isLowStock ? Colors.red.shade900 : color,
          width: _responsiveSize(1, screenWidth),
        ),
      ),
      child: Text(
        item.stock.toString(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }

  // Expansion Content (Scaled)
  Widget _buildExpansionContent() {
    final padding = _responsiveSize(18, screenWidth); // Increased padding
    final titleSize = _responsiveSize(16, screenWidth); // Increased title size
    final subtitleSize = _responsiveSize(
      12,
      screenWidth,
    ); // Increased subtitle size
    final buttonVPad = _responsiveSize(
      14,
      screenWidth,
    ); // Increased button padding
    final buttonIconSize = _responsiveSize(
      20,
      screenWidth,
    ); // Increased icon size

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: _responsiveSize(18, screenWidth)),
          Text(
            'Inventory Management',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
              fontSize: titleSize,
            ),
          ),
          SizedBox(height: _responsiveSize(12, screenWidth)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(_responsiveSize(14, screenWidth)),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(
                _responsiveSize(10, screenWidth),
              ),
              border: Border.all(
                color: Colors.teal.shade200,
                width: _responsiveSize(1, screenWidth),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade900,
                    fontSize: titleSize,
                  ),
                ),
                SizedBox(height: _responsiveSize(12, screenWidth)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onIncreaseStock,
                    icon: Icon(Icons.add_business, size: buttonIconSize),
                    label: Text(
                      'Receive New Shipment',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: titleSize,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: buttonVPad),
                    ),
                  ),
                ),
                SizedBox(height: _responsiveSize(10, screenWidth)),
                Text(
                  'Use the "SET" button above to set the exact total quantity of stock on hand, or use "Receive New Shipment" to add to existing stock.',
                  style: TextStyle(
                    fontSize: subtitleSize,
                    color: Colors.grey.shade600,
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
