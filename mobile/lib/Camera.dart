import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Camera extends StatefulWidget {
  @override
  _CameraState createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  MethodChannel channel;

  void _handlePlatformViewCreated(int viewId) {
    this.channel = MethodChannel('FlutterUiKitCamera/viewId:$viewId');
  }

  @override
  Widget build(BuildContext context) {
    print("Camera");

    return Stack(
      children: [
        UiKitView(
          viewType: "FlutterUiKitCamera",
          onPlatformViewCreated: _handlePlatformViewCreated,
        ),
        GestureDetector(
          child: Container(
            color: Colors.pink,
            width: 150,
            height: 150,
          ),
          onTap: () {
            print("Camera shutter");
            this.channel?.invokeMethod("takePhoto");
          },
        ),
      ],
    );
  }
}
