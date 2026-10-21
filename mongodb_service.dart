import 'package:mongo_dart/mongo_dart.dart';

class MongoDatabase {
  static Db? _db;

  static const String _connectionString =
      'mongodb://admin-1:YEKppf4Sn:8EK_3@ac-i6ob7yz-shard-00-00.woh4rh1.mongodb.net:27017,ac-i6ob7yz-shard-00-01.woh4rh1.mongodb.net:27017,ac-i6ob7yz-shard-00-02.woh4rh1.mongodb.net:27017/myDatabase?ssl=true&replicaSet=atlas-q6ymhc-shard-0&authSource=admin';

  static Future<void> connect() async {
    try {
      _db = await Db.create(_connectionString);
      await _db!.open();
      print('Connected to MongoDB Atlas successfully!');
    } catch (e) {
      print('MongoDB Connection Error: $e');
      rethrow;
    }
  }

  static DbCollection getCollection(String collectionName) {
    if (_db == null || !_db!.isConnected) {
      throw Exception('Database is not connected. Call connect() first.');
    }
    return _db!.collection(collectionName);
  }

  static Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
    }
  }
}