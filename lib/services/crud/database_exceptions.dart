// database exception
class DatabaseAlreadyOpenException implements Exception {}

class DatabaseIsNotOpen implements Exception {}

class UnableToGetDirectoryException implements Exception {}

// user exception
class UserAlreadyExists implements Exception {}

class CouldNotFindUser implements Exception {}

class CouldNotDeleteUser implements Exception {}

// expense and income exception ()
class CouldNotDeleteData implements Exception {}

class CouldNotFindData implements Exception {}

class CouldNotUpdateData implements Exception {}
