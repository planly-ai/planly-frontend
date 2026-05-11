import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:planly_ai/app/services/sync_service.dart';
import 'package:planly_ai/app/utils/show_snack_bar.dart';
import 'package:planly_ai/main.dart';

class SyncController extends GetxController with WidgetsBindingObserver {
  static const Duration syncInterval = Duration(minutes: 1);
  static const Duration enqueueSyncDelay = Duration(milliseconds: 1500);

  final SyncService _syncService = SyncService();
  final Connectivity _connectivity = Connectivity();
  final isSyncing = false.obs;

  Timer? _timer;
  Timer? _enqueueDebounce;
  StreamSubscription<void>? _queueChangeSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _rerunAfterCurrent = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _queueChangeSubscription = SyncService.queueChanges.listen((_) {
      scheduleSync();
    });
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChanged,
    );
    _timer = Timer.periodic(syncInterval, (_) => syncPending());
    Future.microtask(syncPending);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _enqueueDebounce?.cancel();
    _timer?.cancel();
    _queueChangeSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      scheduleSync(delay: Duration.zero);
    }
  }

  void scheduleSync({Duration delay = enqueueSyncDelay}) {
    _enqueueDebounce?.cancel();
    _enqueueDebounce = Timer(delay, () {
      syncPending();
    });
  }

  Future<void> syncPending({
    bool showResult = false,
    bool force = false,
  }) async {
    if (isSyncing.value) {
      if (!showResult) {
        _rerunAfterCurrent = true;
      }
      return;
    }

    isSyncing.value = true;
    try {
      if (!settings.isLoggedIn) {
        if (showResult) {
          showSnackBar('loginToSync'.tr, isInfo: true);
        }
        return;
      }

      final hadPending = await _syncService.pendingCount() > 0;
      final success = await _syncService.syncPending(force: force);

      if (!showResult) return;

      if (!hadPending) {
        showSnackBar('syncNoPending'.tr, isInfo: true);
      } else if (success) {
        showSnackBar('syncSuccess'.tr);
      } else {
        showSnackBar('syncFailed'.tr, isError: true);
      }
    } finally {
      isSyncing.value = false;
      if (_rerunAfterCurrent) {
        _rerunAfterCurrent = false;
        scheduleSync(delay: Duration.zero);
      }
    }
  }

  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    if (results.any((result) => result != ConnectivityResult.none)) {
      scheduleSync(delay: Duration.zero);
    }
  }
}
