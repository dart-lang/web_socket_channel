import 'package:web/helpers.dart';

extension WebSocketExtension on WebSocket {
  Stream<Event> get onOpen =>
      const EventStreamProvider<Event>('open').forTarget(this);
  Stream<MessageEvent> get onMessage =>
      const EventStreamProvider<MessageEvent>('message').forTarget(this);
  Stream<CloseEvent> get onClose =>
      const EventStreamProvider<CloseEvent>('close').forTarget(this);
  Stream<Event> get onError =>
      const EventStreamProvider<Event>('error').forTarget(this);
}
