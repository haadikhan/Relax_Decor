import 'package:flutter/material.dart';
import 'package:inventory_system/firebase/firebase_service.dart';
import 'package:intl/intl.dart';

class SalesReportScreen extends StatefulWidget {
  final FirebaseService firebaseService;

  const SalesReportScreen({super.key, required this.firebaseService});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final year = _selectedDate.year;
    final month = _selectedDate.month;
    final monthName = DateFormat('MMMM yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Date and Category Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Month:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          monthName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_drop_down),
                          onPressed: _showDatePicker,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.category, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Category:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        DropdownButton<String>(
                          value: _selectedCategory,
                          items: const [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text('All Categories'),
                            ),
                            DropdownMenuItem(value: 'Bed', child: Text('Beds')),
                            DropdownMenuItem(
                              value: 'Sofa',
                              child: Text('Sofas'),
                            ),
                            DropdownMenuItem(
                              value: 'Dining Table',
                              child: Text('Dining Tables'),
                            ),
                            DropdownMenuItem(
                              value: 'TV Table',
                              child: Text('TV Tables'),
                            ),
                            DropdownMenuItem(
                              value: 'Wardrobe',
                              child: Text('Wardrobes'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedCategory = value!);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sales Summary
          Expanded(
            child: _selectedCategory == 'All'
                ? _buildAllCategoriesReport(year, month)
                : _buildCategoryReport(_selectedCategory, year, month),
          ),
        ],
      ),
    );
  }

  Widget _buildAllCategoriesReport(int year, int month) {
    return StreamBuilder<List<MonthlySalesSummary>>(
      stream: widget.firebaseService.getMonthlySalesSummary(year, month),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final summaries = snapshot.data ?? [];
        final totalRevenue = summaries.fold(
          0.0,
          (sum, s) => sum + s.totalRevenue,
        );
        final totalItems = summaries.fold(
          0,
          (sum, s) => sum + s.totalItemsSold,
        );

        return Column(
          children: [
            // Total Summary Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Colors.teal.shade50,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'TOTAL MONTHLY SALES',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem(
                            'Total Revenue',
                            '€${totalRevenue.toStringAsFixed(0)}',
                            Icons.euro,
                            Colors.green,
                          ),
                          _buildSummaryItem(
                            'Items Sold',
                            totalItems.toString(),
                            Icons.shopping_cart,
                            Colors.blue,
                          ),
                          _buildSummaryItem(
                            'Categories',
                            summaries.length.toString(),
                            Icons.category,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Sales by Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            // Category Breakdown
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: summaries.length,
                itemBuilder: (context, index) {
                  final summary = summaries[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(summary.category),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getCategoryIcon(summary.category),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        summary.category,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${summary.totalItemsSold} items sold'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '€${summary.totalRevenue.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${((summary.totalRevenue / totalRevenue) * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryReport(String category, int year, int month) {
    return StreamBuilder<List<SalesRecord>>(
      stream: widget.firebaseService.getCategoryMonthlySales(
        category,
        year,
        month,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final sales = snapshot.data ?? [];
        final totalRevenue = sales.fold(0.0, (sum, s) => sum + s.totalAmount);
        final totalItems = sales.fold(0, (sum, s) => sum + s.quantity);

        return Column(
          children: [
            // Category Summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: _getCategoryColor(category).withOpacity(0.1),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(category),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getCategoryIcon(category),
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$category Sales',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem(
                            'Total Revenue',
                            '€${totalRevenue.toStringAsFixed(0)}',
                            Icons.euro,
                            Colors.green,
                          ),
                          _buildSummaryItem(
                            'Items Sold',
                            totalItems.toString(),
                            Icons.shopping_cart,
                            Colors.blue,
                          ),
                          _buildSummaryItem(
                            'Transactions',
                            sales.length.toString(),
                            Icons.receipt,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Sales Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            // Sales List
            Expanded(
              child: sales.isEmpty
                  ? const Center(
                      child: Text(
                        'No sales recorded for this category',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: sales.length,
                      itemBuilder: (context, index) {
                        final sale = sales[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shopping_bag,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              sale.model,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (sale.design != null)
                                  Text('Design: ${sale.design}'),
                                if (sale.color != null)
                                  Text('Color: ${sale.color}'),
                                Text(
                                  'Qty: ${sale.quantity} × €${sale.price.toStringAsFixed(0)}',
                                ),
                                Text(
                                  DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(sale.saleDate),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              '€${sale.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Bed':
        return Colors.teal;
      case 'Sofa':
        return Colors.indigo;
      case 'Dining Table':
        return Colors.orange;
      case 'TV Table':
        return Colors.purple;
      case 'Wardrobe':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Bed':
        return Icons.bed;
      case 'Sofa':
        return Icons.chair_alt;
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

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }
}
