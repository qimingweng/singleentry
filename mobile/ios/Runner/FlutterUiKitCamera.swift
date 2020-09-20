//
//  FlutterUiKitCamera.swift
//  Runner
//
//  Created by Qiming Weng on 2020-09-19.
//

import Foundation
import AVFoundation

// Photos is used for PHPhotoLibrary (which allows us to save images to the Library)
import Photos

public class FlutterUiKitCameraController : NSObject, FlutterPlatformView, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
  let viewId: Int64
  
  // The exposedView is basically the main view, since the name view is taken by the function view(), which is part of the Flutter protocol
  let exposedView: UIView
  
//  var captureSession: AVCaptureSession?
  var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  var capturePhotoOutput: AVCapturePhotoOutput?
  
  // When not nil, this contains the photo output that we can use to capture photos from
  var photoOutput: AVCapturePhotoOutput?
  
  var loaded: Bool = false
  
  // Each view instance should have its own channel
  let channel: FlutterMethodChannel
  
  // Flutter Channels are used to communicate with Flutter
  let registrar: FlutterPluginRegistrar
    
  init(withFrame frame: CGRect, viewId: Int64, args: Any?, registrar: FlutterPluginRegistrar) {
    self.viewId = viewId
    self.exposedView = UIView(frame: frame)
    self.registrar = registrar
    self.channel = FlutterMethodChannel(name: "FlutterUiKitCamera/viewId:\(viewId)", binaryMessenger: registrar.messenger())
    
    // Default to a dark background
    self.exposedView.backgroundColor = UIColor.darkGray
    
    super.init()
    
    // Set up the channel handler
    channel.setMethodCallHandler({
      // The weak self here makes sure that we don't retain a circular reference
      // It is used in the main flutter example, https://flutter.dev/docs/development/platform-integration/platform-channels
      
      [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
      if (call.method == "takePhoto") {
        self?.takePhoto()
      }
    })
  }

  /// When this object is originally created, it has a CGRect.zero frame,
  /// because Flutter seems to be "pre-loading" it. At some later point in time,
  /// the view is requested again, but the frame of the view has changed. It's
  /// not clear what changes the exposedView's frame, but maybe (this is
  /// Qiming's guess) some view constraints at some level.
  public func view() -> UIView {
    print("FlutterUiKitCameraController view")
    print(self.exposedView.frame)
    /// If the frame isn't zero, then we can try to do some initialization
    if (self.exposedView.frame != CGRect.zero) {
      loadCamera()
    }

    return self.exposedView
  }
  
  func takePhoto() {
    // TODO: prevent multiple calls to takePhoto at the same time?
    
    // TODO: this limits to only iOS 11 or later, which may be OK for now but not sure about long term
    // https://everyi.com/by-capability/maximum-supported-ios-version-for-ipod-iphone-ipad.html (basically iPhone 5/5C won't be supported)
    let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
    
    // Auto flash mode, may be we we can change settings here in the future (TODO)
    photoSettings.flashMode = .auto
    
    print("self.photoOutput")
    print(self.photoOutput)
    self.photoOutput?.capturePhoto(with: photoSettings, delegate: self)
    
    print("takePhoto")
  }
  
  // Delegate from takePhoto
  // Used example from Apple's saving captured photos guide
  // https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/capturing_still_and_live_photos/saving_captured_photos
  public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    guard error == nil else { print("Error capturing photo: \(error!)"); return }
    
    print("photoOutput")

    PHPhotoLibrary.requestAuthorization { status in
      guard status == .authorized else {
        print("Error with PHPhotoLibrary authorization status")
        print(status)
        return
      }
      
      PHPhotoLibrary.shared().performChanges({
        // Add the captured photo's file data as the main resource for the Photos asset.
        let creationRequest = PHAssetCreationRequest.forAsset()
        creationRequest.addResource(with: .photo, data: photo.fileDataRepresentation()!, options: nil)
      }, completionHandler: nil)
    }
    
  }
  
  func loadCamera() {
    if (self.loaded) {
      print("Camera already loaded")
      return
    }
    
    guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
      print("No video device found")
      return
    }
    
    // Get an instance of the AVCaptureDeviceInput class. There is some fancy
    // Swift code here for try/guard, but ignore that for now.
    guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {
      print("Error getting AVCaptureDeviceInput")
      return
    }
    
    // Initialize the captureSession object
    let captureSession = AVCaptureSession()
    
    // Start some configuration changes to be committed at the end of the function
    captureSession.beginConfiguration()
  
    // Set the input device on the capture session
    captureSession.addInput(input)
    
    // A performance optimization, suggested by Google's MLKit docs (originally for QR codes but not sure if this makes sense for photo taking too... (there is a  .photo option))
    captureSession.sessionPreset = .hd1280x720
  
    // Get an instance of AVCapturePhotoOutput class, this allows us to take pictures
    let photoOutput = AVCapturePhotoOutput()
    
    // Do we need to add guard against this like in the apple example?
    // not sure
    // https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/capturing_still_and_live_photos
    captureSession.addOutput(photoOutput)
    
    // Save to the class
    self.photoOutput = photoOutput
    
    // Start video capture
    captureSession.commitConfiguration()
    captureSession.startRunning()
    
    //Initialise the video preview layer and add it as a sublayer to the viewPreview view's layer
    let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    videoPreviewLayer.videoGravity = .resizeAspectFill

    /// This is where the magic frame setting happens. This has to occur after
    /// the base view is given a proper frame by Flutter.
    videoPreviewLayer.frame = exposedView.layer.bounds
    exposedView.layer.addSublayer(videoPreviewLayer)

    // It's unclear if we need to protect against this code being run
    // multiple times like this. It's also slightly dirty.
    self.loaded = true
  }
}

public class FlutterUiKitCameraFactory : NSObject, FlutterPlatformViewFactory {
  let registrar: FlutterPluginRegistrar
  
  public init(withRegistrar registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    super.init()
  }
  
  public func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return FlutterUiKitCameraController(withFrame: frame, viewId: viewId, args: args, registrar: registrar)
  }
  
  // Seems like there is something here about arguments passing, see comment below
  // https://github.com/flutter/flutter/issues/28124#issuecomment-465944104
  public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}
