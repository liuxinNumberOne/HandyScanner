//
//  HandyScannerGuide.swift
//  HandyScannerSDK
//
//  Created by well on 2021/10/6.
//

@_exported import UIKit
@_exported import AVFoundation

/// MARK: - Core class
@objc public class HandyScannerHelper: NSObject, HandyScannerHelperProtocol {
    /// Scan parameters
    public var config: HandyScannerConfig!
    /// A device that provides input
    public lazy var device: AVCaptureDevice? = { AVCaptureDevice.default(for: .video) }()
    /// A capture input that provides media
    public var input: AVCaptureDeviceInput?
    /// A capture output for processing timed metadata
    public var metaDataOutput: AVCaptureMetadataOutput?
    /// An object that manages capture
    public var session: AVCaptureSession?
    /// The parent view of the scan view
    public var supView: UIView!
    /// Scan view
    public var scanView: HandyScannerView!
    /// A Core Animation layer
    public var previewLayer: AVCaptureVideoPreviewLayer?
    /// Scan result array (scan string)
    public var valueArray = [String]()
    /// Scan result array (scan type)
    public var typeArray = [AVMetadataObject.ObjectType]()
    /// metadata object types
    public var metadataObjectTypes = [AVMetadataObject.ObjectType]()
    /// Double click gesture state (default small, i.e. initial state)
    public var doubleTapState: DoubleTapState = .Small
    /// Device initial scale (default is 1)
    public var defaultScale: CGFloat = 1
    /// Effective scaling of the device (1 by default)
    public var effectiveScale: CGFloat = 1
    /// Maximum device scale (default = 1)
    public var deviceMaxScale: CGFloat = 1
    /// An object player
    public var aVPlayer: AVPlayer?
    /// Scan single result callback
    public var handler: ((HandyScannerResult) -> Void)?
    /// Scan proxy objects (weak references)
    public weak var delegate: HandyScannerDelegate?
    
    /// A capture output that records video(lazy,optional)
    public lazy var videoDataOutput: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        output.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA]
        return output
    }()
    
    /// A capture output for still image(lazy,optional)
    public lazy var photoOutput: AVCapturePhotoOutput = { AVCapturePhotoOutput() }()
    
    /// De initializer(Reclaim memory)
    deinit {
        if session != nil { self.stop() }
        guard self.config != nil else { return }
        if self.config.isDebugDes { print("HandyScannerHelper deinit~") }
    }
}

/**
 User authorized camera status
 
 - parameter handler: authorized callback
 
 - returns: Return user authorized camera status
 */

public func requestAccess(handler: @escaping (Bool) -> (Void))  {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    switch status {
    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { res in handler(res) }
    case .authorized: handler(true)
    default: handler(false)
    }
}

/**
 Scale enum, default is Small
 
 Available cases:
 - **Large**: Enlarge
 - **Small**: Smaller
 */

@objc public enum DoubleTapState: Int { case Large, Small }

/**
 Animation style enum, default is LineMove
 
 Available cases:
 - **LineMove**: Move up and down
 - **LineCenter**: Center
 - **None**: No animation
 */

@objc public enum AnimationStyle: Int { case LineMove, LineCenter, None }

/**
 Angle style enum, default is OnLine
 
 Available cases:
 - **InLine**: Embedded
 - **OnLine**: Overlap
 - **OutLine**: Overhang
 - **None**: No style
 */

@objc public enum AngleStyle: Int { case InLine, OnLine, OutLine, None }

/**
 * HandyScannerResult
 *
 * value is Scan result string
 * metadataType is Scan result type
 */

@objc public class HandyScannerResult: NSObject {
    /// Scan result string
    var value: String
    /// Scan result type
    var metadataType: AVMetadataObject.ObjectType
    
    init(value: String, type: AVMetadataObject.ObjectType) {
        self.value = value
        self.metadataType = type
    }
}

@objc public protocol HandyScannerHelperProtocol: AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, UIGestureRecognizerDelegate {
    
    /**
     Start scan
     
     - parameter supView:     An incoming parent view.
     - parameter scanConfig:  HandyScannerConfig (Default: HandyScannerConfig()).
     - parameter scanRegion:  Valid scanning area. The default size is the same as that of the parent view.
     - parameter scanType:    The supported recognizable scanning types are the same as the system API by default.
     - parameter scanHandler: Scan result callback
     */
    
    @objc @available(iOS 10.0, *)
    func start(supView: UIView, scanConfig: HandyScannerConfig, scanRegion: CGRect, scanType: [AVMetadataObject.ObjectType], scanHandler: ((HandyScannerResult) -> Void)?)
    
    /**
     flash switch
     
     - parameter open: A Boolean value. The default is false
     */
    
    @objc @available(iOS 6.0, *)
    optional func torchFlash(open: Bool)
    
    /**
     Identify the content information in the picture (for details, please refer to the relevant API of the system cidetector, where the QR code content is identified by default)
     
     - parameter image:               A valid picture.
     - parameter ofType:              The type is used to specify the detection intent. (Default: CIDetectorTypeQRCode)
     - parameter context:             The context argument specifies the CIContext to be used to operate on the image. May be nil. (Default: nil)
     - parameter options:             The options parameter lets you optinally specify a accuracy / performance tradeoff. Can be nil or an empty dictionary. (Default: [[CIDetectorAccuracy: CIDetectorAccuracyHigh]]).
     
     - returns: Returns an array of CIFeature instances in the given image.
     */
    
    @objc @available(iOS 5.0, *)
    optional func detector(image: UIImage, ofType: String, context: CIContext?, options: [String : Any]?) -> [CIFeature]?
}

@objc public protocol HandyScannerDelegate: NSObjectProtocol {
    
    /**
     Optional
     
     - parameter bottomView: A view from the bottom of the scan box to the bottom area of the parent view
     
     */
    
    @objc @available(iOS 10.0, *)
    optional func scannerLimit(_ bottomView: UIView)
    
    /**
     Optional
     
     - parameter fullView: A view that is the same size as the parent view
     
     */
    
    @objc @available(iOS 10.0, *)
    optional func scannerUnrestrained(_ fullView: UIView)
    
    /**
     Optional
     
     - parameter values: scan result 'stringValue' array
     - parameter types:  scan result 'objectType' array
     
     */
    
    @objc @available(iOS 10.0, *)
    optional func scannerMetadataOutput(of values: Array<String>, by types: Array<AVMetadataObject.ObjectType>)
}
