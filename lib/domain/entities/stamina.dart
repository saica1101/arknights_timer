class Stamina {
  final int level;
  final int current;
  final int max;

  Stamina({required this.level, required this.current, required this.max});

  Stamina copyWith({int? level, int? current, int? max}) {
    return Stamina(
      level: level ?? this.level,
      current: current ?? this.current,
      max: max ?? this.max,
    );
  }
}
