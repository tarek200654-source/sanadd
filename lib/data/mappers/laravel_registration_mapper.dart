import '../../domain/models/registration_data.dart';
import '../../domain/models/user_role.dart';

abstract final class LaravelRegistrationMapper {
  static Map<String, dynamic> toJson(
    RegistrationData data, {
    required String passwordConfirmation,
  }) => {
    'username': data.username.trim(),
    'first_name': data.firstName.trim(),
    'last_name': data.lastName.trim(),
    'email': data.email.trim().toLowerCase(),
    'password': data.password,
    'password_confirmation': passwordConfirmation,
    'role': data.role.value,
    'country': data.country.trim(),
    'region': data.region.trim(),
    'address': data.address.trim(),
    'phone_number': data.phoneNumber.trim(),
  };
}
