import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindspace/database/supabase_service.dart';
import 'package:mindspace/RemindersModule/models/reminder_model.dart';
import 'package:intl/intl.dart';

class AddEditReminderScreen extends StatefulWidget {
  final ReminderModel? reminder;

  const AddEditReminderScreen({Key? key, this.reminder}) : super(key: key);

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final SupabaseService _dbHelper = SupabaseService.instance;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  bool _isRecurring = false;
  String? _recurrenceType;
  bool _isSaving = false;

  final List<String> _recurrenceTypes = [
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      _titleController.text = widget.reminder!.title;
      _descriptionController.text = widget.reminder!.description ?? '';
      _selectedDateTime = widget.reminder!.reminderTime;
      _isRecurring = widget.reminder!.isRecurring;
      _recurrenceType = widget.reminder!.recurrenceType;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isRecurring && _recurrenceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a recurrence type')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final reminderData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'reminder_time': _selectedDateTime.toIso8601String(),
        'is_recurring': _isRecurring,
        'recurrence_type': _isRecurring ? _recurrenceType : null,
      };

      if (widget.reminder != null && widget.reminder!.id != null) {
        // Update existing reminder
        await _dbHelper.updateReminder(widget.reminder!.id!, reminderData);
      } else {
        // Create new reminder
        await _dbHelper.createReminder(reminderData);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving reminder: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.reminder == null ? 'New Reminder' : 'Edit Reminder'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveReminder,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g., Meditation',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Date & Time
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time, color: Color(0xFF2196F3)),
                title: const Text('Date & Time'),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(_selectedDateTime),
                  style: const TextStyle(fontSize: 16),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _selectDateTime,
              ),
            ),
            const SizedBox(height: 16),

            // Recurring Toggle
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.repeat, color: Color(0xFF2196F3)),
                title: const Text('Repeat'),
                subtitle: const Text('Make this reminder recurring'),
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value;
                    if (!value) {
                      _recurrenceType = null;
                    }
                  });
                },
              ),
            ),

            // Recurrence Type
            if (_isRecurring) ...[
              const SizedBox(height: 16),
              Card(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Repeat Frequency',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  value: _recurrenceType,
                  items: _recurrenceTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type[0].toUpperCase() + type.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _recurrenceType = value;
                    });
                  },
                  validator: (value) {
                    if (_isRecurring && value == null) {
                      return 'Please select a frequency';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

