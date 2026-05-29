import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:american_sweets/firebase_options.dart';

class StorageUpload {
  static List<String?> _bucketCandidates() {
    final opts = DefaultFirebaseOptions.currentPlatform;
    final projectId = opts.projectId;
    final rawBucket = (opts.storageBucket ?? '').trim();

    final out = <String?>[];

    void addBucket(String? b) {
      final v = (b ?? '').trim();
      if (v.isEmpty) return;
      final normalized = v.startsWith('gs://') ? v.substring(5) : v;
      if (!out.contains(normalized)) out.add(normalized);
    }

    if (rawBucket.isNotEmpty && rawBucket.contains('.firebasestorage.app')) {
      addBucket(rawBucket.replaceAll('.firebasestorage.app', '.appspot.com'));
    }
    addBucket('$projectId.appspot.com');
    addBucket(rawBucket);
    addBucket('$projectId.firebasestorage.app');

    return out;
  }

  static Future<String> _getDownloadUrlWithRetry(Reference ref) async {
    final delays = <Duration>[
      const Duration(milliseconds: 250),
      const Duration(milliseconds: 500),
      const Duration(milliseconds: 900),
      const Duration(milliseconds: 1400),
      const Duration(milliseconds: 2200),
    ];

    FirebaseException? last;
    for (int i = 0; i <= delays.length; i++) {
      try {
        return await ref.getDownloadURL();
      } on FirebaseException catch (e) {
        last = e;
        if (e.code != 'object-not-found') rethrow;
        if (i >= delays.length) break;
        await Future.delayed(delays[i]);
      }
    }
    throw last ?? FirebaseException(plugin: 'storage', code: 'unknown');
  }

  static Future<String> uploadBytes(
    Uint8List bytes,
    String path, {
    String? contentType,
  }) async {
    final meta = SettableMetadata(contentType: contentType);
    Object? last;
    for (final bucket in _bucketCandidates()) {
      try {
        final storage = FirebaseStorage.instanceFor(bucket: bucket);
        final ref = storage.ref().child(path);
        await ref.putData(bytes, meta);
        return await _getDownloadUrlWithRetry(ref);
      } catch (e) {
        last = e;
      }
    }
    if (last is FirebaseException) throw last;
    throw FirebaseException(
        plugin: 'storage', code: 'unknown', message: last?.toString() ?? '');
  }

  static Future<String> uploadFile(
    File file,
    String path, {
    String? contentType,
  }) async {
    final meta = SettableMetadata(contentType: contentType);
    if (kIsWeb) throw FirebaseException(plugin: 'storage', code: 'web');
    Object? last;
    for (final bucket in _bucketCandidates()) {
      try {
        final storage = FirebaseStorage.instanceFor(bucket: bucket);
        final ref = storage.ref().child(path);
        await ref.putFile(file, meta);
        return await _getDownloadUrlWithRetry(ref);
      } catch (e) {
        last = e;
      }
    }
    if (last is FirebaseException) throw last;
    throw FirebaseException(
        plugin: 'storage', code: 'unknown', message: last?.toString() ?? '');
  }
}
