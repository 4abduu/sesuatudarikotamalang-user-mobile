import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/creator_application_model.dart';

class ApplicationsProvider extends ChangeNotifier {
  List<CreatorApplicationModel> _apps = [];
  static const _key = 'sdkm-user-applications';

  List<CreatorApplicationModel> get applications => List.unmodifiable(_apps);

  Future<void> init() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _apps = list.map((j) => CreatorApplicationModel.fromJson(j as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> addApplication(CreatorApplicationModel app) async {
    _apps = [app, ..._apps];
    notifyListeners();
    await _persist();
  }

  CreatorApplicationModel? latestForUser(String userId) {
    final userApps = _apps.where((a) => a.userId == userId).toList();
    if (userApps.isEmpty) return null;
    userApps.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return userApps.first;
  }

  /// Updates the status of an existing application. Used by the
  /// "[Demo] Simulasikan Hasil Kurasi" affordance on the application
  /// status screen. Optionally persists a [rejectReason] when status
  /// is [ApplicationStatus.rejected].
  Future<void> updateStatus(String id, ApplicationStatus status, {String? rejectReason}) async {
    final idx = _apps.indexWhere((a) => a.id == id);
    if (idx < 0) return;
    final a = _apps[idx];
    _apps[idx] = CreatorApplicationModel(
      id: a.id, userId: a.userId, applicantName: a.applicantName,
      contact: a.contact, email: a.email, brandName: a.brandName,
      description: a.description, category: a.category,
      submittedAt: a.submittedAt, status: status,
      rejectReason: status == ApplicationStatus.rejected ? (rejectReason ?? a.rejectReason) : null,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(_apps.map((a) => a.toJson()).toList()));
  }
}
