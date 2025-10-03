enum UserRole {
  empresa,
  chofer,
  user;

  String get displayName {
    switch (this) {
      case UserRole.empresa:
        return 'Empresa';
      case UserRole.chofer:
        return 'Chofer';
      case UserRole.user:
        return 'Usuario';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toUpperCase()) {
      case 'EMPRESA':
        return UserRole.empresa;
      case 'CHOFER':
      case 'DRIVER':
        return UserRole.chofer;
      case 'USUARIO':
      case 'USER':
        return UserRole.user;
      default:
        throw Exception('Rol no válido: $role');
    }
  }
}