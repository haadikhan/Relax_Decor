import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_system/firebase/firebase_service.dart';
import 'package:inventory_system/login_screen.dart';

// The FurnitureItem class is now defined in lib/firebase/firebase_service.dart
// and is accessible via the import above.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Initialize with 'late' and set in initState
  late FirebaseService _firebaseService;

  final List<String> tabs = [
    'Bed',
    'Sofa',
    'Dining Table',
    'TV Table',
    'Wardrobe',
  ];
  // --- LOW STOCK THRESHOLD SET TO 5 ---
  final int _lowStockThreshold = 5;

  // Filter state variables
  String? _selectedDesign;
  String? _selectedColor;
  String? _selectedSize;

  // NEW: State to manage Firebase/Auth readiness
  bool _isAuthReady = false;

  // NEW: Tracks which item is currently being sold to display loading indicator
  // The map is Map<String, bool> where key is item ID and value is true if selling.
  // FIX: Making the map nullable (Map<String, bool>?) and initializing it defensively in _sellItem
  // to avoid the persistent "type 'Null' is not a subtype of type 'Map<String, bool>'" error.
  Map<String, bool>? _sellingItems;

  // MANDATORY: Authentication and Initialization Logic
  Future<void> _initializeAppAndAuth() async {
    // 1. Setup App ID
    final String appId = (const String.fromEnvironment('__app_id').isEmpty
        ? 'default-app-id'
        : const String.fromEnvironment('__app_id'));
    _firebaseService = FirebaseService(appId: appId);

    try {
      // 2. Auth Check: We must sign in to satisfy the 'if request.auth != null' security rule.
      final auth = FirebaseAuth.instance;

      // We only attempt sign-in if no user is currently authenticated.
      if (auth.currentUser == null) {
        debugPrint('Authentication required. Attempting sign-in...');

        // Use the global custom token provided by the environment
        const initialAuthToken = String.fromEnvironment('__initial_auth_token');
        if (initialAuthToken.isNotEmpty) {
          await auth.signInWithCustomToken(initialAuthToken);
          debugPrint('Signed in with custom token.');
        } else {
          // Fallback to anonymous sign-in if the token is not available
          await auth.signInAnonymously();
          debugPrint('Signed in anonymously.');
        }
      } else {
        debugPrint('Already signed in as: ${auth.currentUser!.uid}');
      }

      // 3. Seed Data (MUST run after successful authentication)
      // This will now run with proper authentication and should succeed if rules are correct.
      await _firebaseService.seedInventoryIfEmpty();

      setState(() {
        _isAuthReady = true; // Set flag to true to display the main UI
      });
    } catch (e) {
      debugPrint(
        'FATAL AUTH/INIT ERROR. Check your Firebase initialization or network: $e',
      );
      setState(() {
        _isAuthReady =
            true; // Still set to true so the list stream can display the error
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize the map here too, just in case, now that it's nullable.
    _sellingItems = {};

    _initializeAppAndAuth();

    _tabController = TabController(length: tabs.length, vsync: this);

    // Set initial filter values to 'All'
    _selectedDesign = 'All Designs';
    _selectedColor = 'All Colors';
    _selectedSize = 'All Sizes';

    // Listen for tab changes to reset filters
    _tabController.addListener(() {
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

  // --- Inventory Management Functions ---

  // ENHANCED ERROR HANDLING FOR TRANSACTION FAILURE
  void _sellItem(String itemId, String model) async {
    // Defensive check: Ensure the map is initialized before use
    if (_sellingItems == null) {
      _sellingItems = {};
    }

    // 1. Start loading state
    setState(() {
      _sellingItems![itemId] = true; // Using ! since we checked for null above
    });

    String errorMessage = 'Transaction Failed. Check Console/Permissions.';
    try {
      await _firebaseService.sellItem(itemId);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sold one $model. Stock updated in Firestore.')),
      );
    } catch (e) {
      // 1. Log the full error object to the console for detailed debugging
      debugPrint('Sell Item Error (Full Object): $e');

      if (e is FirebaseException) {
        errorMessage =
            e.message ?? 'Firestore Error: Check security rules or network.';
      } else if (e is PlatformException) {
        errorMessage = e.message ?? 'Platform Error: Check connection.';
      } else if (e.toString().contains('out of stock')) {
        errorMessage = 'Item is out of stock!';
      } else if (e.toString().contains('Item not found')) {
        errorMessage = 'Item not found!';
      } else {
        final errorParts = e.toString().split(':');
        if (errorParts.length > 2) {
          errorMessage = errorParts.sublist(1).join(':').trim();
        } else {
          errorMessage = e.toString();
        }
      }

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sale failed: ${errorMessage.trim()}')),
      );
    } finally {
      // 2. Stop loading state, regardless of success or failure
      setState(() {
        _sellingItems!.remove(
          itemId,
        ); // Using ! since we checked for null above
      });
    }
  }

  void _updateStock(String itemId, String model, int newQuantity) async {
    try {
      await _firebaseService.updateStock(itemId, newQuantity);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock for $model set to $newQuantity.')),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Update failed: ${e.toString().split(':').last.trim()}',
          ),
        ),
      );
    }
  }

  void _increaseStock(String itemId, String model, int increaseAmount) async {
    try {
      await _firebaseService.increaseStock(itemId, increaseAmount);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$increaseAmount units added to $model. Stock updated.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Increase failed: ${e.toString().split(':').last.trim()}',
          ),
        ),
      );
    }
  }

  void _logout(BuildContext context) {
    FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // --- Dialogs ---

  /// **NEW: Dialog to collect the absolute quantity for manual correction.**
  void _showSetStockDialog(String itemId, String model, int currentQuantity) {
    // Controller initialized with current quantity for easy editing
    final TextEditingController amountController = TextEditingController(
      text: currentQuantity.toString(),
    );
    // Move cursor to the end
    amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: amountController.text.length),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Set Total Stock for $model',
            style: TextStyle(
              color: Colors.indigo.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the new, definitive total quantity for this item.',
              ),
              const SizedBox(height: 15),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'New Total Quantity',
                  hintText: 'e.g., 50',
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
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newQuantity = int.tryParse(amountController.text);
                if (newQuantity != null && newQuantity >= 0) {
                  Navigator.pop(context);
                  _updateStock(
                    itemId,
                    model,
                    newQuantity,
                  ); // Calls the absolute stock set logic
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid non-negative number.',
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Set Total'),
            ),
          ],
        );
      },
    );
  }

  /// Dialog to collect the quantity of new stock arriving (INCREMENT).
  void _showIncreaseStockDialog(String itemId, String model) {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
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
              const Text(
                'Enter the quantity of new stock arriving to be ADDED.',
              ),
              const SizedBox(height: 15),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Quantity to Add',
                  hintText: 'e.g., 20',
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
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final increaseAmount = int.tryParse(amountController.text);
                if (increaseAmount != null && increaseAmount > 0) {
                  Navigator.pop(context);
                  _increaseStock(itemId, model, increaseAmount);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid positive number.'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Add Stock'),
            ),
          ],
        );
      },
    );
  }

  // --- Filter and UI Builders ---

  Widget _buildFilterDropdown({
    required String fieldName,
    required String? selectedValue,
    required Function(String?) onChanged,
    required String categoryName,
  }) {
    // The field name used in Firestore documents (e.g., 'design', 'color', 'size')
    final String firestoreFieldName = fieldName.toLowerCase();

    return StreamBuilder<List<String>>(
      // Fetch dynamic options based on the currently selected category
      stream: _firebaseService.streamDistinctValues(
        categoryName,
        firestoreFieldName,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: fieldName,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: const [],
            onChanged: null,
            hint: const Text('Loading...'),
          );
        }

        // Handle stream errors (e.g., permission denied)
        if (snapshot.hasError) {
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: fieldName,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: const [],
            onChanged: null,
            hint: Text(
              'Error: ${snapshot.error.toString().split(']')[1].trim()}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final List<String> items = snapshot.data ?? ['All ${fieldName}s'];

        final String effectiveSelectedValue =
            (selectedValue != null && items.contains(selectedValue))
            ? selectedValue
            : items.first;

        return DropdownButtonFormField<String>(
          value: effectiveSelectedValue,
          decoration: InputDecoration(
            labelText: fieldName,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.teal.shade200),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        );
      },
    );
  }

  // Widget to build the row of filter dropdowns
  Widget _buildFilterRow(String currentCategory) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildFilterDropdown(
              fieldName: 'Design',
              selectedValue: _selectedDesign,
              categoryName: currentCategory,
              onChanged: (newValue) {
                setState(() {
                  _selectedDesign = newValue;
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildFilterDropdown(
              fieldName: 'Size',
              selectedValue: _selectedSize,
              categoryName: currentCategory,
              onChanged: (newValue) {
                setState(() {
                  _selectedSize = newValue;
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildFilterDropdown(
              fieldName: 'Color',
              selectedValue: _selectedColor,
              categoryName: currentCategory,
              onChanged: (newValue) {
                setState(() {
                  _selectedColor = newValue;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockStatusBar() {
    final totalBeds = _firebaseService.streamTotalStock('Bed');
    final totalSofas = _firebaseService.streamTotalStock('Sofa');
    final totalDiningTables = _firebaseService.streamTotalStock('Dining Table');
    final totalTVTables = _firebaseService.streamTotalStock('TV Table');
    final totalWardrobes = _firebaseService.streamTotalStock('Wardrobe');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 5.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildStockItem(Icons.bed, 'Beds', totalBeds, Colors.teal),
          ),
          Expanded(
            child: _buildStockItem(
              Icons.chair_alt,
              'Sofas',
              totalSofas,
              Colors.indigo,
            ),
          ),
          Expanded(
            child: _buildStockItem(
              Icons.restaurant,
              'Dining Tables',
              totalDiningTables,
              Colors.orange,
            ),
          ),
          Expanded(
            child: _buildStockItem(
              Icons.tv,
              'TV Tables',
              totalTVTables,
              Colors.purple,
            ),
          ),
          Expanded(
            child: _buildStockItem(
              Icons.checkroom,
              'Wardrobes',
              totalWardrobes,
              Colors.brown,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockItem(
    IconData icon,
    String label,
    Stream<int> countStream,
    MaterialColor color,
  ) {
    return StreamBuilder<int>(
      stream: countStream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        // Uses the new low stock threshold
        final bool isLow = count <= _lowStockThreshold;
        final Color countColor = isLow ? Colors.red.shade700 : color.shade800;

        // Handle stream errors (e.g., permission denied)
        if (snapshot.hasError) {
          return Column(
            children: [
              CircleAvatar(
                // ignore: deprecated_member_use
                backgroundColor: Colors.red.withOpacity(0.2),
                child: Icon(icon, color: Colors.red, size: 24),
              ),
              const SizedBox(height: 4),
              const Text(
                'AUTH',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'FAIL',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(isLow ? 0.2 : 0.1),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: isLow ? FontWeight.w900 : FontWeight.bold,
                color: countColor,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (isLow)
              Text(
                'LOW',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: Colors.red.shade700,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFurnitureList(String categoryName, List<FurnitureItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Text('No $categoryName items match the selected filters.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isLowStock = item.stock <= _lowStockThreshold;
        final Color stockColor = isLowStock
            ? Colors.red.shade700
            : Colors.teal.shade700;

        // FIX: Safely check the loading state using null-aware access.
        // If _sellingItems is null, this evaluates to null, and null == true evaluates to false (safe).
        final bool isSelling = _sellingItems?[item.id] == true;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,

          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            title: Text(
              item.model,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
                fontSize: 16.0,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price Display
                Text(
                  'Price: \$${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                // Detailed Attributes (Color, Design, Size)
                Text(
                  'Design: ${item.design ?? 'N/A'} | Color: ${item.color ?? 'N/A'} | Size: ${item.size ?? 'N/A'}',
                  style: TextStyle(fontSize: 12.0, color: Colors.grey.shade500),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- UPDATE Stock Button (Set Absolute Quantity) ---
                SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () =>
                        _showSetStockDialog(item.id, item.model, item.stock),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo.shade700,
                      side: BorderSide(
                        color: Colors.indigo.shade400,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'UPDATE STOCK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Total Quantity Display
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isLowStock
                        ? const Color.fromRGBO(255, 205, 210, 1)
                        : stockColor.withOpacity(0.15),
                    borderRadius: isLowStock
                        ? BorderRadius.circular(10)
                        : BorderRadius.circular(8),
                    border: Border.all(
                      color: isLowStock ? Colors.red.shade900 : stockColor,
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    item.stock.toString(),
                    style: TextStyle(
                      color: stockColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Sell Button (Decrement by 1)
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    // Disable button if stock is zero or a sale is in progress
                    onPressed: item.stock > 0 && !isSelling
                        ? () => _sellItem(item.id, item.model)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLowStock
                          ? Colors.red.shade600
                          : Colors.teal.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // --- Visual Feedback: Circular progress indicator when selling ---
                    child: isSelling
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                              backgroundColor: Colors.white.withOpacity(0.3),
                            ),
                          )
                        : const Text(
                            'SELL',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    // --- End Visual Feedback ---
                  ),
                ),
              ],
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  top: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Inventory Arrival (Atomic Increment) SECTION ---
                    Divider(color: Colors.grey.shade300, height: 16),
                    Text(
                      'Inventory Arrival (Atomic Increment)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // INCREASE STOCK BUTTON - calls the dialog
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showIncreaseStockDialog(item.id, item.model),
                        icon: const Icon(Icons.inventory_2_outlined, size: 18),
                        label: const Text(
                          'New Inventory Truck Arrived? Click to Increase Quantity',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
      },
    );
  }

  // Wrapper for the List Builder using a StreamBuilder
  Widget _buildTabContent(String categoryName) {
    return StreamBuilder<List<FurnitureItem>>(
      stream: _firebaseService.streamInventory(
        categoryName,
        design: _selectedDesign,
        color: _selectedColor,
        size: _selectedSize,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // Display the permission error clearly
          return Center(
            child: Text(
              'Error loading data: ${snapshot.error.toString().split(']')[0].trim()}] \nAuthentication Failed. Please refresh after ensuring security rules are correct.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        final List<FurnitureItem> items = snapshot.data ?? [];
        return _buildFurnitureList(categoryName, items);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading screen until authentication and initial seeding are complete
    if (!_isAuthReady) {
      return Scaffold(
        backgroundColor: Colors.teal.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.teal.shade600),
              const SizedBox(height: 20),
              Text(
                'Initializing Secure Connection to Firestore...',
                style: TextStyle(color: Colors.teal.shade800, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Get the name of the currently selected tab
    final String currentCategory = tabs[_tabController.index];

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text('Real-Time Inventory Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal.shade800,
        elevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.teal.shade900,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal.shade700),
              child: const Text(
                'Relax Decor Tools',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                _logout(context);
              },
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening Add New Furniture dialog...'),
            ),
          );
        },
        label: const Text(
          'Add Furniture',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        elevation: 6,
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 20.0,
              left: 20.0,
              right: 20.0,
              bottom: 10.0,
            ),
            child: _buildStockStatusBar(),
          ),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border(
                bottom: BorderSide(color: Colors.teal.shade100, width: 1.0),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: tabs.map((name) => Tab(text: name)).toList(),
              labelColor: Colors.teal.shade800,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.teal.shade500,
              indicatorWeight: 3.5,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // The new three-filter row is here, placed right below the tabs
          _buildFilterRow(currentCategory),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: tabs.map((tabName) {
                return _buildTabContent(tabName);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
