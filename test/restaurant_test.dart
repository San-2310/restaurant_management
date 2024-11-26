import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Restaurant Reservation System Testing', () {
    // Simulated reservations database
    final List<Map<String, dynamic>> reservations = [];

    // Helper function to simulate adding a reservation
    Map<String, dynamic> addReservation(Map<String, dynamic> reservationData) {
      // Validate party size
      if (reservationData['partySize'] == null ||
          reservationData['partySize'] <= 0) {
        throw Exception('Invalid party size');
      }

      // Validate required fields
      if (reservationData['customerName'] == null ||
          reservationData['dateTime'] == null) {
        throw Exception('Missing required fields');
      }

      // Simulate unique ID and add reservation to the list
      reservationData['id'] = reservations.length; // Assign a unique ID
      reservations.add(reservationData);
      return reservationData;
    }

    // Helper function to simulate fetching a reservation
    Map<String, dynamic>? getReservation(int id) {
      try {
        return reservations.firstWhere((r) => r['id'] == id);
      } catch (e) {
        return null; // Return null if no matching element is found
      }
    }

    // Helper function to simulate updating a reservation
    void updateReservation(int id, Map<String, dynamic> updates) {
      final reservation = getReservation(id);
      if (reservation == null) {
        throw Exception('Reservation not found');
      }
      reservation.addAll(updates);
    }

    // Helper function to simulate deleting a reservation
    void deleteReservation(int id) {
      final reservation = getReservation(id);
      if (reservation == null) {
        throw Exception('Reservation not found');
      }
      reservations.remove(reservation);
    }

    // Unit 1: Reservation Creation Tests
    group('Reservation Creation Tests', () {
      test(
          'Should successfully create a reservation with complete and valid information',
          () {
        final reservationData = addReservation({
          'customerName': 'Test User',
          'partySize': 4,
          'dateTime': DateTime.now(),
        });

        // Verify reservation was created
        expect(reservations.contains(reservationData), true);
        expect(reservationData['partySize'], 4);
      });

      test(
          'Should throw an exception when creating a reservation with an invalid party size',
          () {
        expect(
          () => addReservation({
            'customerName': 'Invalid User',
            'partySize': -1, // Invalid party size
            'dateTime': DateTime.now(),
          }),
          throwsA(isA<Exception>()),
        );
      });

      test(
          'Should throw an exception when creating a reservation with missing required fields',
          () {
        expect(
          () => addReservation({'customerName': 'Incomplete User'}),
          throwsA(isA<Exception>()),
        );
      });
    });

    // Unit 2: Reservation Update Tests
    group('Reservation Update Tests', () {
      test(
          'Should successfully update an existing reservation with new party size',
          () {
        final reservation = addReservation({
          'customerName': 'Original User',
          'partySize': 2,
          'dateTime': DateTime.now(),
        });

        // Update reservation
        updateReservation(reservation['id'], {'partySize': 4});

        // Verify update
        expect(getReservation(reservation['id'])?['partySize'], 4);
      });

      test(
          'Should throw an exception when attempting to update a non-existent reservation',
          () {
        expect(
          () => updateReservation(999, {'partySize': 5}),
          throwsA(isA<Exception>()),
        );
      });
    });

    // Unit 3: Reservation Deletion Tests
    group('Reservation Deletion Tests', () {
      test('Should successfully delete an existing reservation', () {
        final reservation = addReservation({
          'customerName': 'Deletion Test User',
          'partySize': 3,
          'dateTime': DateTime.now(),
        });

        // Delete the reservation
        deleteReservation(reservation['id']);

        // Verify deletion
        expect(getReservation(reservation['id']), isNull);
      });

      test(
          'Should throw an exception when attempting to delete a non-existent reservation',
          () {
        expect(
          () => deleteReservation(999),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
