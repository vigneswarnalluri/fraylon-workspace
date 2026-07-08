import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/firebase_notification_repository.dart';
import '../../data/repositories/mock_notification_repository.dart';
import '../../domain/models/app_notification.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/repositories/notification_repository.dart';

// Provider that selects the active notification repository dynamically
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final useFirebase = ref.watch(useFirebaseProvider);
  
  bool isFirebaseReady = false;
  try {
    isFirebaseReady = Firebase.apps.isNotEmpty;
  } catch (_) {}

  if (useFirebase && isFirebaseReady) {
    return FirebaseNotificationRepository();
  } else {
    return MockNotificationRepository();
  }
});

// Stream provider to watch notifications reactively
final notificationsStreamProvider = StreamProvider<List<AppNotification>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchNotifications();
});

// Provider that counts unread notifications in real-time
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsStreamProvider);
  return notificationsAsync.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

// ---------------------------------------------------------------------------
// Filtering State
// ---------------------------------------------------------------------------

class NotificationFilters {
  final String selectedCategory; // 'All', 'Task', 'Announcement', 'System'
  final String selectedPriority; // 'All', 'Low', 'Medium', 'High', 'Urgent'

  NotificationFilters({
    this.selectedCategory = 'All',
    this.selectedPriority = 'All',
  });

  NotificationFilters copyWith({
    String? selectedCategory,
    String? selectedPriority,
  }) {
    return NotificationFilters(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedPriority: selectedPriority ?? this.selectedPriority,
    );
  }
}

class NotificationFiltersNotifier extends StateNotifier<NotificationFilters> {
  NotificationFiltersNotifier() : super(NotificationFilters());

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void selectPriority(String priority) {
    state = state.copyWith(selectedPriority: priority);
  }

  void clearFilters() {
    state = NotificationFilters();
  }
}

final notificationFiltersProvider =
    StateNotifierProvider<NotificationFiltersNotifier, NotificationFilters>((ref) {
  return NotificationFiltersNotifier();
});

// ---------------------------------------------------------------------------
// Filtered Notifications Provider
// ---------------------------------------------------------------------------

final filteredNotificationsProvider = Provider<AsyncValue<List<AppNotification>>>((ref) {
  final notificationsAsync = ref.watch(notificationsStreamProvider);
  final filters = ref.watch(notificationFiltersProvider);

  return notificationsAsync.when(
    data: (notifications) {
      var list = notifications;

      // Filter by category
      if (filters.selectedCategory != 'All') {
        list = list.where((n) => n.category == filters.selectedCategory).toList();
      }

      // Filter by priority
      if (filters.selectedPriority != 'All') {
        list = list.where((n) => n.priority == filters.selectedPriority).toList();
      }

      return AsyncValue.data(list);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, stack) => AsyncValue.error(e, stack),
  );
});

// ---------------------------------------------------------------------------
// Notification Action Controller
// ---------------------------------------------------------------------------

class NotificationActionController extends StateNotifier<AsyncValue<void>> {
  final NotificationRepository _repository;

  NotificationActionController(this._repository)
      : super(const AsyncValue.data(null));

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _repository.deleteNotification(id);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> clearAll() async {
    try {
      await _repository.clearAll();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Developer simulation helper: creates a random notification in the list
  Future<void> simulateNotification() async {
    final now = DateTime.now();
    final categories = ['Task', 'Announcement', 'System'];
    final priorities = ['Low', 'Medium', 'High', 'Urgent'];
    
    // Choose index based on timestamp to make it pseudo-random
    final catIdx = now.millisecondsSinceEpoch % categories.length;
    final priIdx = now.millisecondsSinceEpoch % priorities.length;
    
    final category = categories[catIdx];
    final priority = priorities[priIdx];
    
    final id = 'sim_${now.millisecondsSinceEpoch}';
    final title = 'Simulated $category Notification';
    final message = 'This is a pseudo-random notification simulated on ${now.hour}:${now.minute.toString().padLeft(2, '0')} with priority $priority.';
    
    final notification = AppNotification(
      id: id,
      title: title,
      message: message,
      category: category,
      priority: priority,
      createdAt: now,
    );
    
    try {
      await _repository.createNotification(notification);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final notificationActionControllerProvider =
    StateNotifierProvider<NotificationActionController, AsyncValue<void>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationActionController(repository);
});
