import 'dart:async';

import 'package:get/get.dart';
import 'package:planly_ai/app/services/sync_service.dart';
import 'package:planly_ai/app/utils/show_snack_bar.dart';
import 'package:planly_ai/main.dart';

class SyncController extends GetxController {
  static const Duration syncInterval = Duration(minutes: 1);

  final SyncService _syncService = SyncService();
  final isSyncing = false.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _timer = Timer.periodic(syncInterval, (_) => syncPending());
    Future.microtask(syncPending);
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> syncPending({bool showResult = false}) async {
    if (isSyncing.value) return;

    isSyncing.value = true;
    try {
      if (!settings.isLoggedIn) {
        if (showResult) {
          showSnackBar('loginToSync'.tr, isInfo: true);
        }
        return;
      }

      final hadPending = await _syncService.pendingCount() > 0;
      final success = await _syncService.syncPending();

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
    }
  }
}
