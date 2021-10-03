//
//  HandyScannerHelper.swift
//  HandyScanner
//
//  Created by well on 2021/10/3.
//

class HandyScannerHelper: NSObject, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, UIGestureRecognizerDelegate {
    /// 扫描参数
    private var config: HandyScannerConfig!
    /// 设备
    private var device: AVCaptureDevice?
    /// 设备输入源
    private var input: AVCaptureDeviceInput?
    /// metadata输出源
    private var metaDataOutput: AVCaptureMetadataOutput?
    /// 设备输入输出管理者
    private var session: AVCaptureSession?
    /// 扫描视图所在的父视图
    private var supView: UIView!
    /// 扫描视图
    private var scanView: HandyScannerView!
    /// 扫描预览图层
    private var previewLayer: AVCaptureVideoPreviewLayer?
    /// 扫描结果数组(扫描内容)
    private var valueArray = [String]()
    /// 扫描结果数组(扫描类型)
    private var typeArray = [String]()
    /// 支持的扫描类型数组(默认为系统支持的所有类型)
    private var metadataObjectTypes = [AVMetadataObject.ObjectType]()
    /// 扫描结果回调
    private var handler: ((HandyScannerResult) -> Void)?
    /// 双击手势状态(默认小,即初始状态)
    private var doubleTapState: DoubleTapState = .Small
    /// 设备初始缩放比例(默认为1)
    private var defaultScale: CGFloat = 1
    /// 设备有效缩放比例(默认为1)
    private var effectiveScale: CGFloat = 1
    /// 设备最大缩放比例(默认为1)
    private var deviceMaxScale: CGFloat = 1
    
    /// 懒加载videoData输出对象
    private lazy var videoDataOutput: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        output.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA]
        return output
    }()
    
    /// 懒加载photoOutput输出对象
    private lazy var photoOutput: AVCapturePhotoOutput = {
        let output = AVCapturePhotoOutput()
        return output
    }()
    
    // MARK: - 反初始化器
    deinit {
        if session != nil { stop() }
        print("HandyScannerHelper deinit~")
    }
    
    /// 启动扫描组件
    public func start(supView: UIView, scanConfig: HandyScannerConfig = HandyScannerConfig(), scanRegion: CGRect = .zero, scanType: [AVMetadataObject.ObjectType] = [], result: @escaping ((HandyScannerResult) -> Void)) {
        
        
        requestAccess { res in
            // 用户授权相机权限后,执行后续操作
            guard res else { print("⚠️⚠️⚠️===>>>,The Camera not authorized!!!"); return }
            
            // 启用相机设备
            self.device = AVCaptureDevice.default(for: .video)
            
            guard (self.device != nil) else { print("⚠️⚠️⚠️===>>>,The simulator does not have a scanning device!!!"); return }
            
            self.handler = result
            self.supView = supView
            self.config = scanConfig
            
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
            
            DispatchQueue.main.async {
                // 核心动画层,在捕获视频时显示视频
                self.addPreviewLayer()
                // 通过系统计算扫描区域的矩形坐标位置
                self.rectOfInterestConverted(scanRegion)
                // 开启缩放手势效果
                if scanConfig.isZoom { self.addPinchTap() }
                // 开启双击手势效果
                if scanConfig.isDoubleTap { self.addDoubleTap() }
            }
            
            DispatchQueue.global().async {
                // 添加addPhotoOutput输出源
                if scanConfig.isDoubleTap || scanConfig.isZoom { self.addPhotoOutput() }
                // 开启光感检测,闪光灯效果
                if scanConfig.isHasTorch { self.addVideoDataOutput() }
                // 开启自动对焦
                if scanConfig.isAutoFocus { self.addAutoFocus() }
            }
            
            // 延迟0.01秒后,执行扫描(预留光感闪光灯输出源初始化时长)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                // 添加自定义扫描框视图(此处可扩展,自定义UI)
                if scanConfig.isSquare { self.addScanView() }
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
    private func stop() {
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
    
    // 可识别的元数据对象类型字符串数组
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
    
    /// 开启自动对焦
    func addAutoFocus() {
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
        self.scanView.scanAreaBlock = { (res) in print("Coordinate position of middle scanning frame(relative to parent view): \(res)") }
        self.supView.addSubview(self.scanView)
    }
    
    /// 添加videoData输出对象
    private func addVideoDataOutput() {
        if self.session!.canAddOutput(self.videoDataOutput) { self.session?.addOutput(self.videoDataOutput)
        }
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
    @objc func doubleTapClick(gesture: UIGestureRecognizer) {
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
    @objc func pinchTapClick(gesture: UIPinchGestureRecognizer) {
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
    
    /// 闪光灯状态(打开/关闭)
    private func torchFlash(open: Bool) {
        try? device?.lockForConfiguration()
        if open {
            device?.torchMode = .on
        }else {
            device?.torchMode = .off
        }
        device?.unlockForConfiguration()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UIPinchGestureRecognizer.self) { defaultScale = effectiveScale }
        return true
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        // 若扫描空白处,则直接返回,减少内存资源消耗
        guard !metadataObjects.isEmpty else { return }
        
        // 单一结果处理
        if self.config!.isSingle {
            if let metadataObj = metadataObjects.last as? AVMetadataMachineReadableCodeObject {
                if self.metadataObjectTypes.contains(metadataObj.type) {
                    if let res = metadataObj.stringValue {
                        self.stop()
                        let result = HandyScannerResult(count: 1, results: [res], metadataTypes: [metadataObj.type.rawValue])
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
                                self.typeArray.append(metadataObj.type.rawValue)
                            }
                        }
                    }
                    self.stop()
                    let results = HandyScannerResult(count: self.valueArray.count, results: self.valueArray, metadataTypes: self.typeArray)
                    DispatchQueue.main.async { self.handler?(results) }
                }
            }
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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
