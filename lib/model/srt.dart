/// A single SRT record.
class SrtRecord {
  final int id;
  final String text;
  final int start;
  final int end;

  SrtRecord({
    required this.id,
    required this.text,
    required this.start,
    required this.end,
  });

  /// Converts milliseconds to an SRT timestamp string (HH:MM:SS,ms).
  String msecToString(int msec) {
    final d = Duration(milliseconds: msec);
    final s = d.toString();
    return s.substring(0, s.length - 3).padLeft(12, '0').replaceAll('.', ',');
  }

  /// Converts the record into the standard SRT block format as a list of strings.
  List<String> toTexts() => [
    id.toString(),
    '${msecToString(start)} --> ${msecToString(end)}',
    text,
    '',
  ];

  SrtRecord copyWith({int? id, String? text, int? start, int? end}) =>
      SrtRecord(
        id: id ?? this.id,
        text: text ?? this.text,
        start: start ?? this.start,
        end: end ?? this.end,
      );
}
