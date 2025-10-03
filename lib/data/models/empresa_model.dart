class EmpresaModel {
  final String id;
  final String nombre;
  final String telefono;

  EmpresaModel({
    required this.id,
    required this.nombre,
    required this.telefono,
  });

  factory EmpresaModel.fromJson(Map<String, dynamic> json) {
    return EmpresaModel(
      id: json['id'].toString(),
      nombre: json['nombre'] ?? '',
      telefono: json['telefono'] ?? '',
    );
  }
}