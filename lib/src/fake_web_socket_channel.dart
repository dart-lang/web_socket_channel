// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:stream_channel/stream_channel.dart';

import '../web_socket_channel.dart';

const _noStatusCodePresent = 1005;

class _FakeSink extends DelegatingStreamSink implements WebSocketSink {
  final _FakeWebSocketChannel _channel;

  _FakeSink(this._channel) : super(_channel._controller.sink);

  @override
  Future close([int? closeCode, String? closeReason]) async {
    if (!_channel._isClosed) {
      _channel._isClosed = true;
      unawaited(super.close());
      _channel._closeCode = closeCode;
      _channel._closeReason = closeReason;
      unawaited(_channel._close(closeCode, closeReason));
    }
  }
}

class _FakeWebSocketChannel extends StreamChannelMixin
    implements WebSocketChannel {
  final StreamChannel _controller;
  final Future Function(int? closeCode, String? closeReason) _close;
  int? _closeCode;
  String? _closeReason;
  var _isClosed = false;

  _FakeWebSocketChannel(this._controller, this._close);

  @override
  int? get closeCode => _closeCode;

  @override
  String? get closeReason => _closeReason;

  @override
  String? get protocol => throw UnimplementedError();

  @override
  Future<void> get ready => Future.value();

  @override
  WebSocketSink get sink => _FakeSink(this);

  @override
  Stream get stream => _controller.stream;
}

/// Create a pair of fake [WebSocketChannel]s that are connected to each other.
///
/// For example:
///
/// ```
/// import 'package:test/test.dart';
/// import 'package:web_socket_channel/testing.dart';
/// import 'package:web_socket_channel/web_socket_channel.dart';
///
/// Future<void> sumServer(WebSocketChannel channel) async {
///   var sum = 0;
///   await channel.stream.forEach((number) {
///     sum += int.parse(number as String);
///     channel.sink.add(sum.toString());
///   });
/// }
///
/// void main() async {
///   late WebSocketChannel client;
///   late WebSocketChannel server;
///
///   setUp(() => (client, server) = fakes());
///   tearDown(() => client.sink.close());
///   tearDown(() => server.sink.close());
///
///   test('test positive numbers', () {
///     sumServer(server);
///     client.sink.add('1');
///     client.sink.add('2');
///     client.sink.add('3');
///     expect(client.stream, emitsInOrder(['1', '3', '6']));
///   });
/// }
/// ```
(WebSocketChannel, WebSocketChannel) fakes() {
  final peer1Write = StreamController<dynamic>();
  final peer2Write = StreamController<dynamic>();

  late _FakeWebSocketChannel peer1;
  late _FakeWebSocketChannel peer2;

  peer1 = _FakeWebSocketChannel(
      StreamChannel(peer2Write.stream, peer1Write.sink),
      (closeCode, closeReason) =>
          peer2.sink.close(closeCode ?? _noStatusCodePresent, closeReason));
  peer2 = _FakeWebSocketChannel(
      StreamChannel(peer1Write.stream, peer2Write.sink),
      (closeCode, closeReason) =>
          peer1.sink.close(closeCode ?? _noStatusCodePresent, closeReason));

  return (peer1, peer2);
}
