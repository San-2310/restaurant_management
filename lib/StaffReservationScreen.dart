import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StaffReservationScreen extends StatefulWidget {
  const StaffReservationScreen({super.key});

  @override
  _StaffReservationScreenState createState() => _StaffReservationScreenState();
}

class _StaffReservationScreenState extends State<StaffReservationScreen> {
  // Controller for creating new reservations
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _partySizeController = TextEditingController();
  DateTime? _selectedDateTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Reservations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddReservationDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .orderBy('dateTime')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var reservation = snapshot.data!.docs[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('${reservation['customerName']}'),
                  subtitle: Text(
                    'Date: ${_formatDateTime(reservation['dateTime'].toDate())}\n'
                    'Party Size: ${reservation['partySize']}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _updateReservation(context, reservation),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('reservations')
                              .doc(reservation.id)
                              .delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Format date and time nicely
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} '
        '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
  }

  // Helper to ensure two-digit formatting
  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  void _showAddReservationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Reservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Customer Name'),
            ),
            TextField(
              controller: _partySizeController,
              decoration: const InputDecoration(labelText: 'Party Size'),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
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
              },
              child: Text(_selectedDateTime == null
                  ? 'Select Date & Time'
                  : 'Date: ${_formatDateTime(_selectedDateTime!)}'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              _resetControllers();
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text('Add'),
            onPressed: () {
              if (_validateReservation()) {
                FirebaseFirestore.instance.collection('reservations').add({
                  'customerName': _nameController.text,
                  'partySize': int.parse(_partySizeController.text),
                  'dateTime': _selectedDateTime,
                });
                _resetControllers();
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _updateReservation(BuildContext context, DocumentSnapshot reservation) {
    TextEditingController nameController =
        TextEditingController(text: reservation['customerName']);
    TextEditingController partySizeController =
        TextEditingController(text: reservation['partySize'].toString());
    DateTime selectedDate = reservation['dateTime'].toDate();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Reservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Customer Name'),
            ),
            TextField(
              controller: partySizeController,
              decoration: const InputDecoration(labelText: 'Party Size'),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(selectedDate),
                  );
                  if (pickedTime != null) {
                    selectedDate = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                  }
                }
              },
              child: Text('Select Date & Time'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Update'),
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('reservations')
                  .doc(reservation.id)
                  .update({
                'customerName': nameController.text,
                'partySize': int.parse(partySizeController.text),
                'dateTime': selectedDate,
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  bool _validateReservation() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter customer name')),
      );
      return false;
    }

    if (_partySizeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter party size')),
      );
      return false;
    }

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return false;
    }

    return true;
  }

  void _resetControllers() {
    _nameController.clear();
    _partySizeController.clear();
    _selectedDateTime = null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _partySizeController.dispose();
    super.dispose();
  }
}
