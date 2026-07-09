import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/firebase_task_repository.dart';
import '../../data/repositories/mock_task_repository.dart';
import '../../domain/models/task.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/repositories/task_repository.dart';
import '../../../profile/domain/models/user_profile.dart';

// Provider that selects the active task repository dynamically
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final useFirebase = ref.watch(useFirebaseProvider);
  
  bool isFirebaseReady = false;
  try {
    isFirebaseReady = Firebase.apps.isNotEmpty;
  } catch (_) {}

  if (useFirebase && isFirebaseReady) {
    return FirebaseTaskRepository();
  } else {
    return MockTaskRepository();
  }
});

// Stream provider to watch tasks reactively, filtered by role.
// - Employee: only sees tasks explicitly assigned to their UID.
// - Manager / Admin / Super Admin: sees all tasks.
final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final userProfileAsync = ref.watch(userProfileProvider);

  return repository.watchTasks().map((tasks) {
    final profile = userProfileAsync.valueOrNull;

    // If profile not yet loaded, show nothing to avoid leaking data.
    if (profile == null) return <Task>[];

    const employeeRoles = {'Employee'};
    if (employeeRoles.contains(profile.role)) {
      // Employees only see tasks assigned specifically to them.
      return tasks.where((t) => t.assigneeId == profile.uid).toList();
    }

    // Managers and above see all tasks.
    return tasks;
  });
});

// ---------------------------------------------------------------------------
// Filtering State
// ---------------------------------------------------------------------------

class TaskFilters {
  final String searchQuery;
  final List<String> selectedStatuses;
  final List<String> selectedPriorities;
  final DateTime? selectedDate;
  final bool isCalendarView;

  TaskFilters({
    this.searchQuery = '',
    this.selectedStatuses = const [],
    this.selectedPriorities = const [],
    this.selectedDate,
    this.isCalendarView = false,
  });

  TaskFilters copyWith({
    String? searchQuery,
    List<String>? selectedStatuses,
    List<String>? selectedPriorities,
    DateTime? selectedDate,
    bool clearDate = false,
    bool? isCalendarView,
  }) {
    return TaskFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      selectedPriorities: selectedPriorities ?? this.selectedPriorities,
      selectedDate: clearDate ? null : (selectedDate ?? this.selectedDate),
      isCalendarView: isCalendarView ?? this.isCalendarView,
    );
  }
}

class TaskFiltersNotifier extends StateNotifier<TaskFilters> {
  TaskFiltersNotifier() : super(TaskFilters());

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleStatus(String status) {
    final list = List<String>.from(state.selectedStatuses);
    if (list.contains(status)) {
      list.remove(status);
    } else {
      list.add(status);
    }
    state = state.copyWith(selectedStatuses: list);
  }

  void togglePriority(String priority) {
    final list = List<String>.from(state.selectedPriorities);
    if (list.contains(priority)) {
      list.remove(priority);
    } else {
      list.add(priority);
    }
    state = state.copyWith(selectedPriorities: list);
  }

  void updateDate(DateTime? date) {
    if (date == null) {
      state = state.copyWith(clearDate: true);
    } else {
      state = state.copyWith(selectedDate: date);
    }
  }

  void toggleCalendarView(bool isCalendar) {
    state = state.copyWith(isCalendarView: isCalendar);
  }

  void clearFilters() {
    state = TaskFilters(isCalendarView: state.isCalendarView);
  }
}

final taskFiltersProvider =
    StateNotifierProvider<TaskFiltersNotifier, TaskFilters>((ref) {
  return TaskFiltersNotifier();
});

// ---------------------------------------------------------------------------
// Filtered Tasks Provider
// ---------------------------------------------------------------------------

final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  final filters = ref.watch(taskFiltersProvider);

  return tasksAsync.when(
    data: (tasks) {
      var list = tasks;

      // Filter by search query
      if (filters.searchQuery.isNotEmpty) {
        final query = filters.searchQuery.toLowerCase();
        list = list.where((t) {
          return t.title.toLowerCase().contains(query) ||
              t.description.toLowerCase().contains(query);
        }).toList();
      }

      // Filter by status
      if (filters.selectedStatuses.isNotEmpty) {
        list = list.where((t) => filters.selectedStatuses.contains(t.status)).toList();
      }

      // Filter by priority
      if (filters.selectedPriorities.isNotEmpty) {
        list = list.where((t) => filters.selectedPriorities.contains(t.priority)).toList();
      }

      // Filter by due date (same day check)
      if (filters.selectedDate != null) {
        final filterDate = filters.selectedDate!;
        list = list.where((t) {
          return t.dueDate.year == filterDate.year &&
              t.dueDate.month == filterDate.month &&
              t.dueDate.day == filterDate.day;
        }).toList();
      }

      return AsyncValue.data(list);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, stack) => AsyncValue.error(e, stack),
  );
});

// ---------------------------------------------------------------------------
// Task Action Controller
// ---------------------------------------------------------------------------

class TaskActionController extends StateNotifier<AsyncValue<void>> {
  final TaskRepository _repository;

  TaskActionController(this._repository) : super(const AsyncValue.data(null));

  Future<bool> createTask({
    required String title,
    required String description,
    required String status,
    required String priority,
    required DateTime dueDate,
    String? assigneeId,
    String? assigneeName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final task = Task(
        id: now.millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        status: status,
        priority: priority,
        dueDate: dueDate,
        comments: [],
        history: [
          TaskHistoryEntry(
            id: 'h_${now.millisecondsSinceEpoch}',
            action: 'Task created',
            timestamp: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
        assigneeId: assigneeId,
        assigneeName: assigneeName,
      );
      await _repository.createTask(task);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> updateTask(Task task) async {
    state = const AsyncValue.loading();
    try {
      final updated = task.copyWith(updatedAt: DateTime.now());
      await _repository.updateTask(updated);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> changeTaskStatus(Task task, String newStatus) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final updatedHistory = List<TaskHistoryEntry>.from(task.history)
        ..add(
          TaskHistoryEntry(
            id: 'h_${now.millisecondsSinceEpoch}',
            action: 'Changed status from ${task.status} to $newStatus',
            timestamp: now,
          ),
        );
      final updated = task.copyWith(
        status: newStatus,
        history: updatedHistory,
        updatedAt: now,
      );
      await _repository.updateTask(updated);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> addTaskComment(Task task, String userName, String text) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final comment = TaskComment(
        id: 'c_${now.millisecondsSinceEpoch}',
        userName: userName,
        text: text,
        createdAt: now,
      );
      final updatedComments = List<TaskComment>.from(task.comments)..add(comment);
      final updatedHistory = List<TaskHistoryEntry>.from(task.history)
        ..add(
          TaskHistoryEntry(
            id: 'h_${now.millisecondsSinceEpoch}',
            action: 'Added comment: "$text"',
            timestamp: now,
          ),
        );
      final updated = task.copyWith(
        comments: updatedComments,
        history: updatedHistory,
        updatedAt: now,
      );
      await _repository.updateTask(updated);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTask(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final taskActionControllerProvider =
    StateNotifierProvider<TaskActionController, AsyncValue<void>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TaskActionController(repository);
});

final allUsersProvider = FutureProvider<List<UserProfile>>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getAllUsers();
});
