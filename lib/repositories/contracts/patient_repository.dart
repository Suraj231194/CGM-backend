import 'dart:async';

import '../../models/optimus_models.dart';

/// Abstract contract for patient data operations.
/// Currently backed by a local development implementation.
/// Replace it with API calls when backend is ready.
abstract class PatientRepository {
  Future<List<Patient>> getPatients({String? doctorId});
  Future<Patient?> getPatientById(String id);
  Future<List<OptimusGlucoseReading>> getReadings({
    required String patientId,
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  });
  Future<OptimusGlucoseReading> addReading(OptimusGlucoseReading reading);
  Future<List<OptimusGlucoseReading>> addReadings({
    required String patientId,
    required List<OptimusGlucoseReading> readings,
  });
  Future<List<MealLog>> getMeals({required String patientId});
  Future<MealLog> addMeal(MealLog meal);
  Future<List<Sensor>> getSensors({required String patientId});
  Future<Sensor> registerSensor({
    required String patientId,
    required String serialNumber,
  });
  Future<List<AIInterpretation>> getInterpretations({
    required String patientId,
  });
  Future<List<Order>> getOrders({required String patientId});
  Future<Order> placeOrder(Order order);
}
