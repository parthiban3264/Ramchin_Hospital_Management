import 'package:hospitrax/utils/utils.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  late io.Socket socket;

  void connect() {
    socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {});

    socket.on('queueStatusUpdate', (data) {});

    socket.onDisconnect((_) {});
  }

  void disconnect() {
    socket.disconnect();
  }
}
