import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/enquiry_model.dart';
import 'widgets/contact_actions_row.dart';
import '../../services/launcher.dart';

class EnquiriesListScreen extends StatefulWidget {
  const EnquiriesListScreen({super.key});
  @override
  State<EnquiriesListScreen> createState() => _EnquiriesListScreenState();
}

class _EnquiriesListScreenState extends State<EnquiriesListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final statuses = EnquiryStatus.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: statuses.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enquiries'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [for (final s in statuses) Tab(text: s.name)],
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/enquiries/new'),
            icon: const Icon(Icons.add),
            label: const Text('Add Enquiry'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [for (final s in statuses) _StatusTab(status: s)],
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  final EnquiryStatus status;
  const _StatusTab({required this.status});

  Color _getStatusColor(EnquiryStatus status) {
    switch (status) {
      case EnquiryStatus.enquired:
        return Colors.grey;
      case EnquiryStatus.inTalks:
        return Colors.amber;
      case EnquiryStatus.confirmed:
        return Colors.blue;
      case EnquiryStatus.completed:
        return Colors.green;
      case EnquiryStatus.notInterested:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mock data for demo
    final mockEnquiries = [
      {
        'id': '1',
        'customerName': 'John Doe',
        'customerPhone': '+919876543210',
        'eventTypeLabel': 'Wedding',
        'eventDate': DateTime.now().add(const Duration(days: 30)),
        'locationText': 'Mumbai, India',
        'status': EnquiryStatus.enquired,
      },
      {
        'id': '2',
        'customerName': 'Jane Smith',
        'customerPhone': '+919876543211',
        'eventTypeLabel': 'Birthday Party',
        'eventDate': DateTime.now().add(const Duration(days: 15)),
        'locationText': 'Delhi, India',
        'status': EnquiryStatus.inTalks,
      },
      {
        'id': '3',
        'customerName': 'Mike Johnson',
        'customerPhone': '+919876543212',
        'eventTypeLabel': 'Corporate Event',
        'eventDate': DateTime.now().add(const Duration(days: 45)),
        'locationText': 'Bangalore, India',
        'status': EnquiryStatus.confirmed,
      },
    ];

    // Filter enquiries by status
    final filteredEnquiries = mockEnquiries.where((e) => e['status'] == status).toList();

    if (filteredEnquiries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${status.name} enquiries',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New enquiries will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredEnquiries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final d = filteredEnquiries[i];
        final name = d['customerName'] as String;
        final phone = d['customerPhone'] as String;
        final event = d['eventTypeLabel'] as String;
        final when = d['eventDate'] as DateTime;
        final location = d['locationText'] as String;
        final enquiryStatus = d['status'] as EnquiryStatus;
        
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.go('/enquiries/${d['id']}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              event,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(
                          enquiryStatus.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: _getStatusColor(enquiryStatus).withOpacity(0.1),
                        side: BorderSide(
                          color: _getStatusColor(enquiryStatus).withOpacity(0.3),
                        ),
                        labelStyle: TextStyle(
                          color: _getStatusColor(enquiryStatus),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(when),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => ContactLauncher.call(phone),
                        icon: const Icon(Icons.phone),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green.withOpacity(0.1),
                          foregroundColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => ContactLauncher.whatsapp(
                          phone,
                          message: 'Hi $name! Regarding your $event enquiry.',
                        ),
                        icon: const Icon(Icons.message),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green.withOpacity(0.1),
                          foregroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 0) {
      return 'In $difference days';
    } else {
      return '${-difference} days ago';
    }
  }
}
