import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Message {
  final String id;
  final String text;
  final DateTime timestamp;
  final String userId;

  Message({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'userId': userId,
    };
  }

  factory Message.fromSnapshot(DataSnapshot snapshot) {
    Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
    return Message(
      id: snapshot.key ?? '',
      text: data['text'] ?? '',
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
      userId: data['userId'] ?? '',
    );
  }
}

enum FilterType { newest, oldest, myMessages }

class MessageService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String messagesRef = 'anonymous_messages';
  static const int pageSize = 10;

  /// Post an anonymous message to Realtime Database
  Future<String?> postMessage(String messageText) async {
    try {
      if (messageText.trim().isEmpty) {
        print('Message cannot be empty');
        return null;
      }

      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('User not authenticated');
        return null;
      }

      DatabaseReference newMessageRef =
          _database.ref(messagesRef).push();

      await newMessageRef.set({
        'text': messageText.trim(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'userId': currentUser.uid,
      });

      print('Message posted successfully with ID: ${newMessageRef.key}');
      return newMessageRef.key;
    } catch (e) {
      print('Error posting message: $e');
      return null;
    }
  }

  /// Get all messages
  Future<List<Message>> getAllMessages({
    FilterType filter = FilterType.newest,
  }) async {
    try {
      DatabaseReference ref = _database.ref(messagesRef);
      DataSnapshot snapshot = await ref.get();

      if (!snapshot.exists) {
        return [];
      }

      List<Message> messages = [];
      Map<String, dynamic> data =
          Map<String, dynamic>.from(snapshot.value as Map);

      data.forEach((key, value) {
        Map<String, dynamic> msgData = Map<String, dynamic>.from(value as Map);
        messages.add(Message(
          id: key,
          text: msgData['text'] ?? '',
          timestamp: DateTime.fromMillisecondsSinceEpoch(
              msgData['timestamp'] ?? 0),
          userId: msgData['userId'] ?? '',
        ));
      });

      // Sort by timestamp
      if (filter == FilterType.newest) {
        messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      } else if (filter == FilterType.oldest) {
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }

      return messages;
    } catch (e) {
      print('Error retrieving messages: $e');
      return [];
    }
  }

  /// Paginate messages locally
  List<Message> paginateMessages(
    List<Message> allMessages,
    int pageNumber,
  ) {
    if (pageNumber < 1) return [];

    int start = (pageNumber - 1) * pageSize;
    int end = start + pageSize;

    if (start >= allMessages.length) return [];

    return allMessages.sublist(
      start,
      end > allMessages.length ? allMessages.length : end,
    );
  }

  /// Get messages with pagination
  Future<List<Message>> getMessages({
    required int pageNumber,
    FilterType filter = FilterType.newest,
  }) async {
    try {
      List<Message> allMessages = await getAllMessages(filter: filter);
      return paginateMessages(allMessages, pageNumber);
    } catch (e) {
      print('Error retrieving paginated messages: $e');
      return [];
    }
  }

  /// Search messages by text
  Future<List<Message>> searchMessages(String searchQuery) async {
    try {
      if (searchQuery.trim().isEmpty) return [];

      String searchLower = searchQuery.trim().toLowerCase();
      List<Message> allMessages = await getAllMessages();

      List<Message> results = allMessages
          .where((msg) => msg.text.toLowerCase().contains(searchLower))
          .toList();

      return results;
    } catch (e) {
      print('Error searching messages: $e');
      return [];
    }
  }

  /// Get messages from a specific date range
  Future<List<Message>> getMessagesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      List<Message> allMessages = await getAllMessages();

      List<Message> results = allMessages
          .where((msg) =>
              msg.timestamp.isAfter(startDate) &&
              msg.timestamp.isBefore(endDate))
          .toList();

      return results;
    } catch (e) {
      print('Error retrieving messages by date: $e');
      return [];
    }
  }

  /// Get total number of messages
  Future<int> getTotalMessageCount() async {
    try {
      DataSnapshot snapshot =
          await _database.ref(messagesRef).get();

      if (!snapshot.exists) {
        return 0;
      }

      Map<String, dynamic> data =
          Map<String, dynamic>.from(snapshot.value as Map);
      return data.length;
    } catch (e) {
      print('Error getting message count: $e');
      return 0;
    }
  }

  /// Get user's own messages
  Future<List<Message>> getUserMessages({required int pageNumber}) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('User not authenticated');
        return [];
      }

      if (pageNumber < 1) return [];

      DataSnapshot snapshot =
          await _database.ref(messagesRef).get();

      if (!snapshot.exists) {
        return [];
      }

      List<Message> userMessages = [];
      Map<String, dynamic> data =
          Map<String, dynamic>.from(snapshot.value as Map);

      data.forEach((key, value) {
        Map<String, dynamic> msgData = Map<String, dynamic>.from(value as Map);
        if (msgData['userId'] == currentUser.uid) {
          userMessages.add(Message(
            id: key,
            text: msgData['text'] ?? '',
            timestamp: DateTime.fromMillisecondsSinceEpoch(
                msgData['timestamp'] ?? 0),
            userId: msgData['userId'] ?? '',
          ));
        }
      });

      userMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return paginateMessages(userMessages, pageNumber);
    } catch (e) {
      print('Error retrieving user messages: $e');
      return [];
    }
  }

  /// Delete a message (only if user is the author)
  Future<bool> deleteMessage(String messageId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('User not authenticated');
        return false;
      }

      DataSnapshot snapshot =
          await _database.ref('$messagesRef/$messageId').get();

      if (!snapshot.exists) {
        print('Message not found');
        return false;
      }

      Map<String, dynamic> data =
          Map<String, dynamic>.from(snapshot.value as Map);
      if (data['userId'] != currentUser.uid) {
        print('Unauthorized: You can only delete your own messages');
        return false;
      }

      await _database.ref('$messagesRef/$messageId').remove();
      print('Message deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  /// Real-time stream of messages (newest first)
  Stream<List<Message>> getMessagesStream() {
    return _database.ref(messagesRef).onValue.map((event) {
      if (!event.snapshot.exists) {
        return [];
      }

      List<Message> messages = [];
      Map<String, dynamic> data =
          Map<String, dynamic>.from(event.snapshot.value as Map);

      data.forEach((key, value) {
        Map<String, dynamic> msgData = Map<String, dynamic>.from(value as Map);
        messages.add(Message(
          id: key,
          text: msgData['text'] ?? '',
          timestamp: DateTime.fromMillisecondsSinceEpoch(
              msgData['timestamp'] ?? 0),
          userId: msgData['userId'] ?? '',
        ));
      });

      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages.take(pageSize).toList();
    });
  }

  /// Real-time stream of user's own messages
  Stream<List<Message>> getUserMessagesStream() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _database.ref(messagesRef).onValue.map((event) {
      if (!event.snapshot.exists) {
        return [];
      }

      List<Message> messages = [];
      Map<String, dynamic> data =
          Map<String, dynamic>.from(event.snapshot.value as Map);

      data.forEach((key, value) {
        Map<String, dynamic> msgData = Map<String, dynamic>.from(value as Map);
        if (msgData['userId'] == currentUser.uid) {
          messages.add(Message(
            id: key,
            text: msgData['text'] ?? '',
            timestamp: DateTime.fromMillisecondsSinceEpoch(
                msgData['timestamp'] ?? 0),
            userId: msgData['userId'] ?? '',
          ));
        }
      });

      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages;
    });
  }

  /// Real-time stream with custom filter
  Stream<List<Message>> getFilteredMessagesStream(FilterType filter) {
    User? currentUser = _auth.currentUser;

    return _database.ref(messagesRef).onValue.map((event) {
      if (!event.snapshot.exists) {
        return [];
      }

      List<Message> messages = [];
      Map<String, dynamic> data =
          Map<String, dynamic>.from(event.snapshot.value as Map);

      data.forEach((key, value) {
        Map<String, dynamic> msgData = Map<String, dynamic>.from(value as Map);

        // Apply filter
        if (filter == FilterType.myMessages) {
          if (msgData['userId'] != currentUser?.uid) return;
        }

        messages.add(Message(
          id: key,
          text: msgData['text'] ?? '',
          timestamp: DateTime.fromMillisecondsSinceEpoch(
              msgData['timestamp'] ?? 0),
          userId: msgData['userId'] ?? '',
        ));
      });

      // Apply sorting
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages.take(pageSize).toList();
    });
  }
}