// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:web_socket_channel/testing.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  group('fakes', () {
    late WebSocketChannel client;
    late WebSocketChannel server;

    setUp(() => (client, server) = fakes());
    tearDown(() => client.sink.close());
    tearDown(() => server.sink.close());

    test('string send and receive', () async {
      server.sink.add('Hello');
      server.sink.add('How are you?');
      expect(client.stream, emitsInOrder(['Hello', 'How are you?']));
      client.sink.add('Great!');
      client.sink.add('And you?');
      expect(server.stream, emitsInOrder(['Great!', 'And you?']));
    });

    test('list<int> send and receive', () async {
      server.sink.add([1, 2, 3]);
      server.sink.add([4, 5, 6]);
      expect(
          client.stream,
          emitsInOrder([
            [1, 2, 3],
            [4, 5, 6]
          ]));
      client.sink.add([7, 8]);
      client.sink.add([10, 11]);
      expect(
          server.stream,
          emitsInOrder([
            [7, 8],
            [10, 11]
          ]));
    });

    test('close', () async {
      await server.sink.close();

      expect(server.closeCode, isNull);
      expect(server.closeReason, isNull);

      expect(client.closeCode, 1005); // 1005: closed without a code.
      expect(client.closeReason, isNull);
    });

    test('close with code and reason', () async {
      await server.sink.close(3001, 'bye!');

      expect(server.closeCode, 3001);
      expect(server.closeReason, 'bye!');

      expect(client.closeCode, 3001);
      expect(client.closeReason, 'bye!');
    });
  });
}
