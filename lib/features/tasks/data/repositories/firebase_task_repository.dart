import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/task.dart';
import '../../domain/repositories/task_repository.dart';

class FirebaseTaskRepository implements TaskRepository {
  final FirebaseFirestore _firestore;

  FirebaseTaskRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('tasks');

  @override
  Stream<List<Task>> watchTasks() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Task.fromMap(doc.data(), doc.id);
      }).toList();
    }).handleError((error) {
      if (error is FirebaseException) {
        throw Exception(_mapFirestoreError(error));
      }
      throw Exception('Task synchronization failed: ${error.toString()}');
    });
  }

  @override
  Future<List<Task>> getTasks() async {
    try {
      final snapshot = await _collection
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        return Task.fromMap(doc.data(), doc.id);
      }).toList();
    } on FirebaseException catch (e) {
      throw Exception(_mapFirestoreError(e));
    } catch (e) {
      throw Exception('Failed to retrieve tasks: ${e.toString()}');
    }
  }

  @override
  Future<void> createTask(Task task) async {
    try {
      await _collection.doc(task.id).set(task.toMap());
    } on FirebaseException catch (e) {
      throw Exception(_mapFirestoreError(e));
    } catch (e) {
      throw Exception('Failed to create task: ${e.toString()}');
    }
  }

  @override
  Future<void> updateTask(Task task) async {
    try {
      await _collection.doc(task.id).update(task.toMap());
    } on FirebaseException catch (e) {
      throw Exception(_mapFirestoreError(e));
    } catch (e) {
      throw Exception('Failed to update task: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      await _collection.doc(id).delete();
    } on FirebaseException catch (e) {
      throw Exception(_mapFirestoreError(e));
    } catch (e) {
      throw Exception('Failed to delete task: ${e.toString()}');
    }
  }

  String _mapFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Write/read permission denied. Ensure you are authorized.';
      case 'unavailable':
        return 'Firestore database service is currently offline. Please check connection.';
      case 'not-found':
        return 'The requested task document was not found.';
      case 'already-exists':
        return 'A task with this identifier already exists.';
      default:
        return e.message ?? 'An unexpected database error occurred.';
    }
  }
}
