import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/local_auth_base.dart';

class _TestEvent extends LocalAuthEvent {
  const _TestEvent();
}

class _OtherEvent extends LocalAuthEvent {
  const _OtherEvent();
}

class _TestState extends LocalAuthState {
  const _TestState();
}

class _OtherState extends LocalAuthState {
  const _OtherState();
}

void main() {
  group('LocalAuthEvent', () {
    test('equality by runtime type', () {
      const a = _TestEvent();
      const b = _TestEvent();
      const c = _OtherEvent();

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('LocalAuthState', () {
    test('equality by runtime type', () {
      const a = _TestState();
      const b = _TestState();
      const c = _OtherState();

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
