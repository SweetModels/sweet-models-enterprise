import 'dart:async';

import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Servicio ligero para chat en tiempo real via WebSocket
class ChatService {
	ChatService({this.url = 'ws://localhost:3000/api/chat/ws'});

	final String url;
	WebSocketChannel? _channel;
	final _messages = StreamController<String>.broadcast();

	Stream<String> get stream => _messages.stream;

	void connect() {
		_channel = WebSocketChannel.connect(Uri.parse(url));
		_channel?.stream.listen(
			(event) => _messages.add(event.toString()),
			onError: (err) => _messages.add('⚠️ Error: $err'),
			onDone: () {
				// El servidor cerró la conexión
			},
		);
	}

	void sendMessage(String text) {
		_channel?.sink.add(text);
	}

	Future<void> dispose() async {
		await _channel?.sink.close(ws_status.normalClosure);
		await _messages.close();
	}
}
