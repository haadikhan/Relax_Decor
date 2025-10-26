import 'package:flutter/material.dart';
import 'package:inventory_system/firebase/firebase_service.dart';

class SalesScreen extends StatefulWidget {
  final FurnitureItem item;
  final FirebaseService firebaseService;

  const SalesScreen({
    super.key,
    required this.item,
    required this.firebaseService,
  });

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  int _quantity = 1;
  bool _isSelling = false;

  void _showConfirmationDialog() {
    final totalPrice = _quantity * widget.item.price;
    final isMobile = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Confirm Sale',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to sell $_quantity ${widget.item.model}(s) for €${totalPrice.toStringAsFixed(0)}?',
            style: TextStyle(fontSize: isMobile ? 14 : 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No', style: TextStyle(fontSize: isMobile ? 14 : 16)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sellItem();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Yes',
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
            ),
          ],
        );
      },
    );
  }

  void _sellItem() async {
    if (_quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    if (_quantity > widget.item.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only ${widget.item.stock} items available')),
      );
      return;
    }

    setState(() => _isSelling = true);

    try {
      await widget.firebaseService.sellItem(
        widget.item.id,
        _quantity,
        widget.item,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sold $_quantity ${widget.item.model}(s) for €${(_quantity * widget.item.price).toStringAsFixed(0)}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sale failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _quantity * widget.item.price;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    // Responsive padding
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 32.0 : 48.0);
    final verticalPadding = isMobile ? 16.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sell Item',
          style: TextStyle(fontSize: isMobile ? 18 : 22),
        ),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // For larger screens, center content with max width
            final maxWidth = isMobile ? double.infinity : 800.0;

            return Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Item Details Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.item.model,
                                style: TextStyle(
                                  fontSize: isMobile ? 18 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                              SizedBox(height: isMobile ? 8 : 12),

                              // Details in a responsive grid
                              if (isMobile)
                                // Mobile: Single column
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailRow(
                                      'Category',
                                      widget.item.category,
                                      isMobile,
                                    ),
                                    if (widget.item.design != null)
                                      _buildDetailRow(
                                        'Design',
                                        widget.item.design!,
                                        isMobile,
                                      ),
                                    if (widget.item.color != null)
                                      _buildDetailRow(
                                        'Color',
                                        widget.item.color!,
                                        isMobile,
                                      ),
                                    if (widget.item.size != null)
                                      _buildDetailRow(
                                        'Size',
                                        widget.item.size!,
                                        isMobile,
                                      ),
                                  ],
                                )
                              else
                                // Tablet/Desktop: Two columns
                                Wrap(
                                  spacing: 24,
                                  runSpacing: 8,
                                  children: [
                                    _buildDetailRow(
                                      'Category',
                                      widget.item.category,
                                      isMobile,
                                    ),
                                    if (widget.item.design != null)
                                      _buildDetailRow(
                                        'Design',
                                        widget.item.design!,
                                        isMobile,
                                      ),
                                    if (widget.item.color != null)
                                      _buildDetailRow(
                                        'Color',
                                        widget.item.color!,
                                        isMobile,
                                      ),
                                    if (widget.item.size != null)
                                      _buildDetailRow(
                                        'Size',
                                        widget.item.size!,
                                        isMobile,
                                      ),
                                  ],
                                ),

                              SizedBox(height: isMobile ? 12 : 16),
                              const Divider(),
                              SizedBox(height: isMobile ? 8 : 12),

                              // Stock and Price Row - Responsive
                              Wrap(
                                spacing: 16,
                                runSpacing: 12,
                                alignment: WrapAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.item.stock > 0
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: widget.item.stock > 0
                                            ? Colors.green.shade200
                                            : Colors.red.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.inventory_2,
                                          size: isMobile ? 18 : 20,
                                          color: widget.item.stock > 0
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Stock: ${widget.item.stock}',
                                          style: TextStyle(
                                            fontSize: isMobile ? 14 : 16,
                                            color: widget.item.stock > 0
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.blue.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.euro,
                                          size: isMobile ? 18 : 20,
                                          color: Colors.green.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '€${widget.item.price.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: isMobile ? 16 : 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: isMobile ? 24 : 32),

                      // Quantity Selection
                      Text(
                        'Quantity to Sell:',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),

                      Container(
                        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Decrease Button
                            Container(
                              width: isMobile ? 44 : 56,
                              height: isMobile ? 44 : 56,
                              decoration: BoxDecoration(
                                color: _quantity > 1
                                    ? Colors.teal.shade600
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                                icon: Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                  size: isMobile ? 20 : 24,
                                ),
                              ),
                            ),

                            SizedBox(width: isMobile ? 24 : 32),

                            // Quantity Display
                            Container(
                              constraints: BoxConstraints(
                                minWidth: isMobile ? 60 : 80,
                              ),
                              child: Text(
                                '$_quantity',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 32 : 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                            ),

                            SizedBox(width: isMobile ? 24 : 32),

                            // Increase Button
                            Container(
                              width: isMobile ? 44 : 56,
                              height: isMobile ? 44 : 56,
                              decoration: BoxDecoration(
                                color: _quantity < widget.item.stock
                                    ? Colors.teal.shade600
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: _quantity < widget.item.stock
                                    ? () => setState(() => _quantity++)
                                    : null,
                                icon: Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: isMobile ? 20 : 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isMobile ? 8 : 12),

                      // Max quantity hint
                      Center(
                        child: Text(
                          'Maximum: ${widget.item.stock}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                      ),

                      SizedBox(height: isMobile ? 24 : 32),

                      // Total Price Card
                      Container(
                        padding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.blue.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart,
                                  color: Colors.blue.shade700,
                                  size: isMobile ? 20 : 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isMobile ? 12 : 16),
                            Text(
                              '€${totalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: isMobile ? 36 : 44,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: isMobile ? 4 : 8),
                            Text(
                              '$_quantity × €${widget.item.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isMobile ? 32 : 40),

                      // Sell Button
                      SizedBox(
                        height: isMobile ? 54 : 64,
                        child: ElevatedButton(
                          onPressed: widget.item.stock > 0 && !_isSelling
                              ? _showConfirmationDialog
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: _isSelling
                              ? SizedBox(
                                  width: isMobile ? 20 : 24,
                                  height: isMobile ? 20 : 24,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: isMobile ? 20 : 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'CONFIRM SALE',
                                      style: TextStyle(
                                        fontSize: isMobile ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      // Bottom spacing for better scrolling
                      SizedBox(height: isMobile ? 24 : 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isMobile ? 13 : 15,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: isMobile ? 13 : 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
