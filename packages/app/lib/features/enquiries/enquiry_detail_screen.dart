import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/enquiry_model.dart';
import '../../services/launcher.dart';

class EnquiryDetailScreen extends StatelessWidget {
  final String id;
  const EnquiryDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    // Mock data for demo
    final mockData = {
      'customerName': 'John Doe',
      'customerPhone': '+919876543210',
      'customerEmail': 'john.doe@example.com',
      'eventTypeLabel': 'Wedding',
      'eventDate': DateTime.now().add(const Duration(days: 30)),
      'locationText': 'Mumbai, India',
      'status': EnquiryStatus.confirmed,
      'assignedTo': 'Staff Member',
      'assignedToUid': 'staff123',
      'createdAt': DateTime.now().subtract(const Duration(days: 5)),
      'updatedAt': DateTime.now().subtract(const Duration(hours: 2)),
      'payment': {
        'totalAmount': 50000,
        'advanceAmount': 15000,
        'balance': 35000,
        'confirmedAt': DateTime.now().subtract(const Duration(hours: 2)),
      },
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enquiry Details'),
        actions: [
          IconButton(
            onPressed: () => context.go('/enquiries/$id/edit'),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
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
                              mockData['customerName'] as String,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mockData['eventTypeLabel'] as String,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(
                          (mockData['status'] as EnquiryStatus).name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: _getStatusColor(mockData['status'] as EnquiryStatus).withOpacity(0.1),
                        side: BorderSide(
                          color: _getStatusColor(mockData['status'] as EnquiryStatus).withOpacity(0.3),
                        ),
                        labelStyle: TextStyle(
                          color: _getStatusColor(mockData['status'] as EnquiryStatus),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => ContactLauncher.call(mockData['customerPhone'] as String),
                        icon: const Icon(Icons.phone),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green.withOpacity(0.1),
                          foregroundColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => ContactLauncher.whatsapp(
                          mockData['customerPhone'] as String,
                          message: 'Hi ${mockData['customerName']}! Regarding your ${mockData['eventTypeLabel']} enquiry.',
                        ),
                        icon: const Icon(Icons.message),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green.withOpacity(0.1),
                          foregroundColor: Colors.green,
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => context.go('/enquiries/$id/edit'),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Customer Information
          _SectionCard(
            title: 'Customer Information',
            icon: Icons.person,
            children: [
              _InfoRow(
                label: 'Name',
                value: mockData['customerName'] as String,
              ),
              _InfoRow(
                label: 'Phone',
                value: mockData['customerPhone'] as String,
                action: IconButton(
                  onPressed: () => ContactLauncher.call(mockData['customerPhone'] as String),
                  icon: const Icon(Icons.phone, size: 18),
                ),
              ),
              _InfoRow(
                label: 'Email',
                value: mockData['customerEmail'] as String,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Event Information
          _SectionCard(
            title: 'Event Information',
            icon: Icons.event,
            children: [
              _InfoRow(
                label: 'Event Type',
                value: mockData['eventTypeLabel'] as String,
              ),
              _InfoRow(
                label: 'Event Date',
                value: _formatDate(mockData['eventDate'] as DateTime),
              ),
              _InfoRow(
                label: 'Location',
                value: mockData['locationText'] as String,
              ),
              _InfoRow(
                label: 'Assigned To',
                value: mockData['assignedTo'] as String,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Payment Information
          _SectionCard(
            title: 'Payment Information',
            icon: Icons.payments,
            children: [
              _InfoRow(
                label: 'Total Amount',
                value: '₹${(mockData['payment'] as Map)['totalAmount']}',
                valueStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              _InfoRow(
                label: 'Advance Paid',
                value: '₹${(mockData['payment'] as Map)['advanceAmount']}',
              ),
              _InfoRow(
                label: 'Balance Due',
                value: '₹${(mockData['payment'] as Map)['balance']}',
                valueStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
              if ((mockData['payment'] as Map)['confirmedAt'] != null)
                _InfoRow(
                  label: 'Confirmed At',
                  value: _formatDateTime((mockData['payment'] as Map)['confirmedAt'] as DateTime),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Timeline
          _SectionCard(
            title: 'Timeline',
            icon: Icons.timeline,
            children: [
              _TimelineStepper(id: id),
            ],
          ),
        ],
      ),
    );
  }

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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final Widget? action;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueStyle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            action!,
          ],
        ],
      ),
    );
  }
}

class _TimelineStepper extends StatelessWidget {
  final String id;
  const _TimelineStepper({required this.id});

  @override
  Widget build(BuildContext context) {
    // Mock timeline data
    final timelineEvents = [
      {
        'type': 'created',
        'title': 'Enquiry Created',
        'description': 'New enquiry submitted by customer',
        'timestamp': DateTime.now().subtract(const Duration(days: 5)),
        'icon': Icons.add_circle,
        'color': Colors.blue,
      },
      {
        'type': 'assigned',
        'title': 'Assigned to Staff',
        'description': 'Enquiry assigned to Staff Member',
        'timestamp': DateTime.now().subtract(const Duration(days: 3)),
        'icon': Icons.person_add,
        'color': Colors.orange,
      },
      {
        'type': 'confirmed',
        'title': 'Enquiry Confirmed',
        'description': 'Payment details confirmed and advance received',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'icon': Icons.check_circle,
        'color': Colors.green,
      },
    ];

    return Column(
      children: timelineEvents.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;
        final isLast = index == timelineEvents.length - 1;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (event['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (event['color'] as Color).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    event['icon'] as IconData,
                    color: event['color'] as Color,
                    size: 20,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title'] as String,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event['description'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(event['timestamp'] as DateTime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
