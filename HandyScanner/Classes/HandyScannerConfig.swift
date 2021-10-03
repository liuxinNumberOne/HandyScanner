//
//  HandyScannerConfig.swift
//  HandyScanner
//
//  Created by well on 2021/10/3.
//

@_exported import UIKit
@_exported import PhotosUI
@_exported import Foundation
@_exported import AVFoundation

/// 屏幕宽
func kScreenWidth() -> Int { UIScreen.main.bounds.width.i }
/// 屏幕高
func kScreenHeight() -> Int { UIScreen.main.bounds.height.i }

extension BinaryFloatingPoint {
    /// 浮点型转整型
    var i: Int { return Int(self) }
}

extension FixedWidthInteger {
    /// 整型转CGFloat
    var cgf: CGFloat { CGFloat(self) }
}

/// 用户相机授权状态
func requestAccess(handler: @escaping (Bool) -> (Void))  {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    switch status {
    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { res in handler(res) }
    case .authorized: handler(true)
    default: handler(false)
    }
}

enum DoubleTapState {
    /// 大、小
    case Large, Small
}

enum AnimationStyle {
    /// 上下移动、居中悬停、无动画
    case LineMove, LineCenter, None
}

enum AngleStyle {
    /// 内嵌、重合、外悬、无
    case InLine, OnLine, OutLine, None
}

struct HandyScannerResult {
    // 扫描结果个数(默认0,无扫描结果)
    var count: Int = 0
    // 扫描结果集内容数组
    var results: [String]? = nil
    // 扫描结果集类型数组
    var metadataTypes: [String]? = nil
}

struct HandyScannerConfig {
    /// 是否只识别单一结果(默认单一结果集)
    var isSingle: Bool = true
    /// 是否展示正方形边框(默认展示)
    var isSquare: Bool = true
    /// 是否自动对焦(默认支持)
    var isAutoFocus: Bool = true
    /// 是否支持双击手势(默认支持)
    var isDoubleTap: Bool = true
    /// 是否支持缩放手势(默认支持)
    var isZoom: Bool = true
    /// 是否支持光感检测,自动打开闪光灯(默认支持)
    var isHasTorch: Bool = true
    /// 自动开启闪光灯亮度对比值(默认小于-1时开启)  [经测试取值范围在(-10 ~ 10)之间,有误差]
    var brightnessMinValue: Double = -1
    /// 自动关闭闪光灯亮度对比值(默认大于8时关闭)
    var brightnessMaxValue: Double = 8
    /// 扫描质量(默认hd1920x1080)
    var preset: AVCaptureSession.Preset = .hd1920x1080
    ///  扫描成功是否播放提示音(默认无声音,需要自己配置)
    var soundSource: String?
    ///  扫描动画样式图(默认无动画,需要自己配置)
    var animationImage: UIImage? = nil {
        willSet {
            guard newValue != nil else { return }
            scanStyle.animationImage = newValue
            scanStyle.anmiationStyle = .LineMove
        }
    }
    ///  默认扫描样式
    var scanStyle = HandyScannerStyle()
}

struct HandyScannerStyle {
    /// 距离边界间距(默认60)
    var margin: Int = 60
    /// 正方形边框粗细(默认0个像素)
    var lineHeight: Int = 0
    /// 正方形边框颜色(默认clear)
    var lineColor: UIColor = .clear
    /// 正方形边框4个角颜色(默认orange)
    var angleColor: UIColor = .orange
    /// 正方形边框4个角长度(默认30个像素)
    var angleLength: Int = 30
    /// 正方形边框4个角高度(默认4个像素)
    var angleHeight: Int = 4
    /// 正方形边框边角样式(默认重合)
    var angleStyle: AngleStyle = .OnLine
    /// 扫码动画效果(默认无动画)
    var anmiationStyle: AnimationStyle = .None
    /// 扫码动画资源图片(可选值,若为空则无动画效果)
    var animationImage: UIImage?
    /// 非识别区域背景色(默认黑色,0.5透明度)
    var unrecognizedArea: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
}
