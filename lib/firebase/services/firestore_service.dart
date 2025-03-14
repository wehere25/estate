import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/property/data/models/property_dto.dart';

abstract class FirestoreService {
  Future<PropertyDto?> getProperty(String id);
  Future<void> deleteProperty(String id);
  Future<void> updateProperty(String id, Map<String, dynamic> data);
  Future<QuerySnapshot> queryCollection(
    String collection, {
    required Query Function(Query) queryBuilder,
    int? limit,
    DocumentSnapshot? startAfter,
  });
  Future<DocumentSnapshot> getDocument(String collection, String id);
  Future<DocumentReference> addDocument(
    String collection,
    Map<String, dynamic> data,
  );
  Future<void> updateDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  );
  Future<void> deleteDocument(String collection, String id);
  Stream<QuerySnapshot> watchCollection(
    String collection, {
    Query Function(Query)? queryBuilder,
  });
}

class FirestoreServiceImpl implements FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreServiceImpl([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<PropertyDto?> getProperty(String id) async {
    final doc = await _firestore.collection('properties').doc(id).get();
    if (!doc.exists) return null;
    return PropertyDto.fromFirestore(doc);
  }

  @override
  Future<void> deleteProperty(String id) async {
    await _firestore.collection('properties').doc(id).delete();
  }

  @override
  Future<void> updateProperty(String id, Map<String, dynamic> data) async {
    await _firestore.collection('properties').doc(id).update(data);
  }

  @override
  Future<QuerySnapshot> queryCollection(
    String collection, {
    required Query Function(Query) queryBuilder,
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore.collection(collection);
    query = queryBuilder(query);
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.get();
  }

  @override
  Future<DocumentSnapshot> getDocument(String collection, String id) async {
    return _firestore.collection(collection).doc(id).get();
  }

  @override
  Future<DocumentReference> addDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    return _firestore.collection(collection).add(data);
  }

  @override
  Future<void> updateDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(collection).doc(id).update(data);
  }

  @override
  Future<void> deleteDocument(String collection, String id) async {
    await _firestore.collection(collection).doc(id).delete();
  }

  @override
  Stream<QuerySnapshot> watchCollection(
    String collection, {
    Query Function(Query)? queryBuilder,
  }) {
    Query query = _firestore.collection(collection);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }
}
