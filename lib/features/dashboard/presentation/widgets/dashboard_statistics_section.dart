import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../../ui/components/stats_card.dart';
import 'dashboard_kpi_row.dart';

/// Dashboard KPI statistics row backed by a Firestore enquiries stream.
class DashboardStatisticsSection extends ConsumerWidget {
  const DashboardStatisticsSection({
    super.key,
    required this.isAdmin,
    required this.userId,
  });

  final bool isAdmin;
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: ref
          .read(firestoreServiceProvider)
          .watchEnquiriesForRole(isAdmin: isAdmin, assignedToUid: userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading statistics');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final enquiries = snapshot.data?.docs ?? [];

        final totalEnquiries = enquiries.length;
        final newEnquiries = enquiries.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['statusValue'] as String?)?.toLowerCase() == 'new';
        }).length;
        final inProgressEnquiries = enquiries.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['statusValue'] as String?)?.toLowerCase() == 'in_talks';
        }).length;
        final confirmedEnquiries = enquiries.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['statusValue'] as String?)?.toLowerCase() == 'confirmed';
        }).length;
        final completedEnquiries = enquiries.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['statusValue'] as String?)?.toLowerCase() == 'completed';
        }).length;

        final cards = [
          StatsCard(
            icon: Icons.inbox_outlined,
            value: totalEnquiries.toString(),
            label: 'Total enquiries',
          ),
          StatsCard(icon: Icons.fiber_new, value: newEnquiries.toString(), label: 'New'),
          StatsCard(
            icon: Icons.handshake_outlined,
            value: inProgressEnquiries.toString(),
            label: 'In talks',
          ),
          StatsCard(
            icon: Icons.check_circle_outline,
            value: confirmedEnquiries.toString(),
            label: 'Confirmed',
          ),
          StatsCard(
            icon: Icons.verified_outlined,
            value: completedEnquiries.toString(),
            label: 'Completed',
          ),
        ];

        return DashboardKpiRow(items: cards);
      },
    );
  }
}
