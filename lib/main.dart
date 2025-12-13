import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Main function - starts the app
void main() {
  runApp(const MediSchedApp());
}

// Main App Widget - sets up the basic app structure and theme
class MediSchedApp extends StatelessWidget {
  const MediSchedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediSched',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const MediSchedHome(),
    );
  }
}

// Appointment Class - stores appointment information (name and date/time)
class Appointment {
  String name;        // Patient's name
  DateTime dateTime;  // Appointment date and time

  Appointment({required this.name, required this.dateTime});

  // Convert appointment to JSON format for saving to SharedPreferences
  Map<String, dynamic> toJson() => {
        'name': name,
        'dateTime': dateTime.toIso8601String(),
      };

  // Create appointment from JSON data loaded from SharedPreferences
  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        name: json['name'] ?? '',
        dateTime: DateTime.parse(json['dateTime'] ?? DateTime.now().toIso8601String()),
      );
}

// Main Screen Widget - handles all appointment operations
class MediSchedHome extends StatefulWidget {
  const MediSchedHome({super.key});

  @override
  State<MediSchedHome> createState() => _MediSchedHomeState();
}

class _MediSchedHomeState extends State<MediSchedHome> {
  final TextEditingController _nameController = TextEditingController(); // Controls name input field
  DateTime? _selectedDate;     // Stores selected appointment date
  TimeOfDay? _selectedTime;    // Stores selected appointment time
  List<Appointment> _appointments = []; // List of all appointments
  int? _editingIndex;          // Index of appointment being edited (null if creating new)
  int? _selectedIndex;         // Index of currently selected appointment

  static const storageKey = 'timeric_appointments'; // Key for saving data to phone

  @override
  void initState() {
    super.initState();
    _loadAppointments(); // Load saved appointments when app starts
  }

  // Load saved appointments from device storage (SharedPreferences)
  // Location: Platform-specific system directories (no visible JSON file)
  Future<void> _loadAppointments() async {
    final prefs = await SharedPreferences.getInstance(); // Access device's SharedPreferences
    final raw = prefs.getString(storageKey); // Get stored JSON string
    if (raw != null) {
      try {
        final List<dynamic> list = jsonDecode(raw); // Convert JSON string to list
        _appointments = list.map((e) => Appointment.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (e) {
        _appointments = []; // If loading fails, start with empty list
      }
    }
    setState(() {}); // Update the screen with loaded data
  }

  // Save appointments to device storage (SharedPreferences)
  // Location: Platform-specific system directories (no visible JSON file)
  Future<void> _saveAppointments() async {
    final prefs = await SharedPreferences.getInstance(); // Access device's SharedPreferences
    final encoded = jsonEncode(_appointments.map((a) => a.toJson()).toList()); // Convert to JSON string
    await prefs.setString(storageKey, encoded); // Save to device storage
  }

  // Set date to current date (today)
  void _setDefaultDate() {
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  // Set time to current time (now)
  void _setDefaultTime() {
    setState(() {
      final now = DateTime.now();
      _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
    });
  }

  // Open calendar picker for user to choose date
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),  // Can go back 5 years
      lastDate: DateTime(now.year + 5),   // Can go forward 5 years
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // Open time picker for user to choose time
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // Combine selected date and time into one DateTime object
  DateTime? _combinedDateTime() {
    if (_selectedDate == null || _selectedTime == null) return null;
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  // Main function: Create new appointment or save edited appointment
  void _submit() {
    final name = _nameController.text.trim();  // Get name and remove extra spaces
    final dt = _combinedDateTime() ?? DateTime.now(); // Use selected date/time or current time

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name')));
      return;
    }

    if (_editingIndex == null) {
      // Creating new appointment
      _appointments.add(Appointment(name: name, dateTime: dt));
    } else {
      // Updating existing appointment
      _appointments[_editingIndex!] = Appointment(name: name, dateTime: dt);
      _editingIndex = null; // Exit edit mode
    }

    // Clear the form and save data
    _nameController.clear();
    _selectedDate = null;
    _selectedTime = null;
    _saveAppointments();
    setState(() {}); // Update the screen
  }

  // Load appointment data into form for editings
  void _startEdit(int index) {
    final appt = _appointments[index];
    _nameController.text = appt.name;
    _selectedDate = DateTime(appt.dateTime.year, appt.dateTime.month, appt.dateTime.day);
    _selectedTime = TimeOfDay(hour: appt.dateTime.hour, minute: appt.dateTime.minute);
    _editingIndex = index;
    setState(() => _selectedIndex = index);
  }

  // Remove appointment from the list
  void _delete(int index) {
    _appointments.removeAt(index);
    if (_editingIndex != null && _editingIndex == index) _editingIndex = null;
    _saveAppointments();
    setState(() {});
  }

  // Create the blue gradient header at the top of the screen
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.teal.shade300, Colors.teal.shade500]), // Blue gradient
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))], // Shadow effect
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('MediSched', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 4),
          Text('Clinic Appointment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white70)),
        ],
      ),
    );
  }

  // Build the main user interface - creates all the visual elements on screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light gray background
      body: SafeArea(  // Keeps content inside safe area (not behind notches)
        child: Column(
          children: [
            _buildHeader(), // Blue header at top
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Full Name:', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'Enter full name',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Appointment Date:'),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo.shade600,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: 1,
                                      ),
                                      onPressed: () => _setDefaultDate(),
                                      child: const Text('Default Date'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.shade600,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: 1,
                                      ),
                                      onPressed: _pickDate,
                                      child: const Text('Pick Date'),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(_selectedDate != null ? _selectedDate!.toLocal().toIso8601String().split('T').first : 'No date selected'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Appointment Time:'),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: 1,
                                      ),
                                      onPressed: _setDefaultTime,
                                      child: const Text('Default Time'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.shade600,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: 1,
                                      ),
                                      onPressed: _pickTime,
                                      child: const Text('Pick Time'),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(_selectedTime != null ? _selectedTime!.format(context) : 'No time selected'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 2,
                          ),
                          onPressed: _submit,
                          icon: Icon(Icons.check),
                          label: const Text('Submit'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 2,
                          ),
                          onPressed: _editingIndex != null ? () => _submit() : null,
                          icon: Icon(Icons.edit),
                          label: const Text('Edit'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 2,
                          ),
                          onPressed: _selectedIndex != null ? () => _delete(_selectedIndex!) : null,
                          icon: Icon(Icons.delete),
                          label: const Text('Delete'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('Appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _appointments.isEmpty
                        ? const Text('No appointments yet.')
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _appointments.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final appt = _appointments[index];
                              final selected = index == _selectedIndex;
                              return InkWell(
                                onTap: () => setState(() => _selectedIndex = index),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selected ? Colors.teal.shade50 : Colors.white,
                                    border: Border.all(color: selected ? Colors.teal : Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: selected ? [BoxShadow(color: Colors.teal.shade200, blurRadius: 4)] : [BoxShadow(color: Colors.black12, blurRadius: 2)],
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(appt.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: selected ? Colors.teal.shade800 : Colors.black87)),
                                          Text('${appt.dateTime.toLocal()}'.split('.').first, style: TextStyle(color: selected ? Colors.teal.shade600 : Colors.black54)),
                                        ],
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.edit, color: selected ? Colors.teal.shade700 : Colors.blue.shade600),
                                        onPressed: () => _startEdit(index),
                                        style: IconButton.styleFrom(backgroundColor: selected ? Colors.white : Colors.transparent),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
