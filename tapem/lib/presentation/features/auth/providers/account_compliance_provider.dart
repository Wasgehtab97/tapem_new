import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_provider.dart';

class AccountComplianceException implements Exception {
  const AccountComplianceException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => code == null ? message : '$code: $message';
}

class AccountExportResult {
  const AccountExportResult({
    required this.requestId,
    required this.downloadUrl,
    required this.expiresInSeconds,
    required this.filePath,
    required this.fileSizeBytes,
    required this.estimatedRows,
  });

  final String requestId;
  final String downloadUrl;
  final int expiresInSeconds;
  final String filePath;
  final int fileSizeBytes;
  final int estimatedRows;

  factory AccountExportResult.fromMap(Map<String, dynamic> json) {
    return AccountExportResult(
      requestId: (json['request_id'] as String?) ?? '',
      downloadUrl: (json['download_url'] as String?) ?? '',
      expiresInSeconds: (json['expires_in_seconds'] as num?)?.toInt() ?? 0,
      filePath: (json['file_path'] as String?) ?? '',
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
      estimatedRows: (json['estimated_rows'] as num?)?.toInt() ?? 0,
    );
  }
}

class AccountComplianceService {
  AccountComplianceService(this._ref);

  final Ref _ref;

  SupabaseClient get _client => _ref.read(supabaseClientProvider);

  Future<String> _requireAccessToken() async {
    final session = _client.auth.currentSession;
    final token = session?.accessToken;
    if (token != null && token.isNotEmpty) return token;

    final refreshed = await _client.auth.refreshSession();
    final refreshedToken = refreshed.session?.accessToken;
    if (refreshedToken != null && refreshedToken.isNotEmpty) {
      return refreshedToken;
    }

    throw const AccountComplianceException('Authentication required.');
  }

  Future<AccountExportResult> exportMyData() async {
    final token = await _requireAccessToken();

    final response = await _client.functions.invoke(
      'dsr-export-account-data',
      headers: {'Authorization': 'Bearer $token'},
      body: const {'format': 'json'},
    );

    final payload = _toMap(response.data);
    if (response.status != 200 || payload['ok'] != true) {
      final code = payload['code'] as String?;
      final message =
          (payload['error'] as String?) ??
          'Export failed with HTTP ${response.status}.';
      throw AccountComplianceException(message, code: code);
    }

    final result = AccountExportResult.fromMap(payload);
    if (result.downloadUrl.isEmpty) {
      throw const AccountComplianceException(
        'Export succeeded but no download URL was returned.',
      );
    }
    return result;
  }

  Future<void> deleteMyAccount({required String confirmationText}) async {
    if (confirmationText.trim().toUpperCase() != 'DELETE') {
      throw const AccountComplianceException(
        'Please type DELETE to confirm account deletion.',
      );
    }

    final token = await _requireAccessToken();

    final response = await _client.functions.invoke(
      'dsr-delete-account',
      headers: {'Authorization': 'Bearer $token'},
      body: {'confirmation_text': confirmationText.trim().toUpperCase()},
    );

    final payload = _toMap(response.data);
    if (response.status != 200 || payload['ok'] != true) {
      final code = payload['code'] as String?;
      final message =
          (payload['error'] as String?) ??
          'Account deletion failed with HTTP ${response.status}.';
      throw AccountComplianceException(message, code: code);
    }

    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // Account is already deleted server-side. Local sign-out may fail on an
      // expired token race and is safe to ignore.
    }
  }

  Map<String, dynamic> _toMap(Object? raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }
}

final accountComplianceServiceProvider = Provider<AccountComplianceService>(
  AccountComplianceService.new,
);
