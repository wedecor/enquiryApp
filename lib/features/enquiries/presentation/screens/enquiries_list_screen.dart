import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:we_decor_enquiries/core/providers/role_provider.dart';
import 'package:we_decor_enquiries/shared/models/user_model.dart';
import 'package:we_decor_enquiries/features/enquiries/presentation/screens/enquiry_details_screen.dart';
import 'package:we_decor_enquiries/features/enquiries/presentation/screens/enquiry_form_screen.dart';

class EnquiriesListScreen extends ConsumerWidget {
  const EnquiriesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserWithFirestoreProvider);
    final userRole = currentUser.value?.role;

    return Scaffold(
      appBar: AppBar(
        title: Text(userRole == UserRole.admin ? 'All Enquiries' : 'My Enquiries'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).pushNamed('/enquiry-form');
            },
            tooltip: 'Add New Enquiry',
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Please log in to view enquiries'),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _getEnquiriesStream(userRole, user.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        userRole == UserRole.admin ? Icons.inbox : Icons.assignment,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userRole == UserRole.admin 
                            ? 'No enquiries found' 
                            : 'No enquiries assigned to you',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final enquiries = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: enquiries.length,
                itemBuilder: (context, index) {
                  final enquiry = enquiries[index];
                  final enquiryData = enquiry.data() as Map<String, dynamic>;
                  final enquiryId = enquiry.id;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(enquiryData['eventStatus'] as String?),
                        child: Text(
                          _getStatusInitial(enquiryData['eventStatus'] as String?),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        (enquiryData['customerName'] as String?) ?? 'Unknown Customer',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((enquiryData['eventType'] as String?) ?? 'Unknown Event'),
                          Text(
                            'Date: ${_formatDate(enquiryData['eventDate'])}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (userRole == UserRole.admin && enquiryData['assignedTo'] != null) ...[
                            Text(
                              'Assigned: ${_getAssignedUserName(enquiryData['assignedTo'] as String)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(enquiryData['priority'] as String?),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _capitalizeFirst((enquiryData['priority'] as String?) ?? 'N/A'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Edit button for admin users
                          if (userRole == UserRole.admin) ...[
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () {
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (context) => EnquiryFormScreen(
                                      enquiryId: enquiryId,
                                      mode: 'edit',
                                    ),
                                  ),
                                );
                              },
                              tooltip: 'Edit Enquiry',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 4),
                          ],
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (context) => EnquiryDetailsScreen(
                              enquiryId: enquiryId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading user data: $error'),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getEnquiriesStream(UserRole? userRole, String? currentUserId) {
    if (userRole == UserRole.admin) {
      // Admin sees all enquiries
      return FirebaseFirestore.instance
          .collection('enquiries')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      // Staff only sees assigned enquiries
      return FirebaseFirestore.instance
          .collection('enquiries')
          .where('assignedTo', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      return '${date.toDate().day}/${date.toDate().month}/${date.toDate().year}';
    }
    return date.toString();
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _getStatusInitial(String? status) {
    if (status == null) return '?';
    return status[0].toUpperCase();
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getAssignedUserName(String? assignedTo) {
    if (assignedTo == null) return 'Unassigned';
    // TODO: Fetch user name from Firestore
    return 'User ID: $assignedTo';
  }
} 