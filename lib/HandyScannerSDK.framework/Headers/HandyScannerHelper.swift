//
//  HandyScannerHelper.swift
//  HandyScanner
//
//  Created by well on 2021/10/3.
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
    
    /// MARK: - Core method
    @objc public func start(supView: UIView, scanConfig: HandyScannerConfig = HandyScannerConfig(), scanRegion: CGRect = .zero, scanType: [AVMetadataObject.ObjectType] = [], scanHandler: ((HandyScannerResult) -> Void)?) {
        
        requestAccess { res in
            // 用户授权相机权限后,执行后续操作
            guard res else {
                if scanConfig.isDebugDes {
                    print("⚠️⚠️⚠️===>>>,The Camera not authorized!!!")
                }
                return
            }
            
            guard (self.device != nil) else {
                if scanConfig.isDebugDes {
                    print("⚠️⚠️⚠️===>>>,The simulator does not have a scanning device!!!")
                }
                return
            }
            
            self.supView = supView
            self.config = scanConfig
            self.handler = scanHandler
            
            // 输入输出管理对象
            self.session = AVCaptureSession()
            // 输入对象
            self.input = try? AVCaptureDeviceInput(device: self.device!)
            // metaData输出对象
            self.metaDataOutput = AVCaptureMetadataOutput()
            // 处理扫描信息代理对象
            self.metaDataOutput?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            // 添加输入源
            if self.session!.canAddInput(self.input!) {
                self.session!.addInput(self.input!)
            }
            
            // 添加输出源
            if self.session!.canAddOutput(self.metaDataOutput!) {
                self.session?.addOutput(self.metaDataOutput!)
            }
            
            // 输出的质量级别
            if self.session!.canSetSessionPreset(scanConfig.preset) {
                self.session?.sessionPreset = scanConfig.preset
            }
            
            // 可识别的元数据对象类型字符串数组
            self.setMetadataObjTypes(scanType)
            
            // 多线程异步处理扫描配置项
            DispatchQueue.global().async {
                // 添加addPhotoOutput输出源
                if scanConfig.isDoubleTap || scanConfig.isZoom { self.addPhotoOutput() }
                // 开启光感检测,闪光灯效果
                if scanConfig.isHasTorch { self.addVideoDataOutput() }
                // 开启自动对焦
                if scanConfig.isAutoFocus { self.addAutoFocus() }
                // 开启扫码提示音
                if scanConfig.soundSource != nil { self.addAVPlayer() }
            }
            
            // 主线程异步处理扫描配置项
            DispatchQueue.main.async {
                // 核心动画层,在捕获视频时显示视频
                self.addPreviewLayer()
                // 通过系统计算扫描区域的矩形坐标位置
                self.rectOfInterestConverted(scanRegion)
                // 开启缩放手势效果
                if scanConfig.isZoom { self.addPinchTap() }
                // 开启双击手势效果
                if scanConfig.isDoubleTap { self.addDoubleTap() }
                // 初始化子视图
                self.addSubView()
            }
            
            // 延迟0.01秒后,执行扫描(预留光感闪光灯输出源初始化时长)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                // 开始扫描
                self.start()
            }
        }
    }
    
    /// 开始扫描
    private func start() {
        // 容错处理,若正在扫描,则直接返回
        guard !self.session!.isRunning else { return }
        self.session?.startRunning()
    }
    
    /// 停止扫描
    public func stop() {
        // 容错处理,若没在扫描,则直接返回
        guard self.session!.isRunning else { return }
        // 输入输出管理对象停止运行
        self.session?.stopRunning()
        // 移除自定义蒙层视图
        self.scanView?.removeFromSuperview()
        // 移除输入源
        for output in  self.session!.outputs {  self.session!.removeOutput(output) }
        // 移除输出源
        for input in  self.session!.inputs {  self.session!.removeInput(input) }
        // 若闪光灯为打开状态,则关闭掉
        if  self.device?.torchMode == .on {  self.torchFlash(open: false) }
        // 若预览视图被放大,则先复原
        if  self.effectiveScale > 1 {
            self.zoomPreview(scale: 1, immediately: true)
        }
        // 移除观察者模式
        NotificationCenter.default.removeObserver(self, name: .AVCaptureInputPortFormatDescriptionDidChange, object: nil)
    }
    
    /// 子视图初始化
    private func addSubView() {
        // 完全自定义UI
        if self.config.isUnrestrained {
            let fullView = UIView()
            self.supView.addSubview(fullView)
            fullView.frame = self.supView.bounds
            self.delegate?.scannerUnrestrained(fullView)
        }else {
            // 添加自定义扫描框视图
            if self.config.isSquare { self.addScanView() }
        }
    }
    
    /// 可识别的元数据对象类型字符串数组
    private func setMetadataObjTypes(_ scanType: Array<AVMetadataObject.ObjectType>)  {
        self.metadataObjectTypes = self.metaDataOutput!.availableMetadataObjectTypes
        if !scanType.isEmpty { self.metadataObjectTypes = scanType }
        // 可识别的元数据对象类型字符串数组
        self.metaDataOutput?.metadataObjectTypes = self.metadataObjectTypes
    }
    
    /// 添加系统观察者模式,计算有效扫描区域
    private func rectOfInterestConverted(_ scanRegion: CGRect) {
        var interestRect: CGRect = supView.frame
        if !scanRegion.equalTo(.zero) { interestRect = scanRegion }
        
        let notificationBlock: ((Notification) -> Void) = { [weak self] _ in
            guard let self = self else { return }
            self.metaDataOutput?.rectOfInterest = self.previewLayer!.metadataOutputRectConverted(fromLayerRect: interestRect)
        }
        
        NotificationCenter.default.addObserver(forName: .AVCaptureInputPortFormatDescriptionDidChange, object: nil, queue: .main, using: notificationBlock)
    }
    
    /// 开启扫码播放音
    private func addAVPlayer()  {
        let path = Bundle.main.path(forResource: config.soundSource, ofType: "wav")
        guard path != nil else { return }
        
        let url = URL(fileURLWithPath: path!)
        aVPlayer = AVPlayer(url: url)
    }
    
    /// 开启自动对焦
    private func addAutoFocus() {
        try?  self.device?.lockForConfiguration()
        self.device?.focusMode = .continuousAutoFocus
        self.device?.unlockForConfiguration()
    }
    
    /// 添加预览图层
    private func addPreviewLayer() {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session!)
        self.previewLayer?.frame = self.supView.bounds
        self.previewLayer?.videoGravity = .resizeAspectFill
        self.supView.layer.insertSublayer(self.previewLayer!, at: 0)
    }
    
    /// 添加自定义蒙层视图
    private func addScanView() {
        self.scanView = HandyScannerView(style: self.config.scanStyle)
        self.scanView.frame = self.supView.bounds
        self.scanView.scanAreaBlock = { [weak self](res) in
            
            guard let self = self else { return }
            if self.config.isDebugDes {
                print("Coordinate position of middle scanning frame(relative to parent view): \(res)")
            }
            
            if self.config.isLimit {
                // 扫描框高度
                let scanViewHeight = res.height
                // 扫描框起点Y坐标
                let scanViewMinY = res.origin.y
                // 扫描框终点Y坐标
                let scanViewMaxY = scanViewMinY + scanViewHeight
                
                // 偏移量 = 扫描角高度 / 2
                let offsetH: CGFloat = (self.config.scanStyle.angleHeight / 2).cgf
                
                let bottomView = UIView()
                self.supView.addSubview(bottomView)
                bottomView.frame = CGRect(x: 0, y: scanViewMaxY + offsetH, width: self.supView.frame.size.width, height: self.supView.frame.size.height - (scanViewMaxY + offsetH))
                
                self.delegate?.scannerLimit(bottomView)
            }
        }
        self.supView.addSubview(self.scanView)
    }
    
    /// 添加videoData输出对象
    private func addVideoDataOutput() {
        if self.session!.canAddOutput(self.videoDataOutput) { self.session?.addOutput(self.videoDataOutput) }
    }
    
    /// 添加photoOutput输出对象
    private func addPhotoOutput() {
        guard self.session!.canAddOutput(self.photoOutput) else { return }
        self.session?.addOutput(self.photoOutput)
        self.deviceMaxScale = self.photoOutput.connection(with: .video)!.videoMaxScaleAndCropFactor / 16
    }
    
    /// 添加双击手势
    private func addDoubleTap() {
        DispatchQueue.main.async {
            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(self.doubleTapClick))
            doubleTap.numberOfTapsRequired = 2
            self.supView.addGestureRecognizer(doubleTap)
        }
    }
    
    /// 双击手势事件
    @objc private func doubleTapClick(gesture: UIGestureRecognizer) {
        if doubleTapState == .Small {
            zoomPreview(scale: deviceMaxScale)
            doubleTapState = .Large
        }else {
            zoomPreview(scale: 1)
            doubleTapState = .Small
        }
    }
    
    /// 添加缩放手势
    private func addPinchTap() {
        let pinchTap = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchTapClick))
        pinchTap.delegate = self
        self.supView.addGestureRecognizer(pinchTap)
    }
    
    /// 缩放手势事件
    @objc private func pinchTapClick(gesture: UIPinchGestureRecognizer) {
        effectiveScale = defaultScale * gesture.scale
        // 容错处理,若有效缩放比例小于1,则让有效值恒等于1(有效取值范围≥1)
        if effectiveScale < 1 {
            effectiveScale = 1
            doubleTapState = .Small
        }
        zoomPreview(scale: effectiveScale)
    }
    
    /// 缩放预览视图
    private func zoomPreview(scale: CGFloat, immediately: Bool = false) {
        try? device?.lockForConfiguration()
        guard let videoConnection = connection(mediaType: AVMediaType.video.rawValue, connections: photoOutput.connections) else { return }
        
        effectiveScale = scale
        // 容错处理,若传进来的放大比例大于系统最大值,则调整effectiveScale = deviceMaxScale
        if effectiveScale > deviceMaxScale {
            effectiveScale = deviceMaxScale
            doubleTapState = .Large
        }
        
        let zoomValue = effectiveScale / videoConnection.videoScaleAndCropFactor
        videoConnection.videoScaleAndCropFactor = effectiveScale
        device?.unlockForConfiguration()
        
        let oriTransform = previewLayer?.transform
        if !immediately {
            UIView.animate(withDuration: 0.3) {
                self.previewLayer?.transform = CATransform3DScale(oriTransform!, zoomValue, zoomValue, zoomValue)
            }
        }else {
            self.previewLayer?.transform = CATransform3DScale(oriTransform!, zoomValue, zoomValue, zoomValue)
        }
    }
    
    /// 获取videoConnection对象
    private func connection(mediaType: String, connections: Array<AVCaptureConnection>) -> AVCaptureConnection? {
        for connection in connections {
            for port in connection.inputPorts {
                if port.mediaType.rawValue.isEqual(mediaType) {
                    return connection
                }
            }
        }
        return nil
    }
    
    /// MARK: - Flash on / off
    public func torchFlash(open: Bool) {
        try? device?.lockForConfiguration()
        if open {
            device?.torchMode = .on
        }else {
            device?.torchMode = .off
        }
        device?.unlockForConfiguration()
    }
    
    /// MARK: - Identify photo content (default identification QR code)
    public func detector(image: UIImage, ofType: String = CIDetectorTypeQRCode, context: CIContext? = nil, options: [String : Any]? = [CIDetectorAccuracy: CIDetectorAccuracyHigh]) -> Array<CIFeature>? {
        
        let cIDetector = CIDetector(ofType: ofType, context: context, options: options)
        let ciImage : CIImage = CIImage(image: image)!
        let features = cIDetector?.features(in: ciImage)
        
        return features
    }
    
    /// MARK: - A gesture of Zoom
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UIPinchGestureRecognizer.self) { defaultScale = effectiveScale }
        return true
    }
    
    ///  MARK: - AVCaptureMetadataOutputObjectsDelegate
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        // 若扫描空白处,则直接返回,减少内存资源消耗
        guard !metadataObjects.isEmpty else { return }
        
        // 单一结果处理
        if self.config!.isSingle {
            if let metadataObj = metadataObjects.last as? AVMetadataMachineReadableCodeObject {
                if self.metadataObjectTypes.contains(metadataObj.type) {
                    if let res = metadataObj.stringValue {
                        self.aVPlayer?.play()
                        self.stop()
                        let result = HandyScannerResult(value: res, type: metadataObj.type)
                        DispatchQueue.main.async { self.handler?(result) }
                    }
                }
            }
        }else {
            // 复合结果处理
            for item in metadataObjects {
                if let metadataObj = item as? AVMetadataMachineReadableCodeObject {
                    if self.metadataObjectTypes.contains(metadataObj.type) {
                        if let res = metadataObj.stringValue {
                            if !self.valueArray.contains(res) {
                                self.valueArray.append(res)
                                self.typeArray.append(metadataObj.type)
                            }
                        }
                    }
                    self.aVPlayer?.play()
                    self.stop()
                    DispatchQueue.main.async {
                        self.delegate?.scannerMetadataOutput(of: self.valueArray, by: self.typeArray)
                    }
                }
            }
        }
    }
    
    /// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 容错处理,不支持闪光灯的设备,则直接返回
        guard device!.hasTorch else { return }
        
        if config.isHasTorch {
            let cfDictionary = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
            // 容错处理,解析cfDictionary为空值,则直接返回
            guard cfDictionary != nil else { return }
            
            let metaDic = NSMutableDictionary.init(dictionary: cfDictionary!)
            let exifMetaData: NSDictionary = metaDic.object(forKey: kCGImagePropertyExifDictionary) as! NSDictionary
            let currentValue = exifMetaData.object(forKey: kCGImagePropertyExifBrightnessValue) as! Double
            
            if currentValue < config.brightnessMinValue {
                torchFlash(open: true)
            }else if currentValue > config.brightnessMaxValue {
                torchFlash(open: false)
            }
        }
    }
}
