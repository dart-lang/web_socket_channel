import 'package:web/helpers.dart';

extension WebSocketEvents on WebSocket {
  Stream<Event> get onOpen => EventStreamProviders.openEvent.forTarget(this);
  Stream<MessageEvent> get onMessage =>
      EventStreamProviders.messageEvent.forTarget(this);
  Stream<CloseEvent> get onClose =>
      EventStreamProviders.closeEvent.forTarget(this);
  Stream<Event> get onError =>
      EventStreamProviders.errorEventSourceEvent.forTarget(this);
}
