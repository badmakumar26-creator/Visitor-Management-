import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/app_exception.dart';
import '../models/visitor.dart';
import '../providers/visitor_provider.dart';
import '../widgets/app_feedback.dart';
import '../widgets/custom_button.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/status_chip.dart';
import 'visitor_form_screen.dart';

/// Shows a visitor's profile, QR code and check-in / check-out actions.
/// It watches the provider by id, so status changes made anywhere show up here.
class VisitorDetailsScreen extends StatelessWidget {
  const VisitorDetailsScreen({super.key, required this.visitorId});

  final String visitorId;

  static final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  Future<void> _run(
    BuildContext context,
    Future<Visitor> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (context.mounted) showAppSnackBar(context, successMessage);
    } on AppException catch (e) {
      if (context.mounted) showAppSnackBar(context, e.message, error: true);
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, 'Action failed. Please try again.', error: true);
      }
    }
  }

  Future<void> _delete(BuildContext context, Visitor visitor) async {
    final provider = context.read<VisitorProvider>();
    final navigator = Navigator.of(context);
    final ok = await confirmDelete(context, visitor.name);
    if (!ok || !context.mounted) return;
    try {
      await provider.deleteVisitor(visitor.id);
      navigator.pop();
    } on AppException catch (e) {
      if (context.mounted) showAppSnackBar(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VisitorProvider>();
    final visitor = provider.byId(visitorId);

    if (visitor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visitor Details')),
        body: const EmptyStateWidget(
          icon: Icons.person_off_outlined,
          title: 'Visitor not found',
          message: 'This record may have been deleted.',
        ),
      );
    }

    final busy = provider.isBusy(visitor.id);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Details'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VisitorFormScreen(visitor: visitor)),
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, visitor),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            visitor.name,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        StatusChip(status: visitor.status),
                      ],
                    ),
                    const Divider(height: 24),
                    _row(context, Icons.tag, 'Visitor ID', visitor.id),
                    _row(context, Icons.phone_outlined, 'Mobile', visitor.mobile),
                    _row(context, Icons.email_outlined, 'Email', visitor.email ?? '—'),
                    _row(context, Icons.badge_outlined, 'Type', visitor.visitorType),
                    _row(context, Icons.apartment_outlined, 'Project', visitor.project),
                    _row(context, Icons.assignment_outlined, 'Purpose', visitor.purpose),
                    _row(context, Icons.event_outlined, 'Registered',
                        _dateFormat.format(visitor.createdAt)),
                    if (visitor.checkInTime != null)
                      _row(context, Icons.login, 'Checked in',
                          _dateFormat.format(visitor.checkInTime!)),
                    if (visitor.checkOutTime != null)
                      _row(context, Icons.logout, 'Checked out',
                          _dateFormat.format(visitor.checkOutTime!)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Visitor QR Code', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: QrImageView(
                        data: visitor.id,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      visitor.id,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _actionButton(context, visitor, busy),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, Visitor visitor, bool busy) {
    final provider = context.read<VisitorProvider>();
    if (visitor.canCheckIn) {
      return CustomButton(
        label: 'Check In',
        icon: Icons.login,
        loading: busy,
        color: const Color(0xFF2E7D32),
        onPressed: () => _run(
          context,
          () => provider.checkIn(visitor.id),
          '${visitor.name} checked in',
        ),
      );
    }
    if (visitor.canCheckOut) {
      return CustomButton(
        label: 'Check Out',
        icon: Icons.logout,
        loading: busy,
        color: const Color(0xFFEF6C00),
        onPressed: () => _run(
          context,
          () => provider.checkOut(visitor.id),
          '${visitor.name} checked out',
        ),
      );
    }
    return const CustomButton(
      label: 'Visit Completed',
      icon: Icons.check_circle_outline,
      onPressed: null,
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: muted),
          const SizedBox(width: 10),
          SizedBox(width: 92, child: Text(label, style: TextStyle(color: muted))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
