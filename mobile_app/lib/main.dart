import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/generated_api/client_index.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _text = "";

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    _test();
  }

  @override
  void initState() {
    super.initState();
  }

  _test() async {
    print("test");

    final Openapi api = Openapi.create(
      baseUrl: Uri.parse("http://localhost:5800"),
      errorConverter: const JsonConverter(),
    );

    try {
      final data1 = await api.helloGet(name: "Olly");
      setState(() {
        _text = data1.body!; // << Is string, or can be complex object.
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(_text),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MyAuthenticator extends Authenticator {
  String token = "";

  @override
  FutureOr<Request?> authenticate(
    Request request,
    Response response, [
    Request? originalRequest,
  ]) async {
    if (response.statusCode == HttpStatus.unauthorized) {
      String? newToken = await refreshToken();

      final Map<String, String> updatedHeaders = Map<String, String>.of(request.headers);

      if (newToken != null) {
        newToken = 'Bearer $newToken';
        updatedHeaders.update('Authorization', (String _) => newToken!, ifAbsent: () => newToken!);
        return request.copyWith(headers: updatedHeaders);
      }
    }
    return null;
  }

  Future<String?> refreshToken() async {
    return token;
  }
}

@immutable
class JsonConverter implements Converter, ErrorConverter {
  const JsonConverter();

  @override
  Request convertRequest(Request request) => encodeJson(
        applyHeader(
          request,
          contentTypeKey,
          jsonHeaders,
          override: false,
        ),
      );

  Request encodeJson(Request request) {
    final String? contentType = request.headers[contentTypeKey];

    if ((contentType?.contains(jsonHeaders) ?? false) && (request.body.runtimeType != String || !isJson(request.body))) {
      return request.copyWith(body: json.encode(request.body));
    }

    return request;
  }

  FutureOr<Response> decodeJson<BodyType, InnerType>(Response response) async {
    final List<String> supportedContentTypes = [jsonHeaders, jsonApiHeaders];

    if (response.statusCode != 200) {
      // Convert body to json
      JsonDecoder decoder = const JsonDecoder();
      var body = decoder.convert(response.body);
      throw ApiError(status: body['status'], message: body['message']);
    }

    final String? contentType = response.headers[contentTypeKey];
    var body = response.body;

    if (supportedContentTypes.contains(contentType)) {
      body = utf8.decode(response.bodyBytes);
    }

    body = await tryDecodeJson(body);
    if (isTypeOf<BodyType, Iterable<InnerType>>()) {
      body = body.cast<InnerType>();
    } else if (isTypeOf<BodyType, Map<String, InnerType>>()) {
      body = body.cast<String, InnerType>();
    }

    return response.copyWith<BodyType>(body: body);
  }

  @override
  FutureOr<Response<BodyType>> convertResponse<BodyType, InnerType>(
    Response response,
  ) async =>
      (await decodeJson<BodyType, InnerType>(response)) as Response<BodyType>;

  @protected
  FutureOr<dynamic> tryDecodeJson(String data) {
    try {
      return json.decode(data);
    } catch (e) {
      chopperLogger.warning(e);

      return data;
    }
  }

  @override
  FutureOr<Response> convertError<BodyType, InnerType>(
    Response response,
  ) async =>
      await decodeJson(response);

  static FutureOr<Response<BodyType>> responseFactory<BodyType, InnerType>(
    Response response,
  ) =>
      const JsonConverter().convertResponse<BodyType, InnerType>(response);

  static Request requestFactory(Request request) => const JsonConverter().convertRequest(request);

  @visibleForTesting
  static bool isJson(dynamic data) {
    try {
      json.decode(data);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class ApiError {
  final String status;
  final String message;

  ApiError({required this.status, required this.message});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      status: json['status'],
      message: json['message'],
    );
  }
}
