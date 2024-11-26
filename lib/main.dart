// main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_management/StaffReservationScreen.dart';
import 'package:restaurant_management/UserModel.dart';
import 'package:restaurant_management/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Restaurant Management',
      theme: ThemeData(
        primaryColor: const Color(0xFF6A5ACD), // Soft purple
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light gray
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A5ACD),
          primary: const Color(0xFF6A5ACD),
          secondary: const Color(0xFF8A4FFF), // Lighter purple
          background: const Color(0xFFF5F5F5),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A5ACD),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF6A5ACD), width: 2),
          ),
        ),
      ),
      home: AuthWrapper(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  String _selectedRole = 'customer'; // Default role

  Future<void> _authenticateUser() async {
    try {
      // Validate input fields
      if (_validateInputs()) {
        if (_isLogin) {
          // Login
          await _loginUser();
        } else {
          // Sign Up
          await _signUpUser();
        }
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  bool _validateInputs() {
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Email cannot be empty');
      return false;
    }
    if (_passwordController.text.trim().isEmpty) {
      _showErrorSnackBar('Password cannot be empty');
      return false;
    }
    if (!_isLogin && _nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Name cannot be empty');
      return false;
    }
    return true;
  }

  Future<void> _loginUser() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
  }

  Future<void> _signUpUser() async {
    try {
      // Create user in Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Ensure user is not null
      if (userCredential.user == null) {
        throw Exception('User creation failed');
      }

      // Create UserModel
      UserModel newUser = UserModel(
        id: userCredential.user!.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _selectedRole,
        createdAt: Timestamp.now(),
      );

      // Reference to Firestore collection
      final usersCollection = FirebaseFirestore.instance.collection('users');

      // Store user in Firestore with explicit error handling
      try {
        await usersCollection.doc(newUser.id).set(newUser.toMap());
        print('User successfully added to Firestore: ${newUser.id}');
      } catch (e) {
        print('Error adding user to Firestore: $e');

        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save user details: $e'),
            backgroundColor: Colors.red,
          ),
        );

        // Optionally, delete the user from Firebase Auth if Firestore storage fails
        await userCredential.user!.delete();
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign up failed: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print('Unexpected Error during signup: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign up failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            _isLogin ? 'Login failed: $message' : 'Sign up failed: $message'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isLogin ? 'Welcome Back' : 'Create Account',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (!_isLogin)
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                      if (!_isLogin) const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                      ),
                      if (!_isLogin) const SizedBox(height: 16),
                      if (!_isLogin)
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Select Role',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          value: _selectedRole,
                          items: ['customer', 'staff', 'manager']
                              .map((role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role[0].toUpperCase() +
                                        role.substring(1)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                        ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _authenticateUser,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(_isLogin ? 'Login' : 'Sign Up'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin
                      ? 'Need an account? Sign Up'
                      : 'Already have an account? Login',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Update AuthWrapper to fetch user role
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.data != null) {
            return UserRoleWrapper();
          }
          return AuthScreen();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

// New UserRoleWrapper to determine dashboard based on user role
class UserRoleWrapper extends StatelessWidget {
  const UserRoleWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        UserModel user = UserModel.fromFirestore(snapshot.data!);

        switch (user.role) {
          case 'customer':
            return CustomerDashboardScreen();
          case 'staff':
            return StaffDashboardScreen();
          case 'manager':
            return StaffDashboardScreen(); // Updated to separate manager dashboard
          default:
            return AuthScreen();
        }
      },
    );
  }
}

// Customer Dashboard
class CustomerDashboardScreen extends StatelessWidget {
  const CustomerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen()),
              );
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDashboardItem(
            context,
            'Make Reservation',
            Icons.calendar_today,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CustomerReservationScreen()),
            ),
          ),
          _buildDashboardItem(
            context,
            'Menu',
            Icons.restaurant_menu,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MenuScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      color: Theme.of(context).colorScheme.secondary,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen()),
              );
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDashboardItem(
            context,
            'Reservations',
            Icons.calendar_today,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StaffReservationScreen()),
            ),
          ),
          _buildDashboardItem(
            context,
            'Menu',
            Icons.restaurant_menu,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MenuScreen()),
            ),
          ),
          _buildDashboardItem(
            context,
            'Orders',
            Icons.shopping_cart,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => OrdersScreen()),
            ),
          ),
          _buildDashboardItem(
            context,
            'Tables',
            Icons.table_restaurant,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TablesScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      color: Theme.of(context).colorScheme.secondary,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// Customer Reservation Screen
class CustomerReservationScreen extends StatefulWidget {
  const CustomerReservationScreen({super.key});

  @override
  _CustomerReservationScreenState createState() =>
      _CustomerReservationScreenState();
}

class _CustomerReservationScreenState extends State<CustomerReservationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _partySizeController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  void _makeReservation() async {
    // Get current user
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Fetch user details
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    FirebaseFirestore.instance.collection('reservations').add({
      'customerName': _nameController.text.isNotEmpty
          ? _nameController.text
          : userDoc['name'],
      'customerEmail': user.email,
      'customerUid': user.uid,
      'partySize': int.parse(_partySizeController.text),
      'dateTime': _selectedDate,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reservation Created Successfully')),
    );

    // Clear fields
    _nameController.clear();
    _partySizeController.clear();
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Make Reservation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name (Optional)',
                hintText: 'Leave blank to use account name',
              ),
            ),
            const SizedBox(height: 16),
            // Continuing from the previous code...
            TextField(
              controller: _partySizeController,
              decoration: const InputDecoration(labelText: 'Party Size'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_selectedDate),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _selectedDate = DateTime(
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
              child: Text('Select Date & Time: ${_selectedDate.toString()}'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_partySizeController.text.isNotEmpty) {
                  _makeReservation();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter party size')),
                  );
                }
              },
              child: const Text('Make Reservation'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Reservations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reservations')
                    .where('customerUid',
                        isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No reservations found'),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var reservation = snapshot.data!.docs[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(reservation['customerName']),
                          subtitle: Text(
                            'Date: ${reservation['dateTime'].toDate().toString()}\n'
                            'Party Size: ${reservation['partySize']}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Cancel reservation
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Cancel Reservation'),
                                  content: const Text(
                                      'Are you sure you want to cancel this reservation?'),
                                  actions: [
                                    TextButton(
                                      child: const Text('No'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    TextButton(
                                      child: const Text('Yes'),
                                      onPressed: () {
                                        // Delete the reservation
                                        FirebaseFirestore.instance
                                            .collection('reservations')
                                            .doc(reservation.id)
                                            .delete();
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// Reservations Screen
class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reservations')),
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
                    'Date: ${reservation['dateTime'].toDate().toString()}\n'
                    'Party Size: ${reservation['partySize']}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      FirebaseFirestore.instance
                          .collection('reservations')
                          .doc(reservation.id)
                          .delete();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Menu Screen
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Future<void> _addMenuItem() async {
    String itemName = '';
    String price = '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Menu Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Item Name'),
              onChanged: (value) => itemName = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              onChanged: (value) => price = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Add'),
            onPressed: () {
              if (itemName.isNotEmpty && price.isNotEmpty) {
                FirebaseFirestore.instance.collection('menu').add({
                  'name': itemName,
                  'price': double.parse(price),
                  'imageUrl':
                      'assets/default_image.png', // Default placeholder image
                });

                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('menu').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var menuItem = snapshot.data!.docs[index];
              return Card(
                child: Column(
                  children: [
                    Expanded(
                      child: Image.asset(
                        menuItem['imageUrl'] ?? 'assets/default_image.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/default_image.png',
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            menuItem['name'],
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            '\$${menuItem['price'].toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMenuItem,
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.add),
      ),
    );
  }
}

// Tables Screen
class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tables')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tables').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var table = snapshot.data!.docs[index];
              return Card(
                color: table['isOccupied']
                    ? Colors.red[100]
                    : Theme.of(context).colorScheme.secondary,
                child: InkWell(
                  onTap: () {
                    FirebaseFirestore.instance
                        .collection('tables')
                        .doc(table.id)
                        .update({
                      'isOccupied': !table['isOccupied'],
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Table ${table['number']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Capacity: ${table['capacity']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        table['isOccupied'] ? 'Occupied' : 'Available',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              table['isOccupied'] ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addTable(context);
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addTable(BuildContext context) async {
    String tableNumber = '';
    String capacity = '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Table'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Table Number'),
              keyboardType: TextInputType.number,
              onChanged: (value) => tableNumber = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Capacity'),
              keyboardType: TextInputType.number,
              onChanged: (value) => capacity = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Add'),
            onPressed: () {
              if (tableNumber.isNotEmpty && capacity.isNotEmpty) {
                FirebaseFirestore.instance.collection('tables').add({
                  'number': int.parse(tableNumber),
                  'capacity': int.parse(capacity),
                  'isOccupied': false,
                });
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

// Orders Screen
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var order = snapshot.data!.docs[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('Order #${order.id.substring(0, 8)}'),
                  subtitle: Text(
                    'Table: ${order['tableNumber']}\n'
                    'Total: \$${order['total'].toStringAsFixed(2)}',
                  ),
                  trailing: Text(
                    order['status'],
                    style: TextStyle(
                      color: order['status'] == 'Completed'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Update Order Status'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('In Progress'),
                              onTap: () {
                                FirebaseFirestore.instance
                                    .collection('orders')
                                    .doc(order.id)
                                    .update({'status': 'In Progress'});
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              title: const Text('Completed'),
                              onTap: () {
                                FirebaseFirestore.instance
                                    .collection('orders')
                                    .doc(order.id)
                                    .update({'status': 'Completed'});
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              title: const Text('Cancelled'),
                              onTap: () {
                                FirebaseFirestore.instance
                                    .collection('orders')
                                    .doc(order.id)
                                    .update({'status': 'Cancelled'});
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrder(context),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addOrder(BuildContext context) async {
    String tableNumber = '';
    List<Map<String, dynamic>> items = [];
    double total = 0;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Table Number'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => tableNumber = value,
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance.collection('menu').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return Column(
                      children: snapshot.data!.docs.map((menuItem) {
                        return CheckboxListTile(
                          title: Text(menuItem['name']),
                          subtitle:
                              Text('\$${menuItem['price'].toStringAsFixed(2)}'),
                          value: items
                              .any((item) => item['name'] == menuItem['name']),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value!) {
                                items.add({
                                  'name': menuItem['name'],
                                  'price': menuItem['price'],
                                });
                                total += menuItem['price'];
                              } else {
                                items.removeWhere(
                                    (item) => item['name'] == menuItem['name']);
                                total -= menuItem['price'];
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Total: \$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Add Order'),
              onPressed: () {
                if (tableNumber.isNotEmpty && items.isNotEmpty) {
                  FirebaseFirestore.instance.collection('orders').add({
                    'tableNumber': int.parse(tableNumber),
                    'items': items,
                    'total': total,
                    'status': 'Pending',
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
