import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/visitor.dart';
import '../providers/visitor_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_view.dart';
import 'visitor_form_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onNavigate});

  /// Switches the bottom-navigation tab (0 dashboard, 1 visitors, 2 scan).
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VisitorProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Visitor Management')),
      body: SafeArea(
        child: Builder(builder: (context) {
          if (!provider.hasLoaded && provider.isLoading) {
            return const LoadingView(message: 'Loading visitors...');
          }
          if (!provider.hasLoaded && provider.error != null) {
            return EmptyStateWidget(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load data',
              message: provider.error,
              actionLabel: 'Retry',
              onAction: provider.loadVisitors,
            );
          }
          return RefreshIndicator(
            onRefresh: provider.loadVisitors,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (provider.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MaterialBanner(
                      content: Text(provider.error!),
                      leading: const Icon(Icons.warning_amber_rounded),
                      actions: [
                        TextButton(onPressed: provider.loadVisitors, child: const Text('Retry')),
                      ],
                    ),
                  ),
                DashboardStatCard(
                  title: 'Total Visitors Today',
                  value: provider.totalToday,
                  icon: Icons.groups_outlined,
                  color: const Color(0xFF1E88E5),
                ),
                const SizedBox(height: 12),
                DashboardStatCard(
                  title: 'Currently Checked In',
                  value: provider.currentlyCheckedIn,
                  icon: Icons.login,
                  color: const Color(0xFF2E7D32),
                ),
                const SizedBox(height: 12),
                DashboardStatCard(
                  title: 'Checked Out Today',
                  value: provider.checkedOutToday,
                  icon: Icons.logout,
                  color: const Color(0xFF757575),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Register Visitor',
                  icon: Icons.person_add_alt_1,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VisitorFormScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  label: 'Scan QR Code',
                  icon: Icons.qr_code_scanner,
                  style: CustomButtonStyle.outlined,
                  onPressed: () => onNavigate(2),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  label: 'Visitor List',
                  icon: Icons.list_alt,
                  style: CustomButtonStyle.outlined,
                  onPressed: () => onNavigate(1),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
