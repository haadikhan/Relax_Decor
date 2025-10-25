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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Sale'),
          content: Text(
            'Are you sure you want to sell $_quantity ${widget.item.model}(s) for €${totalPrice.toStringAsFixed(0)}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _sellItem(); // Proceed with sale
              },
              child: const Text('Yes'),
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

        Navigator.pop(context); // Return to previous screen
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell Item'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Details Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.model,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Category: ${widget.item.category}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    if (widget.item.design != null)
                      Text(
                        'Design: ${widget.item.design}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    if (widget.item.color != null)
                      Text(
                        'Color: ${widget.item.color}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    if (widget.item.size != null)
                      Text(
                        'Size: ${widget.item.size}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Stock: ${widget.item.stock}',
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.item.stock > 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Price: €${widget.item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Quantity Selection
            const Text(
              'Quantity to Sell:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _quantity < widget.item.stock
                      ? () => setState(() => _quantity++)
                      : null,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                const Spacer(),
                Text(
                  'Max: ${widget.item.stock}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Total Price
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '€${totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    '$_quantity × €${widget.item.price.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Sell Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: widget.item.stock > 0 && !_isSelling
                    ? _showConfirmationDialog // Changed from _sellItem to _showConfirmationDialog
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSelling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'CONFIRM SALE',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
