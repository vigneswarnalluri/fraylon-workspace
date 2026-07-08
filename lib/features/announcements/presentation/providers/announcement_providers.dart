import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/firebase_announcement_repository.dart';
import '../../data/repositories/mock_announcement_repository.dart';
import '../../domain/models/announcement.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/repositories/announcement_repository.dart';

// Provider that selects the active repository dynamically based on integration settings
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  final useFirebase = ref.watch(useFirebaseProvider);
  
  bool isFirebaseReady = false;
  try {
    isFirebaseReady = Firebase.apps.isNotEmpty;
  } catch (_) {}

  if (useFirebase && isFirebaseReady) {
    return FirebaseAnnouncementRepository();
  } else {
    return MockAnnouncementRepository();
  }
});

// Stream provider to watch announcements reactively
final announcementsStreamProvider = StreamProvider<List<Announcement>>((ref) {
  final repository = ref.watch(announcementRepositoryProvider);
  return repository.watchAnnouncements();
});

// ---------------------------------------------------------------------------
// Filtering State
// ---------------------------------------------------------------------------

class AnnouncementFilters {
  final String searchQuery;
  final List<String> selectedPriorities; // 'Info', 'Notice', 'Alert', 'Urgent'

  AnnouncementFilters({
    this.searchQuery = '',
    this.selectedPriorities = const [],
  });

  AnnouncementFilters copyWith({
    String? searchQuery,
    List<String>? selectedPriorities,
  }) {
    return AnnouncementFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedPriorities: selectedPriorities ?? this.selectedPriorities,
    );
  }
}

class AnnouncementFiltersNotifier extends StateNotifier<AnnouncementFilters> {
  AnnouncementFiltersNotifier() : super(AnnouncementFilters());

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
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

  void clearFilters() {
    state = AnnouncementFilters();
  }
}

final announcementFiltersProvider =
    StateNotifierProvider<AnnouncementFiltersNotifier, AnnouncementFilters>((ref) {
  return AnnouncementFiltersNotifier();
});

// ---------------------------------------------------------------------------
// Filtered Announcements Provider
// ---------------------------------------------------------------------------

final filteredAnnouncementsProvider = Provider<AsyncValue<List<Announcement>>>((ref) {
  final announcementsAsync = ref.watch(announcementsStreamProvider);
  final filters = ref.watch(announcementFiltersProvider);

  return announcementsAsync.when(
    data: (announcements) {
      var list = announcements;

      // Filter by search query (match title, description, or author)
      if (filters.searchQuery.isNotEmpty) {
        final query = filters.searchQuery.toLowerCase();
        list = list.where((a) {
          return a.title.toLowerCase().contains(query) ||
              a.description.toLowerCase().contains(query) ||
              a.author.toLowerCase().contains(query);
        }).toList();
      }

      // Filter by priority list
      if (filters.selectedPriorities.isNotEmpty) {
        list = list.where((a) => filters.selectedPriorities.contains(a.priority)).toList();
      }

      return AsyncValue.data(list);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, stack) => AsyncValue.error(e, stack),
  );
});

// ---------------------------------------------------------------------------
// Announcement Action Controller
// ---------------------------------------------------------------------------

class AnnouncementActionController extends StateNotifier<AsyncValue<void>> {
  final AnnouncementRepository _repository;

  AnnouncementActionController(this._repository)
      : super(const AsyncValue.data(null));

  Future<bool> createAnnouncement({
    required String title,
    required String description,
    required String priority,
    required String author,
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final announcement = Announcement(
        id: 'ann_${now.millisecondsSinceEpoch}',
        title: title,
        description: description,
        author: author,
        createdAt: now,
        priority: priority,
      );
      await _repository.createAnnouncement(announcement);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> updateAnnouncement(Announcement announcement) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateAnnouncement(announcement);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> deleteAnnouncement(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteAnnouncement(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final announcementActionControllerProvider =
    StateNotifierProvider<AnnouncementActionController, AsyncValue<void>>((ref) {
  final repository = ref.watch(announcementRepositoryProvider);
  return AnnouncementActionController(repository);
});
