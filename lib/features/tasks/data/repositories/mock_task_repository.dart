import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/task.dart';
import '../../domain/repositories/task_repository.dart';

class MockTaskRepository implements TaskRepository {
  final _controller = StreamController<List<Task>>.broadcast();
  static const _tasksKey = 'mock_tasks_data';
  List<Task> _tasks = [];

  MockTaskRepository() {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_tasksKey);
      if (jsonStr != null) {
        final List decoded = jsonDecode(jsonStr);
        _tasks = decoded.map((x) => Task.fromMap(x, x['id'] ?? '')).toList();
      } else {
        _tasks = _getSeedTasks();
        await _save();
      }
    } catch (_) {
      _tasks = _getSeedTasks();
    }
    _controller.add(_tasks);
  }

  List<Task> _getSeedTasks() {
    final now = DateTime.now();
    return [
      Task(
        id: '1',
        title: 'Complete login screen animations & validations',
        description: 'Implement soft fade transitions and validation for email/password fields matching material 3 styles.',
        status: 'In Progress',
        priority: 'High',
        dueDate: now.add(const Duration(hours: 4)),
        comments: [
          TaskComment(
            id: 'c1',
            userName: 'Jane',
            text: 'I started writing the fade animation controller yesterday.',
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
        history: [
          TaskHistoryEntry(
            id: 'h1',
            action: 'Task created',
            timestamp: now.subtract(const Duration(hours: 5)),
          ),
          TaskHistoryEntry(
            id: 'h2',
            action: 'Status changed to In Progress',
            timestamp: now.subtract(const Duration(hours: 3)),
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 3)),
        assigneeId: 'mock_employee_1',
        assigneeName: 'Emily Employee',
      ),
      Task(
        id: '2',
        title: 'Review production build config scripts',
        description: 'Verify dynamic mocks switching rules and flutter pipeline compile variables.',
        status: 'Todo',
        priority: 'Medium',
        dueDate: now.add(const Duration(days: 1)),
        comments: [],
        history: [
          TaskHistoryEntry(
            id: 'h3',
            action: 'Task created',
            timestamp: now.subtract(const Duration(hours: 6)),
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 6)),
        assigneeId: 'mock_employee_2',
        assigneeName: 'Evan Employee',
      ),
      Task(
        id: '3',
        title: 'Refactor enterprise organisation switcher',
        description: 'Optimize drawer widgets and layout paddings for narrow display sizes.',
        status: 'Review',
        priority: 'Low',
        dueDate: now.subtract(const Duration(hours: 2)),
        comments: [
          TaskComment(
            id: 'c2',
            userName: 'Alex',
            text: 'Need design approval on organization icon sizes.',
            createdAt: now.subtract(const Duration(minutes: 40)),
          ),
        ],
        history: [
          TaskHistoryEntry(
            id: 'h4',
            action: 'Task created',
            timestamp: now.subtract(const Duration(days: 1)),
          ),
          TaskHistoryEntry(
            id: 'h5',
            action: 'Status changed to Review',
            timestamp: now.subtract(const Duration(hours: 1)),
          ),
        ],
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        assigneeId: 'mock_employee_3',
        assigneeName: 'Ethan Employee',
      ),
      Task(
        id: '4',
        title: 'Upgrade Flutter engine release version',
        description: 'Bump to latest stable build and check deprecated material 3 members warnings.',
        status: 'Completed',
        priority: 'High',
        dueDate: now.subtract(const Duration(days: 1)),
        comments: [],
        history: [
          TaskHistoryEntry(
            id: 'h6',
            action: 'Task created',
            timestamp: now.subtract(const Duration(days: 2)),
          ),
          TaskHistoryEntry(
            id: 'h7',
            action: 'Status changed to Completed',
            timestamp: now.subtract(const Duration(days: 1)),
          ),
        ],
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
        assigneeId: 'mock_manager',
        assigneeName: 'Mark Manager',
      ),
    ];
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _tasks.map((x) => x.toMap()).toList();
      await prefs.setString(_tasksKey, jsonEncode(list));
    } catch (_) {}
  }

  @override
  Stream<List<Task>> watchTasks() => _controller.stream;

  @override
  Future<List<Task>> getTasks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _tasks;
  }

  @override
  Future<void> createTask(Task task) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _tasks = [task, ..._tasks];
    await _save();
    _controller.add(_tasks);
  }

  @override
  Future<void> updateTask(Task task) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _tasks = _tasks.map((x) => x.id == task.id ? task : x).toList();
    await _save();
    _controller.add(_tasks);
  }

  @override
  Future<void> deleteTask(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _tasks = _tasks.where((x) => x.id != id).toList();
    await _save();
    _controller.add(_tasks);
  }
}
