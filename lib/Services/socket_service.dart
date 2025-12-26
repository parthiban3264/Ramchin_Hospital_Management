import 'package:hospitrax/utils/utils.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect() {
    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print('✅ Connected to Socket.IO');
    });

    socket.on('queueStatusUpdate', (data) {
      print('🔥 Queue Updated: $data');
    });

    socket.onDisconnect((_) => print('❌ Disconnected from socket'));
  }

  void disconnect() {
    socket.disconnect();
  }
}
