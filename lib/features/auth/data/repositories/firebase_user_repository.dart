import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../profile/domain/models/user_profile.dart';
import '../../domain/repositories/user_repository.dart';

class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;

  FirebaseUserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<UserProfile?> watchUserProfile(String uid) {
    final docRef = _firestore.collection('users').doc(uid);
    return docRef.snapshots().asyncMap((snapshot) async {
      if (!snapshot.exists || snapshot.data() == null) {
        // Automatically create and seed default user profile if the current authenticated user matches this uid
        final firebaseUser = fb.FirebaseAuth.instance.currentUser;
        if (firebaseUser != null && firebaseUser.uid == uid) {
          final now = DateTime.now();
          final email = firebaseUser.email ?? '';
          final name = firebaseUser.displayName ?? email.split('@')[0];
          
          String role = 'Employee';
          String dept = 'Engineering';
          String org = 'Fraylon Technologies LLP';
          
          if (email.startsWith('superadmin@')) {
            role = 'Super Admin';
            dept = 'HQ';
            org = 'Fraylon Global Inc';
          } else if (email.startsWith('orgadmin@')) {
            role = 'Organization Admin';
            dept = 'Operations';
          } else if (email.startsWith('manager@')) {
            role = 'Manager';
            dept = 'Engineering';
          }
          
          final profile = UserProfile(
            uid: uid,
            name: name,
            email: email,
            role: role,
            phone: '',
            organizationId: role == 'Super Admin' ? 'org_global' : 'org_fraylon',
            departmentId: role == 'Super Admin' ? 'dept_hq' : (role == 'Organization Admin' ? 'dept_ops' : 'dept_engineering'),
            designation: role == 'Super Admin' ? 'System Director' : (role == 'Organization Admin' ? 'VP of Operations' : (role == 'Manager' ? 'Engineering Manager' : 'Software Engineer')),
            createdAt: now,
            lastLogin: now,
            status: 'Active',
            department: dept,
            organization: org,
            employeeId: 'EMP_${now.millisecondsSinceEpoch.toString().substring(7)}',
            joinedDate: now,
          );
          
          await docRef.set(profile.toMap());
          return profile;
        }
        return null;
      }
      return UserProfile.fromMap(snapshot.data()!..putIfAbsent('uid', () => uid));
    });
  }

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    final docRef = _firestore.collection('users').doc(uid);
    final doc = await docRef.get();
    if (!doc.exists || doc.data() == null) {
      final firebaseUser = fb.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null && firebaseUser.uid == uid) {
        final now = DateTime.now();
        final email = firebaseUser.email ?? '';
        final name = firebaseUser.displayName ?? email.split('@')[0];
        
        String role = 'Employee';
        String dept = 'Engineering';
        String org = 'Fraylon Technologies LLP';
        
        if (email.startsWith('superadmin@')) {
          role = 'Super Admin';
          dept = 'HQ';
          org = 'Fraylon Global Inc';
        } else if (email.startsWith('orgadmin@')) {
          role = 'Organization Admin';
          dept = 'Operations';
        } else if (email.startsWith('manager@')) {
          role = 'Manager';
          dept = 'Engineering';
        }
        
        final profile = UserProfile(
          uid: uid,
          name: name,
          email: email,
          role: role,
          phone: '',
          organizationId: role == 'Super Admin' ? 'org_global' : 'org_fraylon',
          departmentId: role == 'Super Admin' ? 'dept_hq' : (role == 'Organization Admin' ? 'dept_ops' : 'dept_engineering'),
          designation: role == 'Super Admin' ? 'System Director' : (role == 'Organization Admin' ? 'VP of Operations' : (role == 'Manager' ? 'Engineering Manager' : 'Software Engineer')),
          createdAt: now,
          lastLogin: now,
          status: 'Active',
          department: dept,
          organization: org,
          employeeId: 'EMP_${now.millisecondsSinceEpoch.toString().substring(7)}',
          joinedDate: now,
        );
        
        await docRef.set(profile.toMap());
        return profile;
      }
      return null;
    }
    return UserProfile.fromMap(doc.data()!..putIfAbsent('uid', () => uid));
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    await _firestore.collection('users').doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  @override
  Future<List<UserProfile>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .map((doc) => UserProfile.fromMap(doc.data()..putIfAbsent('uid', () => doc.id)))
        .toList();
  }

  @override
  Future<void> createUser(UserProfile profile) async {
    await _firestore.collection('users').doc(profile.uid).set(profile.toMap());
  }

  @override
  Future<void> updateUser(UserProfile profile) async {
    await _firestore.collection('users').doc(profile.uid).update(profile.toMap());
  }

  @override
  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
}
