// lib/data/models/user_model.dart
import '../../core/enums/user_role.dart';

class UserModel {
  final String id;
  final String email;
  final String nombre;
  final String apellido;
  final UserRole role;
  final String? telefono;
  final String? dni;
  final String? empresaId;
  final String? busId;
  final String? busNumber;
  final String? busPlate;

  UserModel({
    required this.id,
    required this.email,
    required this.nombre,
    required this.apellido,
    required this.role,
    this.telefono,
    this.dni,
    this.empresaId,
    this.busId,
    this.busNumber,
    this.busPlate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['correo'] ?? json['email'] ?? '',
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      role: UserRole.fromString(json['role'] ?? 'USER'),
      telefono: json['telefono'],
      dni: json['dni'],
      empresaId:
          json['empresa_id']?.toString() ?? json['empresaId']?.toString(),
      busId: json['bus_id']?.toString() ?? json['busId']?.toString(),
      busNumber: json['bus_number'] ?? json['busNumber'],
      busPlate: json['bus_plate'] ?? json['busPlate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'correo': email,
      'nombre': nombre,
      'apellido': apellido,
      'role': role.name.toUpperCase(),
      'telefono': telefono,
      'dni': dni,
      'empresa_id': empresaId,
      'bus_id': busId,
      'bus_number': busNumber,
      'bus_plate': busPlate,
    };
  }

  bool get isEmpresa => role == UserRole.empresa;
  bool get isChofer => role == UserRole.chofer;
  bool get isUser => role == UserRole.user;
}
