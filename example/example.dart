// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:web_socket_channel/io.dart';

void main() async {
  final channel = await IOWebSocketChannel.connect('wss://echo.websocket.org',
      badCertificateCallback: (X509Certificate cert, String host, int port) =>
          false);

  channel.stream.listen((message) {
    print('RECEIVED: $message');
  });
  channel.sink.add('hello WebSocket !');
}
