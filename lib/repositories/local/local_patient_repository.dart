import 'dart:async';

import '../../data/optimus_seed_data.dart';
import '../../models/optimus_models.dart';
import '../contracts/patient_repository.dart';

class LocalPatientRepository implements PatientRepository {
  @override
  Future<List<Patient>> getPatients({String? doctorId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (doctorId != null) {
      return optimusPatients.where((patient) {
        return patient.doctorId == doctorId;
      }).toList();
    }
    return optimusPatients;
  }

  @override
  Future<Patient?> getPatientById(String id) async {
    return optimusPatients.cast<Patient?>().firstWhere(
      (patient) => patient!.id == id,
      orElse: () => null,
    );
  }

  @override
  Future<List<OptimusGlucoseReading>> getReadings({
    required String patientId,
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return const [];
  }

  @override
  Future<OptimusGlucoseReading> addReading(
    OptimusGlucoseReading reading,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return reading;
  }

  @override
  Future<List<OptimusGlucoseReading>> addReadings({
    required String patientId,
    required List<OptimusGlucoseReading> readings,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return readings;
  }

  @override
  Future<List<MealLog>> getMeals({required String patientId}) async {
    return optimusMealLogs.where((meal) {
      return meal.patientId == patientId;
    }).toList();
  }

  @override
  Future<MealLog> addMeal(MealLog meal) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return meal;
  }

  @override
  Future<List<Sensor>> getSensors({required String patientId}) async {
    return optimusSensors.where((sensor) {
      return sensor.patientId == patientId;
    }).toList();
  }

  @override
  Future<Sensor> registerSensor({
    required String patientId,
    required String serialNumber,
  }) async {
    final sensors = await getSensors(patientId: patientId);
    final normalized = serialNumber.trim().toUpperCase();
    if (sensors.isEmpty) {
      return Sensor(
        id: 'local-$normalized',
        serialNumber: normalized,
        patientId: patientId,
        status: SensorStatus.active,
        batteryStatus: 100,
        connectionStatus: ConnectionStatus.connected,
      );
    }
    return sensors.firstWhere(
      (sensor) => sensor.serialNumber.toUpperCase() == normalized,
      orElse: () => sensors.first.copyWith(serialNumber: normalized),
    );
  }

  @override
  Future<List<AIInterpretation>> getInterpretations({
    required String patientId,
  }) async {
    return const [];
  }

  @override
  Future<List<Order>> getOrders({required String patientId}) async {
    return optimusOrders.where((order) {
      return order.patientId == patientId;
    }).toList();
  }

  @override
  Future<Order> placeOrder(Order order) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return order;
  }
}
