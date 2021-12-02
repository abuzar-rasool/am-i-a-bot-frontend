import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:timer_count_down/timer_count_down.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: const DarkChatTheme().primaryColor,
        secondaryHeaderColor: const DarkChatTheme().secondaryColor,
        brightness: Brightness.dark,
      ),
      debugShowCheckedModeBanner: false,
      home: ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<types.Message> _messages = [];
  final _users = const [
    types.User(id: '273948723482347', firstName: "Anonymous"),
    types.User(id: '12345698765432', firstName: "You")
  ];
  late types.User _currentUser;
  late WebSocketChannel channel;
  @override
  void initState() {
    super.initState();
    _currentUser = _users.last;
    channel = WebSocketChannel.connect(
      Uri.parse('ws://966d-34-86-37-67.ngrok.io/'),
    );
    channel.stream.listen((snapshot) {
      final textMessage = types.TextMessage(
        author: _users.first,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: snapshot.toString(),
      );
      setState(() {
        _messages.insert(0,textMessage);
      });
    });
  }


  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = _messages[index].copyWith(previewData: previewData);

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      setState(() {
        _messages[index] = updatedMessage;
      });
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _users.last,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    setState(() {
      _messages.insert(0, textMessage);
      channel.sink.add(message.text);
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             Text('Anonymous'),
             SizedBox(width: 8),
             Spacer(),
             Countdown(
              seconds: 180,
              build: (BuildContext context, double time) => Text(
                time.toStringAsFixed(0) + "s",
                style: const TextStyle(color: Colors.white),
              ),
              interval: const Duration(milliseconds: 100),
              onFinished: () async {
                print('Timer is done!');
                print('redirecting to survey');
                channel.sink.close();
                showDialog(  
                  barrierDismissible: false,
                context: context,  
                builder: (BuildContext context) {  
                  return AlertDialog(  
                  title: Text("Chat Ended"),  
                  content: Text("Thank you for your time."),    
                );  
                });  
                await launch('https://google.com');
              },
            ),
          ],
        ),
        backgroundColor: const DarkChatTheme().inputBackgroundColor,
      ),
      body: SafeArea(
        bottom: true,
        child: Chat(
          showUserNames: true,
          messages: _messages,
          onPreviewDataFetched: _handlePreviewDataFetched,
          onSendPressed: _handleSendPressed,
          user: _currentUser,
        ),
      ),
    );
  }
}
