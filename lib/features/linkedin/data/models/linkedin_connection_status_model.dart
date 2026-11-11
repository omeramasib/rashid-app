import '../../domain/entities/linkedin_connection_status.dart';

class LinkedInConnectionStatusModel extends LinkedInConnectionStatus {
  const LinkedInConnectionStatusModel({
    required super.connected,
    required super.publishingEnabled,
    required super.reauthorizationRequired,
    required super.connectionStatus,
    super.expiresAt,
    super.name,
  });

  factory LinkedInConnectionStatusModel.fromJson(Map<String, dynamic> json) {
    final body = _objectBody(json);
    return LinkedInConnectionStatusModel(
      connected: body['connected'] == true,
      publishingEnabled: body['publishing_enabled'] == true,
      reauthorizationRequired: body['reauthorization_required'] == true,
      connectionStatus: _connectionState(body['connection_status']),
      expiresAt: _date(body['expires_at']),
      name: _text(body['name']),
    );
  }
}

class LinkedInJson {
  static Map<String, dynamic> objectBody(dynamic json) => _objectBody(json);

  static DateTime? date(dynamic value) => _date(value);

  static String? text(dynamic value) => _text(value);

  static String requiredText(dynamic value, String field) {
    final text = _text(value);
    if (text == null) {
      throw FormatException(field);
    }
    return text;
  }
}

Map<String, dynamic> _objectBody(dynamic json) {
  if (json is! Map) {
    throw const FormatException('linkedin_body');
  }
  final map = Map<String, dynamic>.from(json);
  final data = map['data'];
  if (data is Map &&
      !map.containsKey('connected') &&
      !map.containsKey('authorization_url') &&
      !map.containsKey('preview_id') &&
      !map.containsKey('post_url')) {
    return Map<String, dynamic>.from(data);
  }
  return map;
}

LinkedInConnectionState _connectionState(dynamic value) {
  switch (_text(value)) {
    case 'active':
      return LinkedInConnectionState.active;
    case 'expired':
      return LinkedInConnectionState.expired;
    case 'revoked':
      return LinkedInConnectionState.revoked;
    case 'reauthorization_required':
      return LinkedInConnectionState.reauthorizationRequired;
    case 'not_connected':
      return LinkedInConnectionState.notConnected;
    default:
      return LinkedInConnectionState.unknown;
  }
}

DateTime? _date(dynamic value) {
  final text = _text(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}

String? _text(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
}
