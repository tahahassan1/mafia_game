import 'package:equatable/equatable.dart';

import 'validation_reason.dart';

sealed class ValidationResult extends Equatable {
  const ValidationResult();
}

final class Valid extends ValidationResult {
  const Valid();

  @override
  List<Object> get props => [];
}

final class Invalid extends ValidationResult {
  const Invalid(this.reason);

  final ValidationReason reason;

  @override
  List<Object> get props => [reason];
}
