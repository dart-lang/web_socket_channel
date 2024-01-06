// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert' as convert;

import 'package:async/async.dart';
import 'package:crypto/crypto.dart';
import 'package:stream_channel/stream_channel.dart';

import '_connect_api.dart'
    if (dart.library.io) '_connect_io.dart'
    if (dart.library.js_interop) '_connect_html.dart' as platform;
import 'copy/web_socket_impl.dart';
import 'exception.dart';

/// A [StreamChannel] that communicates over a WebSocket.
///
/// This is implemented by classes that use `dart:io` and `package:web`. The
/// [WebSocketChannel.new] constructor can also be used on any platform to
/// connect to use the WebSocket protocol over a pre-existing channel.
///
/// All implementations emit [WebSocketChannelException]s. These exceptions wrap
/// the native exception types where possible.
class WebSocketChannel extends StreamChannelMixin {
  /// The underlying web socket.
  ///
  /// This is essentially a copy of `dart:io`'s WebSocket implementation, with
  /// the IO-specific pieces factored out.
  final WebSocketImpl _webSocket;

  /// The subprotocol selected by the server.
  ///
  /// For a client socket, this is initially `null`. After the WebSocket
  /// connection is established the value is set to the subprotocol selected by
  /// the server. If no subprotocol is negotiated the value will remain `null`.
  String? get protocol => _webSocket.protocol;

  /// The [close code][] set when the WebSocket connection is closed.
  ///
  /// [close code]: https://tools.ietf.org/html/rfc6455#section-7.1.5
  ///
  /// Before the connection has been closed, this will be `null`.
  int? get closeCode => _webSocket.closeCode;

  /// The [close reason][] set when the WebSocket connection is closed.
  ///
  /// [close reason]: https://tools.ietf.org/html/rfc6455#section-7.1.6
  ///
  /// Before the connection has been closed, this will be `null`.
  String? get closeReason => _webSocket.closeReason;

  /// A future that will complete when the WebSocket connection has been
  /// established.
  ///
  /// This future must be complete before before data can be sent using
  /// [WebSocketChannel.sink].
  ///
  /// If a connection could not be established (e.g. because of a network
  /// issue), then this future will complete with an error.
  ///
  /// For example:
  /// ```
  /// final channel = WebSocketChannel.connect(Uri.parse('ws://example.com'));
  ///
  /// try {
  ///   await channel.ready;
  /// } on SocketException catch (e) {
  ///   // Handle the exception.
  /// } on WebSocketChannelException catch (e) {
  ///   // Handle the exception.
  /// }
  ///
  /// // If `ready` completes without an error then the channel is ready to
  /// // send data.
  /// channel.sink.add('Hello World');
  /// ```
  final Future<void> ready = Future.value();

  @override
  Stream get stream => StreamView(_webSocket);

  /// The sink for sending values to the other endpoint.
  ///
  /// This supports additional arguments to [WebSocketSink.close] that provide
  /// the remote endpoint reasons for closing the connection.
  @override
  WebSocketSink get sink => WebSocketSink._(_webSocket);

  /// Signs a `Sec-WebSocket-Key` header sent by a WebSocket client as part of
  /// the [initial handshake][].
  ///
  /// The return value should be sent back to the client in a
  /// `Sec-WebSocket-Accept` header.
  ///
  /// [initial handshake]: https://tools.ietf.org/html/rfc6455#section-4.2.2
  static String signKey(String key)
      // We use [codeUnits] here rather than UTF-8-decoding the string because
      // [key] is expected to be base64 encoded, and so will be pure ASCII.
      =>
      convert.base64
          .encode(sha1.convert((key + webSocketGUID).codeUnits).bytes);

  /// Creates a new WebSocket handling messaging across an existing [channel].
  ///
  /// This is a cross-platform constructor; it doesn't use either `dart:io` or
  /// `package:web`. It's also HTTP-API-agnostic, which means that the initial
  /// [WebSocket handshake][] must have already been completed on the socket
  /// before this is called.
  ///
  /// [protocol] should be the protocol negotiated by this handshake, if any.
  ///
  /// [pingInterval] controls the interval for sending ping signals. If a ping
  /// message is not answered by a pong message from the peer, the WebSocket is
  /// assumed disconnected and the connection is closed with a `goingAway` close
  /// code. When a ping signal is sent, the pong message must be received within
  /// [pingInterval]. It defaults to `null`, indicating that ping messages are
  /// disabled.
  ///
  /// If this is a WebSocket server, [serverSide] should be `true` (the
  /// default); if it's a client, [serverSide] should be `false`.
  ///
  /// [WebSocket handshake]: https://tools.ietf.org/html/rfc6455#section-4
  WebSocketChannel(StreamChannel<List<int>> channel,
      {String? protocol, Duration? pingInterval, bool serverSide = true})
      : _webSocket = WebSocketImpl.fromSocket(
            channel.stream, channel.sink, protocol, serverSide)
          ..pingInterval = pingInterval;

  /// Creates a new WebSocket connection.
  ///
  /// Connects to [uri] using and returns a channel that can be used to
  /// communicate over the resulting socket.
  ///
  /// The optional [protocols] parameter is the same as `WebSocket.connect`.
  ///
  /// A WebSocketChannel is returned synchronously, however the connection is
  /// not established synchronously.
  /// The [ready] future will complete after the channel is connected.
  /// If there are errors creating the connection the [ready] future will
  /// complete with an error.
  factory WebSocketChannel.connect(Uri uri, {Iterable<String>? protocols}) =>
      platform.connect(uri, protocols: protocols);
}

/// The sink exposed by a [WebSocketChannel].
///
/// This is like a normal [StreamSink], except that it supports extra arguments
/// to [close].
class WebSocketSink extends DelegatingStreamSink {
  final WebSocketImpl _webSocket;

  WebSocketSink._(WebSocketImpl super.webSocket) : _webSocket = webSocket;

  /// Closes the web socket connection.
  ///
  /// [closeCode] and [closeReason] are the [close code][] and [reason][] sent
  /// to the remote peer, respectively. If they are omitted, the peer will see
  /// a "no status received" code with no reason.
  ///
  /// [close code]: https://tools.ietf.org/html/rfc6455#section-7.1.5
  /// [reason]: https://tools.ietf.org/html/rfc6455#section-7.1.6
  @override
  Future close([int? closeCode, String? closeReason]) =>
      _webSocket.close(closeCode, closeReason);
}
