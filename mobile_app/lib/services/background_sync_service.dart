import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Background sync configuration and tasks
class BackgroundSyncService {
  static const String syncTaskName = 'syncProductionData';
  static const String notificationCheckTask = 'checkNotifications';
  
  /// Initialize WorkManager for background tasks
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to false in production
    );
    
    print('✅ Background sync service initialized');
  }
  
  /// Register periodic sync task (runs every 15 minutes)
  static Future<void> registerPeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      syncTaskName,
      syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
    );
    
    print('✅ Periodic sync task registered (every 15 minutes)');
  }
  
  /// Register notification check task (runs every 30 minutes)
  static Future<void> registerNotificationCheck() async {
    await Workmanager().registerPeriodicTask(
      notificationCheckTask,
      notificationCheckTask,
      frequency: const Duration(minutes: 30),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    
    print('✅ Notification check task registered (every 30 minutes)');
  }
  
  /// Cancel all background tasks
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    print('❌ All background tasks cancelled');
  }
  
  /// Manual sync trigger
  static Future<void> triggerManualSync() async {
    await Workmanager().registerOneOffTask(
      'manualSync',
      syncTaskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    
    print('🔄 Manual sync triggered');
  }
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('🔄 Background task started: $task');
      
      switch (task) {
        case BackgroundSyncService.syncTaskName:
          await _syncPendingProduction();
          break;
          
        case BackgroundSyncService.notificationCheckTask:
          await _checkNewNotifications();
          break;
          
        default:
          print('Unknown task: $task');
      }
      
      print('✅ Background task completed: $task');
      return Future.value(true);
    } catch (e) {
      print('❌ Background task failed: $task - $e');
      return Future.value(false);
    }
  });
}

/// Sync pending production logs to server
Future<void> _syncPendingProduction() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString('pending_production');
    
    if (pendingJson == null || pendingJson == '[]') {
      print('No pending production logs to sync');
      return;
    }
    
    final pending = json.decode(pendingJson) as List;
    print('📤 Syncing ${pending.length} pending production logs...');
    
    // Here you would make API calls to sync pending data
    // For now, we'll just log it
    
    // After successful sync, clear pending queue
    // await prefs.setString('pending_production', '[]');
    
  } catch (e) {
    print('❌ Error syncing production: $e');
  }
}

/// Check for new notifications in background
Future<void> _checkNewNotifications() async {
  try {
    // Here you would fetch new notifications from API
    // and show local notifications if needed
    
    print('🔔 Checking for new notifications...');
    
    // For now, just log it
    // In a real app, you'd:
    // 1. Fetch notifications from API
    // 2. Compare with cached notifications
    // 3. Show local notification for new items
    
  } catch (e) {
    print('❌ Error checking notifications: $e');
  }
}

/// Schedule data export job
class ExportScheduler {
  static Future<void> scheduleExport({
    required String exportType,
    required String format,
    DateTime? scheduledFor,
  }) async {
    final taskName = 'export_${exportType}_${DateTime.now().millisecondsSinceEpoch}';
    
    await Workmanager().registerOneOffTask(
      taskName,
      'exportData',
      inputData: {
        'export_type': exportType,
        'format': format,
      },
      initialDelay: scheduledFor != null 
          ? scheduledFor.difference(DateTime.now()) 
          : Duration.zero,
    );
    
    print('📅 Export scheduled: $exportType as $format');
  }
}
