import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(ToDoApp());
}

class ToDoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ToDoList(),
    );
  }
}

class Task {
  String title;
  String priority;
  bool isDone;

  Task({required this.title, this.priority = 'Low', this.isDone = false});
}

class ToDoList extends StatefulWidget {
  @override
  _ToDoListState createState() => _ToDoListState();
}

class _ToDoListState extends State<ToDoList> {
  final List<Task> _tasks = [];
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  String _selectedPriority = 'Low';
  String _sortBy = 'None';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        backgroundColor: Colors.deepPurple,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                _sortBy = value;
                _sortTasks();
              });
            },
            itemBuilder: (BuildContext context) {
              return {'Name', 'Priority'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text('Sort by $choice'),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedList(
              key: _listKey,
              initialItemCount: _tasks.length,
              itemBuilder: (context, index, animation) {
                Task task = _tasks[index];
                return _buildTaskTile(task, index, animation);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Add Task',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedPriority,
                  items: ['Low', 'Medium', 'High'].map((String priority) {
                    return DropdownMenuItem<String>(
                      value: priority,
                      child: Text(priority),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPriority = newValue!;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final task = Task(
                      title: _controller.text,
                      priority: _selectedPriority,
                    );
                    setState(() {
                      _tasks.add(task);
                      _listKey.currentState?.insertItem(_tasks.length - 1);
                      _controller.clear();
                      _sortTasks();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(Task task, int index, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: ListTile(
          key: ValueKey(index),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isDone ? TextDecoration.lineThrough : TextDecoration.none,
              color: task.isDone ? Colors.grey : Colors.black,
            ),
          ),
          subtitle: Text(
            task.priority,
            style: TextStyle(
              decoration: task.isDone ? TextDecoration.lineThrough : TextDecoration.none,
              color: task.isDone ? Colors.grey : Colors.black,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: task.isDone,
                onChanged: (bool? value) {
                  setState(() {
                    task.isDone = value!;
                    if (value) {
                      _moveTaskToBottom(index);
                    } else {
                      _sortTasks();
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _editTask(index);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _tasks.removeAt(index);
                    _listKey.currentState?.removeItem(index, (context, animation) => const SizedBox.shrink());
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _moveTaskToBottom(int index) {
    final task = _tasks.removeAt(index);
    _tasks.add(task);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildTaskTile(task, index, animation),
    );
    _listKey.currentState?.insertItem(_tasks.length - 1);
  }

  void _editTask(int index) {
    _controller.text = _tasks[index].title;
    _selectedPriority = _tasks[index].priority;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: TextField(
            controller: _controller,
          ),
          actions: [
            DropdownButton<String>(
              value: _selectedPriority,
              items: ['Low', 'Medium', 'High'].map((String priority) {
                return DropdownMenuItem<String>(
                  value: priority,
                  child: Text(priority),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPriority = newValue!;
                });
              },
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _tasks[index].title = _controller.text;
                  _tasks[index].priority = _selectedPriority;
                  _controller.clear();
                  _sortTasks();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _sortTasks() {
    _tasks.sort((a, b) {
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      } else if (_sortBy == 'Priority') {
        return _priorityValue(b.priority).compareTo(_priorityValue(a.priority));
      } else if (_sortBy == 'Name') {
        return a.title.compareTo(b.title);
      } else {
        return 0;
      }
    });
    SchedulerBinding.instance?.addPostFrameCallback((_) {
      _listKey.currentState?.setState(() {});
    });
  }

  int _priorityValue(String priority) {
    switch (priority) {
      case 'High':
        return 3;
      case 'Medium':
        return 2;
      case 'Low':
        return 1;
      default:
        return 0;
    }
  }
}
