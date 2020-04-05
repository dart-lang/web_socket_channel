// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

part of my._http;

final _httpOverridesToken = new Object();

const _asyncRunZoned = runZoned;

/// This class facilitates overriding [HttpClient] with a mock implementation.
/// It should be extended by another class in client code with overrides
/// that construct a mock implementation. The implementation in this base class
/// defaults to the actual [HttpClient] implementation. For example:
///
/// ```
/// class MyHttpClient implements HttpClient {
///   ...
///   // An implementation of the HttpClient interface
///   ...
/// }
///
/// main() {
///   HttpOverrides.runZoned(() {
///     ...
///     // Operations will use MyHttpClient instead of the real HttpClient
///     // implementation whenever HttpClient is used.
///     ...
///   }, createHttpClient: (SecurityContext c) => new MyHttpClient(c));
/// }
/// ```
abstract class HttpOverrides {
  static HttpOverrides _global;

  static HttpOverrides get current {
    return Zone.current[_httpOverridesToken] ?? _global;
  }

  /// The [HttpOverrides] to use in the root [Zone].
  ///
  /// These are the [HttpOverrides] that will be used in the root Zone, and in
  /// Zone's that do not set [HttpOverrides] and whose ancestors up to the root
  /// Zone do not set [HttpOverrides].
  static set global(HttpOverrides overrides) {
    _global = overrides;
  }

  /// Runs [body] in a fresh [Zone] using the provided overrides.
  static R runZoned<R>(R body(),
      {HttpClient Function(SecurityContext) createHttpClient,
      String Function(Uri uri, Map<String, String> environment) findProxyFromEnvironment,
      ZoneSpecification zoneSpecification,
      Function onError}) {
    HttpOverrides overrides = new _HttpOverridesScope(createHttpClient, findProxyFromEnvironment);
    return _asyncRunZoned<R>(body,
        zoneValues: {_httpOverridesToken: overrides},
        zoneSpecification: zoneSpecification,
        onError: onError);
  }

  /// Runs [body] in a fresh [Zone] using the overrides found in [overrides].
  ///
  /// Note that [overrides] should be an instance of a class that extends
  /// [HttpOverrides].
  static R runWithHttpOverrides<R>(R body(), HttpOverrides overrides,
      {ZoneSpecification zoneSpecification, Function onError}) {
    return _asyncRunZoned<R>(body,
        zoneValues: {_httpOverridesToken: overrides},
        zoneSpecification: zoneSpecification,
        onError: onError);
  }

  /// Returns a new [HttpClient] using the given [context].
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `new HttpClient`.
  HttpClient createHttpClient(SecurityContext context) {
    return new _HttpClient(context);
  }

  /// Resolves the proxy server to be used for HTTP connections.
  ///
  /// When this override is installed, this function overrides the behavior of
  /// `HttpClient.findProxyFromEnvironment`.
  String findProxyFromEnvironment(Uri url, Map<String, String> environment) {
    return _HttpClient._findProxyFromEnvironment(url, environment);
  }
}

class _HttpOverridesScope extends HttpOverrides {
  final HttpOverrides _previous = HttpOverrides.current;

  final HttpClient Function(SecurityContext) _createHttpClient;
  final String Function(Uri uri, Map<String, String> environment) _findProxyFromEnvironment;

  _HttpOverridesScope(this._createHttpClient, this._findProxyFromEnvironment);

  @override
  HttpClient createHttpClient(SecurityContext context) {
    if (_createHttpClient != null) return _createHttpClient(context);
    if (_previous != null) return _previous.createHttpClient(context);
    return super.createHttpClient(context);
  }

  @override
  String findProxyFromEnvironment(Uri url, Map<String, String> environment) {
    if (_findProxyFromEnvironment != null) {
      return _findProxyFromEnvironment(url, environment);
    }
    if (_previous != null) {
      return _previous.findProxyFromEnvironment(url, environment);
    }
    return super.findProxyFromEnvironment(url, environment);
  }
}
