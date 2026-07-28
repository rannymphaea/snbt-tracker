// lib/services/cloud_sync.dart -- Firestore sync (offline-first: SQLite is source of truth)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../data/repository.dart';
import '../models/models.dart';

class CloudSync {
  static final _fs = FirebaseFirestore.instance;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static DocumentReference? _userDoc() {
    final uid = _uid;
    if (uid == null) return null;
    return _fs.collection('users').doc(uid);
  }

  // ── Push individual records to Firestore ─────────────────────────────────

  static Future<void> pushCheckin(DailyCheckin c) async {
    try {
      await _userDoc()
          ?.collection('checkins')
          .doc(c.id)
          .set(c.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('CloudSync pushCheckin: $e');
    }
  }

  static Future<void> pushTryout(TryoutScore t) async {
    try {
      await _userDoc()
          ?.collection('tryouts')
          .doc(t.id)
          .set(t.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('CloudSync pushTryout: $e');
    }
  }

  static Future<void> pushXp(UserXp xp) async {
    try {
      await _userDoc()
          ?.collection('meta')
          .doc('xp')
          .set(xp.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('CloudSync pushXp: $e');
    }
  }

  static Future<void> pushTargetPtn(TargetPtn t) async {
    try {
      await _userDoc()
          ?.collection('meta')
          .doc('target_ptn')
          .set(t.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('CloudSync pushTargetPtn: $e');
    }
  }

  static Future<void> pushProgress(ProgressModel p) async {
    try {
      await _userDoc()
          ?.collection('progress')
          .doc(p.topicId)
          .set({
            'topic_id': p.topicId,
            'pelajari': p.pelajari ? 1 : 0,
            'latihan': p.latihan ? 1 : 0,
            'review': p.review ? 1 : 0,
            'catatan': p.catatan,
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('CloudSync pushProgress: $e');
    }
  }

  // ── Pull all from Firestore into local SQLite (called on login) ──────────

  static Future<void> pullAll() async {
    if (_uid == null) return;
    try {
      await Future.wait([
        _pullCheckins(),
        _pullTryouts(),
        _pullXp(),
        _pullTargetPtn(),
        _pullProgress(),
      ]);
      debugPrint('CloudSync: pull complete');
    } catch (e) {
      debugPrint('CloudSync pullAll: $e');
    }
  }

  static Future<void> _pullCheckins() async {
    final snap = await _userDoc()?.collection('checkins').get();
    if (snap == null) return;
    for (final doc in snap.docs) {
      try {
        final c = DailyCheckin.fromMap(doc.data());
        await CheckinRepo.upsert(c);
      } catch (_) {}
    }
  }

  static Future<void> _pullTryouts() async {
    final snap = await _userDoc()?.collection('tryouts').get();
    if (snap == null) return;
    for (final doc in snap.docs) {
      try {
        final t = TryoutScore.fromMap(doc.data());
        await TryoutScoreRepo.upsert(t);
      } catch (_) {}
    }
  }

  static Future<void> _pullXp() async {
    final snap = await _userDoc()?.collection('meta').doc('xp').get();
    if (snap == null || !snap.exists) return;
    try {
      final xp = UserXp.fromMap(snap.data()!);
      await XpRepo.set(xp);
    } catch (_) {}
  }

  static Future<void> _pullTargetPtn() async {
    final snap =
        await _userDoc()?.collection('meta').doc('target_ptn').get();
    if (snap == null || !snap.exists) return;
    try {
      final t = TargetPtn.fromMap(snap.data()!);
      await TargetPtnRepo.set(t);
    } catch (_) {}
  }

  static Future<void> _pullProgress() async {
    final snap = await _userDoc()?.collection('progress').get();
    if (snap == null) return;
    for (final doc in snap.docs) {
      try {
        final data = doc.data();
        final p = ProgressModel(
          topicId: data['topic_id'] as String? ?? doc.id,
          pelajari: (data['pelajari'] as int?) == 1,
          latihan: (data['latihan'] as int?) == 1,
          review: (data['review'] as int?) == 1,
          catatan: data['catatan'] as String? ?? '',
        );
        await ProgressRepoSync.upsert(p);
      } catch (_) {}
    }
  }

  // ── Push everything local to Firestore (full backup) ────────────────────

  static Future<void> pushAll() async {
    if (_uid == null) return;
    try {
      final checkins = await CheckinRepo.getAll();
      final tryouts = await TryoutScoreRepo.getAll();
      final xp = await XpRepo.get();
      final target = await TargetPtnRepo.get();

      final batch = _fs.batch();
      final userRef = _userDoc()!;

      for (final c in checkins) {
        batch.set(userRef.collection('checkins').doc(c.id),
            c.toMap(), SetOptions(merge: true));
      }
      for (final t in tryouts) {
        batch.set(userRef.collection('tryouts').doc(t.id),
            t.toMap(), SetOptions(merge: true));
      }
      if (xp != null) {
        batch.set(userRef.collection('meta').doc('xp'),
            xp.toMap(), SetOptions(merge: true));
      }
      if (target != null) {
        batch.set(userRef.collection('meta').doc('target_ptn'),
            target.toMap(), SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('CloudSync: pushAll complete');
    } catch (e) {
      debugPrint('CloudSync pushAll: $e');
    }
  }
}
