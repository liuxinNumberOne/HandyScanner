# HandyScanner
# Swift5.0，基于系统API封装的扫描二维码、条形码、等多种条码扫描组件

# 一）预览图


- [默认样式](https://user-images.githubusercontent.com/29021369/135749766-db3ece15-19c2-4c76-bb38-8f43d51124d0.JPG)


- [外悬样式](https://user-images.githubusercontent.com/29021369/135749785-12cc5d39-2450-4be1-a3d9-382e26ebb565.JPG)


- [内嵌样式](https://user-images.githubusercontent.com/29021369/135749795-db065cd7-76fd-4ee8-998e-5e2529ca684b.JPG)




# 二）组件特性

- 使用简单,犹如芊芊少女般丝滑、流畅;
- 无内存泄漏问题,合理及时销毁回收内存资源;
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
|     soundSource    |          String         |         是否支持提示音        |   有效资源支持,反之不支持   |
| brightnessMinValue |         Double          |    自动开启闪光灯亮度对比值     |   小于此值开启   |   默认-1  |
| brightnessMaxValue |         Double          |    自动关闭闪光灯亮度对比值     |   大于此值关闭   |   默认8   |
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

	  pod 'HandyScanner'


# 六）使用方法


- 基础使用（默认使用方式）
	
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
	
- 进阶使用（带动画效果）

		/// 让控制器持有scanHelper对象,不然会被提前释放
		let scanHelper = HandyScannerHelper()

		override func viewDidLoad() {
			super.viewDidLoad()

			var config = HandyScannerConfig()
			config.animationImage = UIImage(named: "scan_animation")
			scanHelper.start(supView: view, scanConfig: config) { [weak self] (res) in
				guard let self = self else { return }
				print(res)
				self.navigationController?.popViewController(animated: true)
			}
		}
	
- 高阶使用（自定义扫描框样式）

		/// 让控制器持有scanHelper对象,不然会被提前释放
		let scanHelper = HandyScannerHelper()

		override func viewDidLoad() {
			super.viewDidLoad()

			var config = HandyScannerConfig()
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
