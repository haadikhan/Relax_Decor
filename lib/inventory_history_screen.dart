// import 'package:flutter/material.dart';
// import 'package:inventory_system/firebase/firebase_service.dart';
// import 'package:intl/intl.dart';

// class InventoryHistoryScreen extends StatelessWidget {
//   final FirebaseService firebaseService;

//   const InventoryHistoryScreen({super.key, required this.firebaseService});

//   @override
//   Widget build(BuildContext context) {
//     final isMobile = MediaQuery.of(context).size.width < 600;

//     return Scaffold(
//       backgroundColor: Colors.teal.shade50,
//       appBar: AppBar(
//         title: const Text('Inventory History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.teal.shade800,
//         elevation: 1,
//       ),
//       body: StreamBuilder<List<InventoryAction>>(
//         stream: firebaseService.streamInventoryActions(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
//           }

//           final actions = snapshot.data ?? [];

//           if (actions.isEmpty) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.history, size: 80, color: Colors.grey.shade400),
//                   const SizedBox(height: 16),
//                   Text('No inventory actions yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
//                 ],
//               ),
//             );
//           }

//           return ListView.builder(
//             padding: EdgeInsets.all(isMobile ? 12 : 24),
//             itemCount: actions.length,
//             itemBuilder: (context, index) {
//               final action = actions[index];
//               return _buildActionCard(action, isMobile);
//             },
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildActionCard(InventoryAction action, bool isMobile) {
//     final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    
//     Color actionColor;
//     IconData actionIcon;
//     String actionText;
    
//     switch (action.actionType) {
//       case 'increase':
//         actionColor = Colors.green;
//         actionIcon = Icons.add_circle;
//         actionText = 'Added Stock';
//         break;
//       case 'update':
//         actionColor = Colors.blue;
//         actionIcon = Icons.edit;
//         actionText = 'Updated Stock';
//         break;
//       default:
//         actionColor = Colors.orange;
//         actionIcon = Icons.inventory;
//         actionText = 'Stock Change';
//     }

//     return Card(
//       margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: EdgeInsets.all(isMobile ? 14 : 18),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: actionColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(actionIcon, color: actionColor, size: isMobile ? 20 : 24),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         action.model,
//                         style: TextStyle(
//                           fontSize: isMobile ? 16 : 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.teal.shade900,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         '${action.category} • ${action.design}',
//                         style: TextStyle(fontSize: isMobile ? 12 : 14, color: Colors.grey.shade600),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const Divider(height: 24),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildInfoChip('Previous', '${action.previousStock}', Colors.grey, isMobile),
//                 ),
//                 const SizedBox(width: 8),
//                 Icon(Icons.arrow_forward, color: Colors.grey.shade400, size: 20),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: _buildInfoChip('New', '${action.newStock}', Colors.teal, isMobile),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: _buildInfoChip(
//                     'Change',
//                     '${action.quantityChanged > 0 ? '+' : ''}${action.quantityChanged}',
//                     action.quantityChanged > 0 ? Colors.green : Colors.red,
//                     isMobile,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Icon(Icons.person, size: isMobile ? 14 : 16, color: Colors.grey.shade600),
//                 const SizedBox(width: 6),
//                 Expanded(
//                   child: Text(
//                     action.userEmail,
//                     style: TextStyle(fontSize: isMobile ? 12 : 14, color: Colors.grey.shade700),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 6),
//             Row(
//               children: [
//                 Icon(Icons.access_time, size: isMobile ? 14 : 16, color: Colors.grey.shade600),
//                 const SizedBox(width: 6),
//                 Text(
//                   dateFormat.format(action.timestamp),
//                   style: TextStyle(fontSize: isMobile ? 12 : 14, color: Colors.grey.shade700),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoChip(String label, String value, Color color, bool isMobile) {
//     return Container(
//       padding: EdgeInsets.symmetric(vertical: isMobile ? 6 : 8, horizontal: isMobile ? 8 : 12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         children: [
//           Text(
//             label,
//             style: TextStyle(fontSize: isMobile ? 10 : 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             value,
//             style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold, color: color),
//           ),
//         ],
//       ),
//     );
//   }
// }
