class SplitPlan {
  final int startDate;
  final int endDate;
  final Map<int, String> split;
  final Map<String, String> overrides;

  SplitPlan({
    this.startDate = 0,
    this.endDate = 0,
    this.split = const {},
    this.overrides = const {},
  });

  factory SplitPlan.fromMap(Map<String, dynamic> map) {
    final rawSplit = map['split'] as Map?;
    final splitMap = <int, String>{};
    if (rawSplit != null) {
      rawSplit.forEach((k, v) {
        final keyInt = int.tryParse(k.toString());
        if (keyInt != null) {
          splitMap[keyInt] = v.toString();
        }
      });
    }

    final rawOverrides = map['overrides'] as Map?;
    final overridesMap = <String, String>{};
    if (rawOverrides != null) {
      rawOverrides.forEach((k, v) {
        overridesMap[k.toString()] = v.toString();
      });
    }

    return SplitPlan(
      startDate: (map['startDate'] as num?)?.toInt() ?? 0,
      endDate: (map['endDate'] as num?)?.toInt() ?? 0,
      split: splitMap,
      overrides: overridesMap,
    );
  }

  Map<String, dynamic> toMap() {
    final splitStringMap = split.map((k, v) => MapEntry(k.toString(), v));
    return {
      'startDate': startDate,
      'endDate': endDate,
      'split': splitStringMap,
      'overrides': overrides,
    };
  }

  SplitPlan copyWith({
    int? startDate,
    int? endDate,
    Map<int, String>? split,
    Map<String, String>? overrides,
  }) {
    return SplitPlan(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      split: split ?? this.split,
      overrides: overrides ?? this.overrides,
    );
  }
}
