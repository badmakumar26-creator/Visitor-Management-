import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_exception.dart';
import '../models/visitor.dart';
import '../providers/visitor_provider.dart';
import '../widgets/app_feedback.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_view.dart';
import '../widgets/visitor_card.dart';
import 'visitor_details_screen.dart';
import 'visitor_form_screen.dart';

class VisitorListScreen extends StatelessWidget {
  const VisitorListScreen({super.key});

  Future<void> _delete(BuildContext context, Visitor visitor) async {
    final provider = context.read<VisitorProvider>();
    final ok = await confirmDelete(context, visitor.name);
    if (!ok || !context.mounted) return;
    try {
      await provider.deleteVisitor(visitor.id);
      if (context.mounted) showAppSnackBar(context, 'Visitor deleted');
    } on AppException catch (e) {
      if (context.mounted) showAppSnackBar(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VisitorProvider>();
    final visitors = provider.filteredVisitors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitors'),
        actions: [
          IconButton(
            tooltip: 'Register visitor',
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VisitorFormScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                onChanged: provider.setQuery,
                decoration: InputDecoration(
                  hintText: 'Search by name or mobile',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: provider.query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => provider.setQuery(''),
                        ),
                ),
              ),
            ),
            Expanded(child: _body(context, provider, visitors)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, VisitorProvider provider, List<Visitor> visitors) {
    if (!provider.hasLoaded && provider.isLoading) {
      return const LoadingView(message: 'Loading visitors...');
    }
    if (!provider.hasLoaded && provider.error != null) {
      return EmptyStateWidget(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load visitors',
        message: provider.error,
        actionLabel: 'Retry',
        onAction: provider.loadVisitors,
      );
    }
    return RefreshIndicator(
      onRefresh: provider.loadVisitors,
      child: visitors.isEmpty
          ? EmptyStateWidget(
              icon: Icons.people_outline,
              title: provider.query.isEmpty ? 'No visitors yet' : 'No matching visitors',
              message: provider.query.isEmpty
                  ? 'Register your first visitor to get started.'
                  : 'Try a different name or mobile number.',
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: visitors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final v = visitors[index];
                return VisitorCard(
                  visitor: v,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => VisitorDetailsScreen(visitorId: v.id)),
                  ),
                  onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => VisitorFormScreen(visitor: v)),
                  ),
                  onDelete: () => _delete(context, v),
                );
              },
            ),
    );
  }
}
