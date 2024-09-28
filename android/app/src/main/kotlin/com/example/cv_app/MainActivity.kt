package com.random.cvapplication;

import android.os.Bundle;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "opencv_channel";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
            (call, result) -> {
                if (call.method.equals("detectFaceDistance")) {
                    // Call the OpenCV native code for face detection
                    FaceDetectionPlugin faceDetectionPlugin = new FaceDetectionPlugin();
                    faceDetectionPlugin.onMethodCall(call, result);
                } else {
                    result.notImplemented();
                }
            }
        );
    }
}
