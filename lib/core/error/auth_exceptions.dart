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

class TooManyRequestException implements Exception {
  final String error = "Slow down... So many request. I cant handle all";

  @override
  String toString() {
    return error;
  }
}

class WeakPasswordAuthException implements Exception {
  final String error =
      "This password cracked last weak by a baby :) Make it stronger";

  @override
  String toString() {
    return error;
  }
}

class EmailAlreadyInUseAuthException implements Exception {
  final String error = "Email already in use";

  @override
  String toString() {
    return error;
  }
}

class InvalidEmailAuthException implements Exception {
  final String error =
      "This mail address is not like an email. If im not wrong ";

  @override
  String toString() {
    return error;
  }
}

class UserNotLoggedInAuthException implements Exception {
  final String error = "User not logged in";

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

class InvalidVerificationCodeException implements Exception {
  final String error =
      "I didnt give you this code. Please write code that has been sent to you";

  @override
  String toString() {
    return error;
  }
}

class InvalidVerificationIdException implements Exception {
  final String error = "Verification is not valid. Idk why";

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

class PasswdResetException implements Exception {
  String error =
      "This isnt your issue. Its my issue for not giving you acces. Sorry";

  PasswdResetException({required this.error});

  @override
  String toString() {
    List msg = error.split(' ');
    msg.removeAt(0);

    return msg.join(' ');
  }
}

class RequiresRecentLoginException implements Exception {
  final String error = "You should be recently login for doing this";

  @override
  String toString() {
    return error;
  }
}
