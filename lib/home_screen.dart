import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'task_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ─── State ────────────────────────────────────────────────────────────────
  List<Task> _tasks = [];
  bool _isLoading = true;
  final TextEditingController _taskController = TextEditingController();
  static const String _storageKey = 'tasks_list';

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadTasks(); // Load saved tasks on startup
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  // ─── SharedPreferences: Load ───────────────────────────────────────────────
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_storageKey);

    if (tasksJson != null) {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      setState(() {
        _tasks = decoded
            .map((item) => Task.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      });
    }
    setState(() => _isLoading = false);
  }

  // ─── SharedPreferences: Save ───────────────────────────────────────────────
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_tasks.map((t) => t.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  // ─── CRUD Operations ──────────────────────────────────────────────────────

  /// Adds a new task with a unique UUID.
  void _addTask(String title) {
    if (title.trim().isEmpty) return;
    final task = Task(
      id: const Uuid().v4(),
      title: title.trim(),
    );
    setState(() => _tasks.add(task));
    _saveTasks();
    _taskController.clear();
  }

  /// Toggles completion status for a task.
  void _toggleTask(String id) {
    setState(() {
      final task = _tasks.firstWhere((t) => t.id == id);
      task.isCompleted = !task.isCompleted;
    });
    _saveTasks();
  }

  /// Deletes a task by id with undo support.
  void _deleteTask(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    final removed = _tasks[index];
    setState(() => _tasks.removeAt(index));
    _saveTasks();

    // Show undo SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "${removed.title}" deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() => _tasks.insert(index, removed));
            _saveTasks();
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── Add Task Dialog ──────────────────────────────────────────────────────
  void _showAddTaskDialog() {
    _taskController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_task, color: Colors.indigo),
            SizedBox(width: 8),
            Text('New Task'),
          ],
        ),
        content: TextField(
          controller: _taskController,
          autofocus: true,
          maxLength: 80,
          decoration: const InputDecoration(
            hintText: 'Enter task title...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit_note),
          ),
          onSubmitted: (value) {
            _addTask(value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Add Task'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              _addTask(_taskController.text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ─── Computed Properties ──────────────────────────────────────────────────
  int get _completedCount => _tasks.where((t) => t.isCompleted).length;

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ── Custom AppBar ──────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Tasks',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (_tasks.isNotEmpty)
              Text(
                '$_completedCount / ${_tasks.length} completed',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          // Clear completed tasks action button
          if (_completedCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Clear completed',
              onPressed: _clearCompletedDialog,
            ),
          // Add task action button
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Task',
            onPressed: _showAddTaskDialog,
          ),
        ],
      ),

      // ── Body ───────────────────────────────────────────────────────────────
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
          ? _buildEmptyState()
          : _buildTaskList(),

      // ── FAB ────────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  // ─── Empty State Widget ───────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No tasks yet!',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first task.',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // ─── Task List ────────────────────────────────────────────────────────────
  Widget _buildTaskList() {
    // Pending tasks first, completed at bottom
    final pending = _tasks.where((t) => !t.isCompleted).toList();
    final completed = _tasks.where((t) => t.isCompleted).toList();
    final ordered = [...pending, ...completed];

    return Column(
      children: [
        // Progress indicator
        if (_tasks.isNotEmpty)
          LinearProgressIndicator(
            value: _completedCount / _tasks.length,
            backgroundColor: Colors.indigo[50],
            color: Colors.indigo,
            minHeight: 6,
          ),

        // Task list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: ordered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _buildTaskCard(ordered[index]),
          ),
        ),
      ],
    );
  }

  // ─── Task Card ────────────────────────────────────────────────────────────
  Widget _buildTaskCard(Task task) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _deleteTask(task.id),
      child: Card(
        elevation: task.isCompleted ? 0 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: task.isCompleted ? Colors.grey[100] : Colors.white,
        child: ListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          // Checkbox on the left
          leading: GestureDetector(
            onTap: () => _toggleTask(task.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isCompleted ? Colors.indigo : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted ? Colors.indigo : Colors.grey,
                  width: 2,
                ),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
          // Task title
          title: Text(
            task.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight:
              task.isCompleted ? FontWeight.normal : FontWeight.w500,
              color: task.isCompleted ? Colors.grey[400] : Colors.black87,
              decoration:
              task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          // Status chip
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.isCompleted)
                Chip(
                  label: const Text('Done',
                      style: TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete',
                onPressed: () => _deleteTask(task.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Clear Completed Dialog ───────────────────────────────────────────────
  void _clearCompletedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.done_all, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Clear Completed'),
          ],
        ),
        content: Text(
            'Remove all $_completedCount completed task(s)?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() => _tasks.removeWhere((t) => t.isCompleted));
              _saveTasks();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
