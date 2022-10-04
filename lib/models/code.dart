class Code {
  final String value;
  final DateTime createdAt;
  final bool used;
  final DateTime? usedAt;
  final DateTime? expiresAt;

  Code({
    required this.value,
    required this.createdAt,
    this.used = false,
    this.usedAt,
    this.expiresAt,
  });

  Code copyWith({
    final String? value,
    final DateTime? createdAt,
    final bool? used,
    final DateTime? usedAt,
    final DateTime? expiresAt,
  }) =>
      Code(
        value: value ?? this.value,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
        used: used ?? this.used,
        usedAt: usedAt ?? this.usedAt,
      );
}
