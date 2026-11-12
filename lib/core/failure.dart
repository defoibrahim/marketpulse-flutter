import 'package:equatable/equatable.dart';

/// A failure the UI can show as-is: [message] is always written for users,
/// never a raw exception string.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

/// The server could not be reached, or took too long to answer.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = "Can't reach the server. Check your connection and try again.",
  ]);
}

/// The server answered with an error status.
class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'The server ran into a problem. Please try again.',
  ]);
}

/// The server answered, but not with data the app understands.
class ParseFailure extends Failure {
  const ParseFailure([
    super.message = 'The server sent data the app could not read.',
  ]);
}

/// Anything else.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
