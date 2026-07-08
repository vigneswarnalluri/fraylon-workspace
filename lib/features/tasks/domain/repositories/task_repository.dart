import '../models/task.dart';

abstract class TaskRepository {
  Stream<List<Task>> watchTasks();
  Future<List<Task>> getTasks();
  Future<void> createTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String id);
}
