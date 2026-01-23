class UserDisabledAuthException implements Exception {
  final String error = "User disabled";

  @override
  String toString() {
    return error;
  }
}

class WrongPasswordAuthException implements Exception {
  final String error = "Wrong password";

  @override
  String toString() {
    return error;
  }
}

class UserNotFoundAuthException implements Exception {
  final String error = "User not found";

  @override
  String toString() {
    return error;
  }
}

class GenericAuthException implements Exception {
  String? cause;
  GenericAuthException({this.cause});

  @override
  String toString() {
    return cause ?? "Unknown error";
  }
}

class FirebaseLogoutException implements Exception {
  final String error = "Firebase Logout has an error";

  @override
  String toString() {
    return error;
  }
}

class GoogleLogoutException implements Exception {
  final String error = "Gulugulu logout has an error.";

  @override
  String toString() {
    return error;
  }
}

class AccExistWithDifferentCredentialException implements Exception {
  final String error =
      "This account already exists by different provider. (like gooogle, email-paswd...)";

  @override
  String toString() {
    return error;
  }
}

class InvalidCredentialException implements Exception {
  final String error = "Something goes wrong. Only god knows what it is";

  @override
  String toString() {
    return error;
  }
}

class OperationNotAllowedException implements Exception {
  final String error =
      "This isnt your issue. Its my issue for not giving you acces. Sorry";

  @override
  String toString() {
    return error;
  }
}
