The `web_socket_channel` package provides [`StreamChannel`][stream_channel]
wrappers for WebSocket connections. It provides a cross-platform
[`WebSocketChannel`][WebSocketChannel] API, a cross-platform implementation of
that API that communicates over an underlying [`StreamChannel`][stream_channel],
[an implementation][IOWebSocketChannel] that wraps `dart:io`'s `WebSocket`
class, and [a similar implementation][HtmlWebSocketChannel] that wrap's
`dart:html`'s.

[stream_channel]: https://pub.dartlang.org/packages/stream_channel
[WebSocketChannel]: https://www.dartdocs.org/documentation/web_socket_channel/latest/web_socket_channel/WebSocketChannel-class.html
[IOWebSocketChannel]: https://www.dartdocs.org/documentation/web_socket_channel/latest/io/IOWebSocketChannel-class.html
[HtmlWebSocketChannel]: https://www.dartdocs.org/documentation/web_socket_channel/latest/html/HtmlWebSocketChannel-class.html

It also provides constants for the WebSocket protocol's pre-defined status codes
in the [`status.dart` library][status]. It's strongly recommended that users
import this library should be imported with the prefix `status`.

[status]: https://www.dartdocs.org/documentation/web_socket_channel/latest/status/status-library.html

```dart
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

main() async {
  var channel = await IOWebSocketChannel.connect("ws://localhost:1234");

  channel.stream.listen((message) {
    channel.sink.add("received!");
    channel.close(status.goingAway);
  });
}
```

## `WebSocketChannel`

The [`WebSocketChannel`][WebSocketChannel] class's most important role is as the
interface for WebSocket stream channels across all implementations and all
platforms. In addition to the base `StreamChannel` interface, it adds a
[`protocol`][protocol] getter that returns the negotiated protocol for the
socket, as well as [`closeCode`][closeCode] and [`closeReason`][closeReason]
getters that provide information about why the socket closed.

[protocol]: https://www.dartdocs.org/documentation/web_socket_channel/latest/web_socket_channel/WebSocketChannel/protocol.html
[closeCode]: https://www.dartdocs.org/documentation/web_socket_channel/latest/web_socket_channel/WebSocketChannel/closeCode.html
[closeReason]: https://www.dartdocs.org/documentation/web_socket_channel/latest/web_socket_channel/WebSocketChannel/closeReason.html

The channel's [`sink` property][sink] is also special. It returns a
[`WebSocketSink`][WebSocketSink], which is just like a `StreamSink` except that
its [`close()`][sink.close] method supports optional `closeCode` and
`closeReason` parameters. These parameters allow the caller to signal to the
other socket exactly why they're closing the connection.

[sink]: https://www.dartdocs.org/documentation/web_socket_channel/latest/web_socket_channel/WebSocketChannel/sink.html
[WebSocketSink]: https://www.dartdocs.org/documentation/web_socket_channel/latest/web_socket_channel/WebSocketSink-class.html
[sink.close]: https://www.dartdocs.org/documentation/web_socket_channel/latest/web_socket_channel/WebSocketSink/close.html

`WebSocketChannel` also works as a cross-platform implementation of the
WebSocket protocol. Because it can't initiate or handle HTTP requests in a
cross-platform way, the [`new WebSocketChannel()` constructor][new] takes an
underlying [`StreamChannel`][stream_channel] over which it communicates using
the WebSocket protocol. It also provides the static [`signKey()`][signKey]
method to make it easier to implement the [initial WebSocket handshake][]. These
are used in the [`shelf_web_socket`][shelf_web_socket] package to support
WebSockets in a cross-platform way.

[new]: https://www.dartdocs.org/documentation/web_socket_channel/latest/web_socket_channel/WebSocketChannel/WebSocketChannel.html
[signKey]: https://www.dartdocs.org/documentation/web_socket_channel/latest/web_socket_channel/WebSocketChannel/signKey.html
[initial WebSocket handshake]: https://tools.ietf.org/html/rfc6455#section-4.2.2
[shelf_web_socket]: https://pub.dartlang.org/packages/shelf_web_socket

## `IOWebSocketChannel`

The [`IOWebSocketChannel`][IOWebSocketChannel] class wraps
[`dart:io`'s `WebSocket` class][io.WebSocket]. Because it imports `dart:io`, it
has its own library, `package:web_socket_channel/io.dart`. This allows the main
`WebSocketChannel` class to be available on all platforms.

[io.WebSocket]: https://api.dartlang.org/latest/dart-io/WebSocket-class.html

An `IOWebSocketChannel` can be created by passing a `dart:io` WebSocket to
[its constructor][new IOWebSocketChannel]. It's more common to want to connect
directly to a `ws://` or `wss://` URL, in which case
[`new IOWebSocketChannel.connect()`][IOWebSocketChannel.connect] should be used.

[new IOWebSocketChannel]: https://www.dartdocs.org/documentation/web_socket_channel/latest/io/IOWebSocketChannel/IOWebSocketChannel.html
[IOWebSocketChannel.connect]: https://www.dartdocs.org/documentation/web_socket_channel/latest/io/IOWebSocketChannel/IOWebSocketChannel.connect.html

```dart
import 'package:web_socket_channel/io.dart';

main() async {
  var channel = new IOWebSocketChannel.connect("ws://localhost:8181");
  channel.sink.add("connected!");
  channel.stream.listen((message) {
    // ...
  });
}
```

## `HtmlWebSocketChannel`

The [`HtmlWebSocketChannel`][HtmlWebSocketChannel] class wraps
[`dart:html`'s `WebSocket` class][html.WebSocket]. Because it imports
`dart:html`, it has its own library, `package:web_socket_channel/html.dart`.
This allows the main `WebSocketChannel` class to be available on all platforms.

[html.WebSocket]: https://api.dartlang.org/latest/dart-html/WebSocket-class.html

An `HtmlWebSocketChannel` can be created by passing a `dart:html` WebSocket to
[its constructor][new HtmlWebSocketChannel]. It's more common to want to connect
directly to a `ws://` or `wss://` URL, in which case
[`new HtmlWebSocketChannel.connect()`][HtmlWebSocketChannel.connect] should be used.

[new HtmlWebSocketChannel]: https://www.dartdocs.org/documentation/web_socket_channel/latest/html/HtmlWebSocketChannel/HtmlWebSocketChannel.html
[HtmlWebSocketChannel.connect]: https://www.dartdocs.org/documentation/web_socket_channel/latest/html/HtmlWebSocketChannel/HtmlWebSocketChannel.connect.html

```dart
import 'package:web_socket_channel/html.dart';

main() async {
  var channel = new HtmlWebSocketChannel.connect("ws://localhost:8181");
  channel.sink.add("connected!");
  channel.stream.listen((message) {
    // ...
  });
}
```
