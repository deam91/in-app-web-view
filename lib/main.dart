import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
      debug: true // optional: set false to disable printing logs to console
      );
  await Permission.storage.request();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme:
            new AppBarTheme(brightness: Brightness.light, color: Colors.white),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  InAppWebViewController _webViewController;

  String url;

  double progress;

  InAppWebViewController _webViewPopupController;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 30,
          child: TextField(
            textAlignVertical: TextAlignVertical.center,
            textAlign: TextAlign.left,
            onSubmitted: (text) {
              setState(() {
                this.url = text;
                this._webViewController.loadUrl(url: this.url);
              });
            },
            maxLines: 1,
            decoration: InputDecoration(
              hintText: this.url != '' ? this.url : '',
              alignLabelWithHint: true,
              suffixIcon: Icon(Icons.search),
              contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 10),
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black12),
                  borderRadius: BorderRadius.circular(50)),
            ),
          ),
        ),
        actions: <Widget>[
          new IconButton(
            padding:EdgeInsets.all(0),
            icon: new Icon(Icons.arrow_back_ios),
            hoverColor: Colors.blueAccent,
            color: Colors.black45,
            onPressed: () {
              if (_webViewController != null) {
                _webViewController.goBack();
              }
            },
            iconSize: 16,
          ),
          new IconButton(
            padding:EdgeInsets.all(0),
            icon: new Icon(Icons.refresh),
            hoverColor: Colors.blueAccent,
            color: Colors.black45,
            onPressed: () {
              if (_webViewController != null) {
                _webViewController.reload();
              }
            },
            iconSize: 16,
          ),
          new IconButton(
            padding:EdgeInsets.all(0),
            icon: new Icon(Icons.arrow_forward_ios),
            hoverColor: Colors.blueAccent,
            color: Colors.black45,
            onPressed: () {
              if (_webViewController != null) {
                _webViewController.goForward();
              }
            },
            iconSize: 16,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(new FocusNode());
        },
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(0.0),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.transparent)),
                  child: InAppWebView(
                    initialUrl: "https://flutter.dev/",
                    initialOptions: InAppWebViewGroupOptions(
                        crossPlatform: InAppWebViewOptions(
                            useShouldOverrideUrlLoading: true),
                        android: AndroidInAppWebViewOptions(
                          // on Android you need to set supportMultipleWindows to true,
                          // otherwise the onCreateWindow event won't be called
                            supportMultipleWindows: true)),
                    onWebViewCreated: (InAppWebViewController controller) {
                      this._webViewController = controller;
                    },
                    shouldOverrideUrlLoading: (controller, request) async {
                      var url = request.url;
                      var uri = Uri.parse(url);

                      if (![
                        "http",
                        "https",
                        "file",
                        "chrome",
                        "data",
                        "javascript",
                        "about"
                      ].contains(uri.scheme)) {
                        if (await canLaunch(url)) {
                          // Launch the App
                          await launch(
                            url,
                          );
                          // and cancel the request
                          return ShouldOverrideUrlLoadingAction.CANCEL;
                        }
                      }

                      return ShouldOverrideUrlLoadingAction.ALLOW;
                    },
                    onLoadStart: (InAppWebViewController controller, String url) {
                      setState(() {
                        this.url = url;
                      });
                    },
                    onLoadStop:
                        (InAppWebViewController controller, String url) async {
                      setState(() {
                        this.url = url;
                      });
                    },
                    onProgressChanged:
                        (InAppWebViewController controller, int progress) {
                      setState(() {
                        this.progress = progress / 100;
                      });
                    },
                    onDownloadStart: (controller, url) async {
                      print("onDownloadStart $url");
                      final taskId = await FlutterDownloader.enqueue(
                        url: url,
                        savedDir: (await getExternalStorageDirectory()).path,
                        showNotification: true,
                        // show download progress in status bar (for Android)
                        openFileFromNotification:
                        true, // click on notification to open downloaded file (for Android)
                      );
                    },
                    onReceivedServerTrustAuthRequest:
                        (controller, challenge) async {
                      return ServerTrustAuthResponse(
                          action: ServerTrustAuthResponseAction.PROCEED);
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      )
    );
  }

  canLaunch(String url) {}

  launch(String url) {}
}
