# HandyScanner
# Swift5.0，基于系统API封装的扫描二维码、条形码、等多种条码扫描组件


# 注意事项:


# -- platform: ≥ iOS 10
# -- language: Object-C 、Swift



# 一）预览图



- [默认样式](https://user-images.githubusercontent.com/29021369/135749766-db3ece15-19c2-4c76-bb38-8f43d51124d0.JPG)


- [外悬样式](https://user-images.githubusercontent.com/29021369/135749785-12cc5d39-2450-4be1-a3d9-382e26ebb565.JPG)


- [内嵌样式](https://user-images.githubusercontent.com/29021369/135749795-db065cd7-76fd-4ee8-998e-5e2529ca684b.JPG)


- [底部View自定义预览](https://user-images.githubusercontent.com/29021369/136018974-4939a657-a32f-4dec-a1a9-06c9db860fd8.JPG)


- [全部UI自定义预览](https://user-images.githubusercontent.com/29021369/136019235-45c7e752-2671-4f95-9ca3-c777ba6b2bd1.JPG)




# 二）组件特性

- UI界面可完全自定义;
- 使用简单,犹如芊芊少女般丝滑、流畅;
- 无内存泄漏问题,及时回收内存资源,合理释放Class;
- 静态库'HandyScannerSDK.framework',身轻如燕,仅1.3M;
- 轻量级,只开启基础使用功能,仅占用 '12 ~ 16' 个内存, 启用全部功能, 内存占用在 '120 ~ 130'之间;



# 三）功能列表



|        key        |          type           |               des               |    true     |  false   |
| :----------------: | :---------------------: | :-----------------------------: | :---------: | :------: |
|      isSingle      |          bool           |       是否仅识别单一结果        |  单一结果   | 多个结果 |
|      isSquare      |          bool           |       是否展示正方形边框        |    展示     |  不展示  |
|    isAutoFocus     |          bool           |        是否开启自动对焦         |    开启     |   关闭   |
|    isDoubleTap     |          bool           |        是否支持双击手势         |    支持     |  不支持  |
|       isZoom       |          bool           |        是否支持缩放手势         |    支持     |  不支持  |
|     isHasTorch     |          bool           |  是否支持光感检测,自动打开闪光灯 |    支持     |  不支持  |
|       isLimit      |          bool           |        是否自定义底部UI         |    自定义   |  默认UI  |
|   isUnrestrained   |          bool           |        是否完全自定义UI         |    自定义   |  默认UI  |
|   isDebugDes       |          bool           |        是否打印调试信息         |    打印     |  不打印  |
|     soundSource    |          String         |         是否支持提示音        |   有效资源支持   |  默认不支持 |
|  animationImage    |         UIImage         |         扫描动画样式图        |   有效资源显示   |  默认不显示        |
| brightnessMinValue |         Double          |    自动开启闪光灯亮度对比值     |   小于此值开启   |   默认-1  |
| brightnessMaxValue |         Double          |    自动关闭闪光灯亮度对比值     |   大于此值关闭   |   默认7   |
|       preset       | AVCaptureSession.Preset |            扫描质量             | hd1920x1080 |   默认   |



# 四）样式列表




|       key        |      type      |                     des                     |
| :--------------: | :------------: | :-----------------------------------------: |
|      margin      |      Int       |          距离左右边界间距(默认60)           |
|    lineHeight    |      Int       |         正方形边框粗细(默认0个像素)         |
|    lineColor     |    UIColor     |          正方形边框颜色(默认clear)          |
|    angleColor    |    UIColor     |       正方形边框4个角颜色(默认orange)       |
|   angleLength    |      Int       |      正方形边框4个角长度(默认30个像素)      |
|   angleHeight    |      Int       |      正方形边框4个角高度(默认4个像素)       |
|    angleStyle    |   AngleStyle   |        正方形边框边角样式(默认重合)         |
|  animationStyle  | AnimationStyle |          扫码动画效果(默认无动画)           |
|  animationImage  |    UIImage     | 扫码动画资源图片(可选值,若为空则无动画效果) |
| unrecognizedArea |    UIColor     |    非识别区域背景色(默认黑色,0.5透明度)     |



# 五）集成方式

- CocoaPods

		pod 'HandyScanner'

- 手动导入

	[HandyScannerSDK](https://github.com/a51095/HandyScanner/tree/main/lib)


1) 下载静态资源包,拷贝导入到工程目录;
2) 选中 TARGETS -> Build Phases -> Link Binary With Libraries;
3) Link 下载好的静态包;
4) 若报错,请尝试使用真机调试；




# 六）使用方法


	import HandyScannerSDK


- 基础使用（单一识别结果,默认使用方式）

		/// 让控制器持有scanHelper对象,不然会被提前释放
		let scanHelper = HandyScannerHelper()
		override func viewDidLoad() {
			super.viewDidLoad()
			scanHelper.start(supView: view) { [weak self] (res) in
				guard let self = self else { return }
				print(res)
				self.navigationController?.popViewController(animated: true)
			}
		}

- 进阶使用（动画效果,使用属性,调整扫描框样式）

		/// 让控制器持有scanHelper对象,不然会被提前释放
		let scanHelper = HandyScannerHelper()

		override func viewDidLoad() {
			super.viewDidLoad()

			var config = HandyScannerConfig()
			config.soundSource = "scan_asudio"
			config.animationImage = UIImage(named: "scan_animation")
			config.isAutoFocus = false
			config.isHasTorch = false
			config.isZoom = false
			config.isSingle = false

			config.scanStyle.lineColor = .purple
			config.scanStyle.anmiationStyle = .LineCenter
			config.scanStyle.angleStyle = .OutLine

			// and so on ...

			scanHelper.start(supView: view, scanConfig: config) { [weak self] (res) in
				guard let self = self else { return }
				print(res)
				self.navigationController?.popViewController(animated: true)
			}
		}

- 高阶使用(自定义UI,及多个扫描结果)

		class HandyScannerViewController: UIViewController, HandyScannerDelegate {

            /// 让控制器持有scanHelper对象,不然会被提前释放
            let scanHelper = HandyScannerHelper()

            override func viewDidLoad() {
              super.viewDidLoad()
              defaultBackgroundColor()

              let config = HandyScannerConfig()
              config.isUnrestrained = true

              // ⚠️⚠️⚠️scanHandler回调,仅返回单一识别结果
              scanHelper.start(supView: view, scanConfig: config, scanHandler: nil)

            }

            // MARK: - 自定义底部视图(返回一个自定义view,从扫描框底部开始计算到父视图底部边缘区域视图)
            func scannerLimit(_ bottomView: UIView) {
              bottomView.backgroundColor = .orange
            }

            // MARK: - 完全自定义UI视图(返回一个自定义view,frame大小同父视图bounds)
            func scannerUnrestrained(_ fullView: UIView) {
              let v = UIView()
              v.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
              fullView.addSubview(v)
            }

            // MARK: - 多结果返回集合,values: 字符串结果数组, types: 扫描类型结果数组(⚠️⚠️⚠️仅多个结果才会执行此代理方法)
            func scannerMetadataOutput(of values: Array<String>, by types: Array<AVMetadataObject.ObjectType>) {
              print(values) 
            }

            // MARK: 反初始化器
            deinit {
              print("HandyScannerViewController deinit~")
            }
		}

# 七）API引导
- 核心方法
```
    /**
     Start scan
     
     - parameter supView:     An incoming parent view.
     - parameter scanConfig:  HandyScannerConfig (Default: HandyScannerConfig()).
     - parameter scanRegion:  Valid scanning area. The default size is the same as that of the parent view.
     - parameter scanType:    The supported recognizable scanning types are the same as the system API by default.
     - parameter scanHandler: Scan result callback
     */
    
    @available(iOS 10.0, *)
    open func start(supView: UIView, scanConfig: HandyScannerConfig = HandyScannerConfig(), scanRegion: CGRect = .zero, scanType: [AVMetadataObject.ObjectType] = [], scanHandler: ((HandyScannerResult) -> Void)?)
```
- 代理方法

```
    /**
     Optional
     
     - parameter bottomView: A view from the bottom of the scan box to the bottom area of the parent view
     
     */
    
    @available(iOS 10.0, *)
    func scannerLimit(_ bottomView: UIView)
    
    /**
     Optional
     
     - parameter fullView: A view that is the same size as the parent view
     
     */
    
    @available(iOS 10.0, *)
    func scannerUnrestrained(_ fullView: UIView)
    
    /**
     Optional
     
     - parameter values: scan result 'stringValue' array
     - parameter types:  scan result 'objectType' array
     
     */
    
    @available(iOS 10.0, *)
    func scannerMetadataOutput(of values: Array<String>, by types: Array<AVMetadataObject.ObjectType>)
```
- 闪光灯
```
    /**
     flash switch
     
     - parameter open: A Boolean value. The default is false
     */
    
    open func torchFlash(open: Bool)
```
- 识别照片内容api(默认用于识别照片二维码)
```
    /**
     Identify the content information in the picture (for details, please refer to the relevant API of the system cidetector, where the QR code content is identified by default)
     
     - parameter image:               A valid picture.
     - parameter ofType:              The type is used to specify the detection intent. (Default: CIDetectorTypeQRCode)
     - parameter context:             The context argument specifies the CIContext to be used to operate on the image. May be nil. (Default: nil)
     - parameter options:             The options parameter lets you optinally specify a accuracy / performance tradeoff. Can be nil or an empty dictionary. (Default: [[CIDetectorAccuracy: CIDetectorAccuracyHigh]]).
     
     - returns: Returns an array of CIFeature instances in the given image.
     */
    open func detector(image: UIImage, ofType: String = CIDetectorTypeQRCode, context: CIContext? = nil, options: [String : Any]? = [CIDetectorAccuracy: CIDetectorAccuracyHigh]) -> Array<CIFeature>?
```

