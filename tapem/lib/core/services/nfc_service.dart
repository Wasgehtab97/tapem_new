import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

import '../utils/logger.dart';

// ─── Scan result ──────────────────────────────────────────────────────────────

sealed class NfcScanResult {
  const NfcScanResult();
}

final class NfcScanSuccess extends NfcScanResult {
  const NfcScanSuccess({required this.uid, this.equipmentId});
  final String uid;
  final String? equipmentId;
}

final class NfcScanFailure extends NfcScanResult {
  const NfcScanFailure(this.reason);
  final String reason;
}

final class NfcScanCancelled extends NfcScanResult {
  const NfcScanCancelled();
}

// ─── Write result ─────────────────────────────────────────────────────────────

sealed class NfcWriteResult {
  const NfcWriteResult();
}

final class NfcWriteSuccess extends NfcWriteResult {
  const NfcWriteSuccess();
}

final class NfcWriteFailure extends NfcWriteResult {
  const NfcWriteFailure(this.reason);
  final String reason;
}

// ─── NFC Service ──────────────────────────────────────────────────────────────

/// Provides NFC capabilities:
///
/// * [startForegroundSession] — continuous reading while app is open.
///   Silent on Android; shows system sheet on iOS (restarts automatically).
/// * [scanTagOnce] — one-shot scan (used for admin tag assignment).
/// * [writeEquipmentTag] — writes a Tap'em NDEF URL to a tag (admin only).
class NfcService {
  // iOS CoreNFC sessions auto-invalidate after ~60 s idle; restart at 55 s.
  static const _iosRestartInterval = Duration(seconds: 55);
  static const _pollingOptions = <NfcPollingOption>{
    NfcPollingOption.iso14443,
    NfcPollingOption.iso15693,
    NfcPollingOption.iso18092,
  };

  bool _foregroundActive = false;
  Timer? _iosRestartTimer;
  void Function(String? equipmentId, String uid)? _foregroundCallback;

  // ─── Public API ─────────────────────────────────────────────────────────────

  Future<bool> isAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Starts a continuous NFC session that fires [onTag] for every detected tag.
  ///
  /// Android: silent foreground dispatch — no UI, no user action needed.
  /// iOS: CoreNFC system sheet appears; auto-restarts after each scan.
  Future<void> startForegroundSession({
    required void Function(String? equipmentId, String uid) onTag,
  }) async {
    if (_foregroundActive) return;
    _foregroundActive = true;
    _foregroundCallback = onTag;
    await _startOrRestartSession();
  }

  /// Stops the foreground session started by [startForegroundSession].
  Future<void> stopForegroundSession() async {
    _foregroundActive = false;
    _foregroundCallback = null;
    _iosRestartTimer?.cancel();
    _iosRestartTimer = null;
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }

  /// One-shot scan. Returns when a tag is detected or an error occurs.
  /// Used by the workout start hub (iOS) and admin screens.
  Future<NfcScanResult> scanTagOnce({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final completer = Completer<NfcScanResult>();
    try {
      if (!await isAvailable()) {
        return const NfcScanFailure('NFC not available on this device');
      }

      final timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          unawaited(NfcManager.instance.stopSession());
          completer.complete(const NfcScanFailure('Scan timed out'));
        }
      });

      await NfcManager.instance.startSession(
        pollingOptions: _pollingOptions,
        onDiscovered: (tag) async {
          timer.cancel();
          try {
            final uid = _extractUid(tag);
            final eqId = await _parseEquipmentId(tag);
            if (!completer.isCompleted) {
              completer.complete(NfcScanSuccess(uid: uid, equipmentId: eqId));
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.complete(NfcScanFailure(e.toString()));
            }
          } finally {
            await NfcManager.instance.stopSession();
          }
        },
      );
      return completer.future;
    } catch (e) {
      AppLogger.e('NFC scanTagOnce error', e);
      return NfcScanFailure(e.toString());
    }
  }

  /// Cancels an in-progress [scanTagOnce].
  Future<void> cancelScan() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }

  /// Admin-only: starts a session, calls [onTagReady] with the raw [NfcTag]
  /// so the caller can write NDEF data before the session is closed.
  Future<NfcScanResult> scanForWrite({
    required Future<void> Function(NfcTag tag, String uid) onTagReady,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final completer = Completer<NfcScanResult>();
    try {
      if (!await isAvailable()) {
        return const NfcScanFailure('NFC not available on this device');
      }

      final timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          unawaited(NfcManager.instance.stopSession());
          completer.complete(const NfcScanFailure('Scan timed out'));
        }
      });

      await NfcManager.instance.startSession(
        pollingOptions: _pollingOptions,
        onDiscovered: (tag) async {
          timer.cancel();
          try {
            final uid = _extractUid(tag);
            await onTagReady(tag, uid);
            if (!completer.isCompleted) {
              completer.complete(
                NfcScanSuccess(
                  uid: uid,
                  equipmentId: await _parseEquipmentId(tag),
                ),
              );
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.complete(NfcScanFailure(e.toString()));
            }
          } finally {
            await NfcManager.instance.stopSession();
          }
        },
      );
      return completer.future;
    } catch (e) {
      AppLogger.e('NFC scanForWrite error', e);
      return NfcScanFailure(e.toString());
    }
  }

  /// Writes a Tap'em equipment NDEF URL (`tapem://e/<equipmentId>`) to [tag].
  /// Must be called within a [scanForWrite] callback while the session is open.
  Future<NfcWriteResult> writeEquipmentTag(
    NfcTag tag,
    String equipmentId,
  ) async {
    try {
      final ndefAndroid = NdefAndroid.from(tag);
      final ndefIos = NdefIos.from(tag);
      if (ndefAndroid == null && ndefIos == null) {
        return const NfcWriteFailure('Tag unterstützt kein NDEF');
      }

      final message = _buildEquipmentMessage(equipmentId);

      if (ndefAndroid != null) {
        if (!ndefAndroid.isWritable) {
          return const NfcWriteFailure('Tag ist schreibgeschützt');
        }
        await ndefAndroid.writeNdefMessage(message);
        return const NfcWriteSuccess();
      }

      if (ndefIos != null) {
        if (ndefIos.status == NdefStatusIos.readOnly) {
          return const NfcWriteFailure('Tag ist schreibgeschützt');
        }
        if (ndefIos.status == NdefStatusIos.notSupported) {
          return const NfcWriteFailure('Tag unterstützt kein NDEF');
        }
        await ndefIos.writeNdef(message);
        return const NfcWriteSuccess();
      }

      return const NfcWriteFailure('Unbekannter NDEF-Status');
    } catch (e) {
      AppLogger.e('NFC write error', e);
      return NfcWriteFailure(e.toString());
    }
  }

  // ─── Private ────────────────────────────────────────────────────────────────

  Future<void> _startOrRestartSession() async {
    if (!_foregroundActive) return;
    try {
      await NfcManager.instance.startSession(
        pollingOptions: _pollingOptions,
        onDiscovered: (tag) async {
          try {
            final uid = _extractUid(tag);
            final eqId = await _parseEquipmentId(tag);
            _foregroundCallback?.call(eqId, uid);
          } catch (e) {
            AppLogger.e('Foreground NFC tag error', e);
          }

          if (Platform.isIOS) {
            // iOS: stop this session and restart for the next scan.
            await NfcManager.instance.stopSession();
            _iosRestartTimer?.cancel();
            Timer(const Duration(milliseconds: 500), () {
              if (_foregroundActive) unawaited(_startOrRestartSession());
            });
          }
          // Android: do NOT call stopSession — foreground dispatch stays active.
        },
      );

      if (Platform.isIOS) {
        // Restart before the 60 s CoreNFC timeout.
        _iosRestartTimer?.cancel();
        _iosRestartTimer = Timer(_iosRestartInterval, () {
          if (_foregroundActive) {
            unawaited(NfcManager.instance.stopSession());
            unawaited(_startOrRestartSession());
          }
        });
      }
    } catch (e) {
      AppLogger.e('NFC foreground session error', e);
      if (_foregroundActive) {
        Timer(const Duration(seconds: 3), () {
          if (_foregroundActive) unawaited(_startOrRestartSession());
        });
      }
    }
  }

  /// Parses the equipment ID from an NDEF URI record written by Tap'em.
  /// Returns null if no valid `tapem://e/<id>` record is found.
  Future<String?> _parseEquipmentId(NfcTag tag) async {
    try {
      NdefMessage? message;
      final ndefAndroid = NdefAndroid.from(tag);
      if (ndefAndroid != null) {
        message = ndefAndroid.cachedNdefMessage;
        message ??= await ndefAndroid.getNdefMessage();
      } else {
        final ndefIos = NdefIos.from(tag);
        if (ndefIos == null) return null;
        message = ndefIos.cachedNdefMessage;
        message ??= await ndefIos.readNdef();
      }

      if (message == null || message.records.isEmpty) return null;

      for (final record in message.records) {
        // NFC Well-Known URI record: TNF=0x01, type=0x55 ('U')
        if (record.typeNameFormat == TypeNameFormat.wellKnown &&
            record.type.length == 1 &&
            record.type.first == 0x55) {
          final payload = record.payload;
          if (payload.isEmpty) continue;
          final prefixCode = payload.first;
          final rest = String.fromCharCodes(payload.skip(1));
          final prefix = _uriPrefixMap[prefixCode] ?? '';
          final fullUri = '$prefix$rest';
          if (fullUri.startsWith('tapem://e/')) {
            final id = fullUri.substring('tapem://e/'.length).trim();
            if (id.isNotEmpty) return id;
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// NDEF URI prefix abbreviation codes per NFC Forum URI Record Type Definition.
  static const _uriPrefixMap = <int, String>{
    0x00: '',
    0x01: 'http://www.',
    0x02: 'https://www.',
    0x03: 'http://',
    0x04: 'https://',
    0x05: 'tel:',
    0x06: 'mailto:',
    0x13: 'urn:',
  };

  String _extractUid(NfcTag tag) {
    final androidTag = NfcTagAndroid.from(tag);
    if (androidTag != null && androidTag.id.isNotEmpty) {
      return _bytesToHex(androidTag.id);
    }

    final miFare = MiFareIos.from(tag);
    if (miFare != null && miFare.identifier.isNotEmpty) {
      return _bytesToHex(miFare.identifier);
    }
    final iso15693 = Iso15693Ios.from(tag);
    if (iso15693 != null && iso15693.identifier.isNotEmpty) {
      return _bytesToHex(iso15693.identifier);
    }
    final iso7816 = Iso7816Ios.from(tag);
    if (iso7816 != null && iso7816.identifier.isNotEmpty) {
      return _bytesToHex(iso7816.identifier);
    }
    final feliCa = FeliCaIos.from(tag);
    if (feliCa != null && feliCa.currentIDm.isNotEmpty) {
      return _bytesToHex(feliCa.currentIDm);
    }
    throw Exception('Unsupported NFC tag type');
  }

  NdefMessage _buildEquipmentMessage(String equipmentId) {
    final uri = 'tapem://e/$equipmentId';
    return NdefMessage(records: [_buildUriRecord(uri)]);
  }

  NdefRecord _buildUriRecord(String uri) {
    final payload = Uint8List.fromList(<int>[0x00, ...uri.codeUnits]);
    return NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x55]),
      identifier: Uint8List(0),
      payload: payload,
    );
  }

  String _bytesToHex(List<int> bytes) => bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join()
      .toUpperCase();
}

final nfcServiceProvider = Provider<NfcService>((_) => NfcService());

final nfcAvailableProvider = FutureProvider<bool>((ref) async {
  return ref.watch(nfcServiceProvider).isAvailable();
});
