import 'package:web/helpers.dart';

// TODO: remove when https://github.com/dart-lang/web/pull/102 is landed
// and the min constraint on pkg:web is updated
extension WebSocketEvents on WebSocket {
  Stream<Event> get onOpen => EventStreamProviders.openEvent.forTarget(this);
  Stream<MessageEvent> get onMessage =>
      EventStreamProviders.messageEvent.forTarget(this);
  Stream<CloseEvent> get onClose =>
      EventStreamProviders.closeEvent.forTarget(this);
  Stream<Event> get onError =>
      EventStreamProviders.errorEventSourceEvent.forTarget(this);
}
