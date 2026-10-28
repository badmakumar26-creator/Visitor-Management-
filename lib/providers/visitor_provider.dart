import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../models/visitor.dart';
import '../services/visitor_api_service.dart';

/// Single source of truth for visitor data. Screens listen to this provider, so a
/// check-in in the details screen instantly updates the list and dashboard.
class VisitorProvider extends ChangeNotifier {
  VisitorProvider(this._api);

  final VisitorApiService _api;

  List<Visitor> _visitors = [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  String _query = '';
  final Set<String> _busyIds = {};

  // ---- state ----
  List<Visitor> get visitors => List.unmodifiable(_visitors);
  bool get isLoading => _loading;
  bool get hasLoaded => _loaded;
  String? get error => _error;
  String get query => _query;
  bool isBusy(String id) => _busyIds.contains(id);

  /// Search by name or mobile number (local filtering). Newest first.
  List<Visitor> get filteredVisitors {
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty
        ? [..._visitors]
        : _visitors
            .where((v) => v.name.toLowerCase().contains(q) || v.mobile.contains(q))
            .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // ---- dashboard stats (device local date) ----
  static bool _isToday(DateTime? dt) {
    if (dt == null) return false;
    final l = dt.toLocal();
    final n = DateTime.now();
    return l.year == n.year && l.month == n.month && l.day == n.day;
  }

  int get totalToday => _visitors.where((v) => _isToday(v.createdAt)).length;
  int get currentlyCheckedIn =>
      _visitors.where((v) => v.status == VisitorStatus.checkedIn).length;
  int get checkedOutToday => _visitors
      .where((v) => v.status == VisitorStatus.checkedOut && _isToday(v.checkOutTime))
      .length;

  Visitor? byId(String id) {
    for (final v in _visitors) {
      if (v.id == id) return v;
    }
    return null;
  }

  // ---- actions ----
  Future<void> loadVisitors({bool silent = false}) async {
    if (_loading) return;
    _loading = true;
    if (!silent) _error = null;
    notifyListeners();
    try {
      _visitors = await _api.fetchVisitors();
      _error = null;
      _loaded = true;
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Something went wrong while loading visitors.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  /// Fetches a fresh copy from the API (used by the QR scanner) and syncs local state.
  Future<Visitor> fetchById(String id) async {
    final visitor = await _api.fetchVisitor(id);
    _upsert(visitor);
    return visitor;
  }

  Future<Visitor> registerVisitor({
    required String name,
    required String mobile,
    String? email,
    required String visitorType,
    required String project,
    required String purpose,
  }) async {
    final draft = Visitor(
      id: '',
      name: name.trim(),
      mobile: mobile.trim(),
      email: (email == null || email.trim().isEmpty) ? null : email.trim(),
      visitorType: visitorType,
      project: project,
      purpose: purpose.trim(),
      status: VisitorStatus.registered,
      createdAt: DateTime.now(),
    );
    final created = await _api.createVisitor(draft);
    _upsert(created);
    return created;
  }

  Future<Visitor> updateVisitor(
    Visitor original, {
    required String name,
    required String mobile,
    String? email,
    required String visitorType,
    required String project,
    required String purpose,
  }) async {
    final hasEmail = email != null && email.trim().isNotEmpty;
    final updated = original.copyWith(
      name: name.trim(),
      mobile: mobile.trim(),
      email: hasEmail ? email.trim() : null,
      clearEmail: !hasEmail,
      visitorType: visitorType,
      project: project,
      purpose: purpose.trim(),
    );
    final saved = await _api.updateVisitor(updated);
    _upsert(saved);
    return saved;
  }

  Future<void> deleteVisitor(String id) async {
    await _api.deleteVisitor(id);
    _visitors.removeWhere((v) => v.id == id);
    notifyListeners();
  }

  Future<Visitor> checkIn(String id) => _changeStatus(id, VisitorStatus.checkedIn);
  Future<Visitor> checkOut(String id) => _changeStatus(id, VisitorStatus.checkedOut);

  /// Enforces the workflow against the latest server copy, and blocks double taps
  /// / repeated scanner callbacks via [_busyIds].
  Future<Visitor> _changeStatus(String id, VisitorStatus target) async {
    if (_busyIds.contains(id)) {
      throw const BusinessRuleException('Another action is already in progress.');
    }
    _busyIds.add(id);
    notifyListeners();
    try {
      final current = await _api.fetchVisitor(id);
      if (target == VisitorStatus.checkedIn) {
        if (current.status == VisitorStatus.checkedIn) {
          throw const BusinessRuleException('Visitor is already checked in.');
        }
        if (current.status == VisitorStatus.checkedOut) {
          throw const BusinessRuleException('This visit is completed. Cannot check in again.');
        }
      } else {
        if (current.status == VisitorStatus.registered) {
          throw const BusinessRuleException('Visitor has not checked in yet.');
        }
        if (current.status == VisitorStatus.checkedOut) {
          throw const BusinessRuleException('Visitor is already checked out.');
        }
      }
      final now = DateTime.now();
      final next = target == VisitorStatus.checkedIn
          ? current.copyWith(status: target, checkInTime: now)
          : current.copyWith(status: target, checkOutTime: now);
      final saved = await _api.updateVisitor(next);
      _upsert(saved);
      return saved;
    } catch (e) {
      // Keep local state in sync if the server copy differs from what we show.
      if (e is BusinessRuleException) {
        loadVisitors(silent: true);
      }
      rethrow;
    } finally {
      _busyIds.remove(id);
      notifyListeners();
    }
  }

  void _upsert(Visitor visitor) {
    final index = _visitors.indexWhere((v) => v.id == visitor.id);
    if (index >= 0) {
      _visitors[index] = visitor;
    } else {
      _visitors.add(visitor);
    }
    notifyListeners();
  }
}
