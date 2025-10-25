import 'package:flutter/material.dart';
import 'package:inventory_system/firebase/firebase_service.dart';

class StockHistoryScreen extends StatefulWidget {
  final FirebaseService firebaseService;

  const StockHistoryScreen({super.key, required this.firebaseService});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Update History'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<StockUpdateRecord>>(
        stream: widget.firebaseService.getStockUpdates(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading stock history: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final updates = snapshot.data ?? [];

          if (updates.isEmpty) {
            return const Center(
              child: Text(
                'No stock updates found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: updates.length,
            itemBuilder: (context, index) {
              final update = updates[index];
              return _buildUpdateCard(update);
            },
          );
        },
      ),
    );
  }

  Widget _buildUpdateCard(StockUpdateRecord update) {
    final isIncrease = update.updateType == 'increase';
    final changeColor = isIncrease ? Colors.green : Colors.orange;
    final changeIcon = isIncrease ? Icons.add : Icons.edit;
    final changeText = isIncrease ? 'Added' : 'Set to';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with item info
            Row(
              children: [
                Icon(
                  _getCategoryIcon(update.category),
                  color: Colors.teal,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        update.model,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${update.design ?? ''} • ${update.color ?? ''} • ${update.size ?? ''}'
                            .replaceAll(' •  • ', ' • ')
                            .trim(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Stock change information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: changeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: changeColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(changeIcon, color: changeColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$changeText ${update.changeAmount.abs()} items',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: changeColor,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'From ${update.previousStock} to ${update.newStock}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Footer with user and timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Updated by: ${update.updatedBy}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(update.updatedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
