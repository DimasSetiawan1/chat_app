import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:chat_apps/data/local/isar_service.dart';
import 'package:chat_apps/data/model/isar_users_model.dart';
import 'package:chat_apps/data/remote/firestore/users_data_firestore.dart';
import 'package:chat_apps/data/model/user_model.dart';
import 'package:chat_apps/domain/entities/user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthUtils {
  // initialize firebase auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // initialize cloud firestore
  final UsersDataFirestore _usersDataFirestore = UsersDataFirestore();
  final IsarService _isarService = IsarService.instance;

  //Simple Service to check auth
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  // initialize for guest sign in
  bool isInitialized = false;

  Future<UserCredential?> linkAnonymousToEmail(
    String name,
    String email,
    String password,
    String role,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || !currentUser.isAnonymous) {
        throw Exception('No anonymous user to link');
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      final linkedUser = await currentUser.linkWithCredential(credential);

      // Update data user di Firestore dan Isar
      final userEntity = UsersModel(
        uid: linkedUser.user!.uid,
        email: email,
        name: name,
        avatarUrl: '',
        role: role,
        createdAt: DateTime.now().toIso8601String(),
        lastSeenAt: "",
      );
      await _usersDataFirestore.createUser(userEntity);
      await _isarService.cacheUser(
        IsarUser()
          ..avatarUrl = ''
          ..createdAt = DateTime.now().toIso8601String()
          ..lastSeenAt = DateTime.now().toIso8601String()
          ..uid = linkedUser.user!.uid
          ..email = email
          ..name = linkedUser.user!.displayName ?? name
          ..role = role,
      );

      return linkedUser;
    } catch (e) {
      log('Link failed: $e');
      return null;
    }
  }

  // sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userFromFirestore = await _usersDataFirestore.getUserByUid(
        userCredential.user!.uid,
      );
      await _isarService.cacheUser(
        IsarUser()
          ..uid = userFromFirestore!.uid
          ..avatarUrl = userFromFirestore.avatarUrl
          ..email = userFromFirestore.email
          ..name = userFromFirestore.name
          ..role = userFromFirestore.role
          ..createdAt = DateTime.now().toIso8601String()
          ..lastSeenAt = DateTime.now().toIso8601String(),
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      final s = (e.code.isNotEmpty ? e.code : (e.message ?? '')).toLowerCase();
      String message;
      switch (s) {
        case final v when v.contains('wrong-password'):
          message = 'Wrong password provided for that user';
          break;
        case final v when v.contains('user-not-found'):
          message = 'User not found';
          break;
        case final v when v.contains('invalid-email'):
          message = 'Invalid email address';
          break;
        case final v when v.contains('user-disabled'):
          message = 'User account has been disabled';
          break;
        case final v when v.contains('too-many-requests'):
          message = 'Too many requests, please try again later';
          break;
        case final v when v.contains('network-request-failed'):
          message = 'Network connection issue';
          break;
        default:
          message = 'Failed to sign in. Please try again';
      }
      log('Error in signInWithEmailAndPassword: ${e.code} - ${e.message}');
      return Future.error(message);
    } catch (e) {
      log('Error in signInWithEmailAndPassword: $e');
      return Future.error('Failed to sign in. Please try again later');
    }
  }

  // sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
    UsersModel user,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: user.email,
            password: password,
          );
      user = user.copyWith(uid: userCredential.user!.uid);
      await _usersDataFirestore.createUser(user);
      await _isarService.cacheUser(
        IsarUser()
          ..uid = userCredential.user!.uid
          ..role = user.role
          ..name = user.name
          ..avatarUrl = ''
          ..email = userCredential.user!.email ?? ''
          ..createdAt = DateTime.now().toIso8601String()
          ..lastSeenAt = DateTime.now().toIso8601String(),
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      final s = (e.code.isNotEmpty ? e.code : (e.message ?? '')).toLowerCase();
      String message;
      switch (s) {
        case final v when v.contains('email-already-in-use'):
          message = 'Email already registered';
          break;
        case final v when v.contains('invalid-email'):
          message = 'Invalid email address';
          break;
        case final v when v.contains('weak-password'):
          message = 'Weak password';
          break;
        case final v when v.contains('operation-not-allowed'):
          message = 'Operation not allowed';
          break;
        case final v when v.contains('network-request-failed'):
          message = 'Network connection issue';
          break;
        default:
          message = 'Failed to sign up. Please try again later';
      }
      log('Error in signUpWithEmailAndPassword: ${e.code} - ${e.message}');
      return Future.error(message);
    } catch (e) {
      log('Error in signUpWithEmailAndPassword: $e');
      return Future.error('Failed to sign up. Please try again later');
    }
  }

  // Sign in Guest
  Future<UsersModel?> signInAnonymously() async {
    try {
      if (isInitialized) {
        log('Guest sign-in already in progress. Ignoring duplicate request.');
        return null;
      }
      final userFromCache = await _isarService.getCachedUser();
      log('userFromCache: ${userFromCache?.uid}');
      isInitialized = true;
      if (userFromCache != null) {
        log('User already signed in as guest: ${userFromCache.uid}');
        final user = UsersModel(
          uid: userFromCache.id.toString(),
          name: "Guest_${math.Random().nextInt(1000)}",
          avatarUrl: '',
          role: 'guest',
          email: '',
          createdAt: DateTime.now().toIso8601String(),
          lastSeenAt: DateTime.now().toIso8601String(),
        );
        isInitialized = false;
        return user;
      }

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInAnonymously()
          .whenComplete(() => isInitialized = false);
      await _isarService.cacheUser(
        IsarUser()
          ..uid = userCredential.user!.uid
          ..role = 'guest'
          ..name = "Guest_${math.Random().nextInt(1000)}"
          ..avatarUrl = ''
          ..email = userCredential.user!.email ?? ''
          ..createdAt = DateTime.now().toIso8601String()
          ..lastSeenAt = DateTime.now().toIso8601String(),
      );

      if (userCredential.user != null) {
        log('Signed in anonymously as user: ${userCredential.user!.uid}');
      } else {
        log('Anonymous sign-in failed: No user returned');
      }

      final userData = UsersModel(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
        name: 'Guest_${math.Random().nextInt(1000)}',
        avatarUrl: '',
        lastSeenAt: DateTime.now().toIso8601String(),
        role: 'guest',
        createdAt: DateTime.now().toIso8601String(),
      );

      _usersDataFirestore.createUser(userData);

      return userData;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        log(
          'Anonymous sign-in is not enabled. Enable it in the Firebase console.',
        );
      } else {
        log('Error during anonymous sign-in: ${e.message}');
      }
      return Future.error('Gagal masuk sebagai tamu. Silakan coba lagi');
    } catch (e) {
      log('Unexpected error during anonymous sign-in: $e');
      return Future.error('Gagal masuk sebagai tamu. Silakan coba lagi');
    }
  }

  // sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      log('Error in signOut: $e');
    }
  }
}
