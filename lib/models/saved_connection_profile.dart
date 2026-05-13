/// Local-only reference row for endpoints the user applies in another VPN or proxy client.
final class SavedConnectionProfile {
  const SavedConnectionProfile({
    required this.id,
    required this.label,
    this.protocolNote = '',
    this.host = '',
    this.port,
    this.notes = '',
  });

  final String id;
  final String label;
  final String protocolNote;
  final String host;
  final int? port;
  final String notes;

  SavedConnectionProfile copyWith({
    String? id,
    String? label,
    String? protocolNote,
    String? host,
    int? port,
    bool clearPort = false,
    String? notes,
  }) {
    return SavedConnectionProfile(
      id: id ?? this.id,
      label: label ?? this.label,
      protocolNote: protocolNote ?? this.protocolNote,
      host: host ?? this.host,
      port: clearPort ? null : (port ?? this.port),
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'protocolNote': protocolNote,
    'host': host,
    'port': port,
    'notes': notes,
  };

  static SavedConnectionProfile? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final id = m['id']?.toString();
    final label = m['label']?.toString();
    if (id == null || id.isEmpty || label == null || label.trim().isEmpty) {
      return null;
    }
    final portVal = m['port'];
    int? port;
    if (portVal is int) {
      port = portVal;
    } else if (portVal != null) {
      port = int.tryParse(portVal.toString());
    }
    return SavedConnectionProfile(
      id: id,
      label: label,
      protocolNote: m['protocolNote']?.toString() ?? '',
      host: m['host']?.toString() ?? '',
      port: port,
      notes: m['notes']?.toString() ?? '',
    );
  }
}
