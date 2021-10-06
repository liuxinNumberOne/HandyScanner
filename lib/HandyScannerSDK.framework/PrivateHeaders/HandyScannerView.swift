//
//  HandyScannerView.swift
//  HandyScanner
//
//  Created by well on 2021/10/3.
//

public class HandyScannerView: UIView {
    /// 正方形坐标位置
    private var rectOfInterest: CGRect = .zero
    /// 扫描视图样式
    private var style: HandyScannerStyle
    /// 正方形坐标位置回调
    public var scanAreaBlock: ((CGRect) -> Void)?
    /// 懒加载动画视图
    private lazy var animationView: UIImageView = {
        let iV =  UIImageView()
        iV.layer.masksToBounds = true
        iV.contentMode = .scaleAspectFill
        return iV
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 反初始化器
    deinit {
        // 移除动画
        stopScanAnimation()
        if style.isDebug { print("HandyScannerView deinit~") }
    }
    
    /// 初始化器
    init(style: HandyScannerStyle = HandyScannerStyle()) {
        self.style = style
        super.init(frame: .zero)
        self.setBackgroundColor()
    }
    
    /// 设置背景色
    private func setBackgroundColor() { backgroundColor = .clear }
    
    public override func draw(_ rect: CGRect) {
        let autoWidth = frame.width.i - style.margin * 2
        let scanSize = CGSize(width: autoWidth, height: autoWidth)
        let scanMinY = frame.size.height / 2 - scanSize.height / 2
        let scanMaxY = scanMinY + scanSize.height
        let scanMaxX = frame.width.i - style.margin
        
        // 正方形坐标位置(相对于父视图)
        rectOfInterest = CGRect(x: style.margin, y: scanMinY.i, width: autoWidth, height: autoWidth)
        
        let context = UIGraphicsGetCurrentContext()
        let components = style.unrecognizedArea.cgColor.components
        context?.setFillColor(components!)
        
        // top区域
        let topReact = CGRect(x: 0, y: 0, width: frame.size.width.i, height: scanMinY.i)
        
        // left区域
        let leftReact = CGRect(x: 0, y: scanMinY.i, width: style.margin, height: scanSize.height.i)
        
        // bottom区域
        let bottomReact = CGRect(x: 0, y: scanMaxY.i, width: frame.size.width.i, height: frame.size.height.i - scanMinY.i)
        
        // right区域
        let rightReact = CGRect(x: scanMaxX, y: scanMinY.i, width: style.margin, height: scanSize.height.i)
        
        context?.fill([topReact,leftReact,bottomReact,rightReact])
        // 开始绘制非正方形区域
        context?.strokePath()
        
        // center区域
        let lineHeight = style.lineHeight
        
        let centerReact = CGRect(x: style.margin + (lineHeight / 2), y: scanMinY.i + (lineHeight / 2), width: autoWidth - lineHeight, height: autoWidth - lineHeight)
        context?.setStrokeColor(style.lineColor.cgColor)
        context?.setLineWidth(lineHeight.cgf)
        context?.addRect(centerReact)
        // 开始绘制正方形区域
        context?.strokePath()
        
        let angleHeight = style.angleHeight
        let angleLength = style.angleLength
        
        context?.setStrokeColor(style.angleColor.cgColor)
        context?.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context?.setLineWidth(angleHeight.cgf)
        
        guard style.angleStyle != .None else { return }
        
        switch style.angleStyle {
        case .None: return
        case .OutLine:
            // 左上角水平线
            context?.move(to: CGPoint(x: style.margin.cgf, y: scanMinY - (style.angleHeight / 2).cgf))
            context?.addLine(to: CGPoint(x: style.margin.cgf + style.angleLength.cgf, y: scanMinY - (style.angleHeight / 2).cgf))
            
            // 左上角垂直线
            context?.move(to: CGPoint(x: (style.margin - style.angleHeight / 2).cgf, y: scanMinY - (style.angleHeight).cgf))
            context?.addLine(to: CGPoint(x: (style.margin - style.angleHeight / 2).cgf, y: scanMinY + (style.angleLength).cgf))
            
            // 左下角垂直线
            context?.move(to: CGPoint(x: (style.margin - style.angleHeight / 2).cgf, y: scanMaxY - (style.angleLength).cgf))
            context?.addLine(to: CGPoint(x: (style.margin - style.angleHeight / 2).cgf, y: scanMaxY + style.angleHeight.cgf))
            
            // 左下角水平线
            context?.move(to: CGPoint(x: style.margin.cgf, y: scanMaxY + (style.angleHeight / 2).cgf))
            context?.addLine(to: CGPoint(x: style.margin.cgf + style.angleLength.cgf, y: scanMaxY + (style.angleHeight / 2).cgf))
            
            // 右下角水平线
            context?.move(to: CGPoint(x: (scanMaxX - style.angleLength).cgf, y: scanMaxY + (style.angleHeight / 2).cgf))
            context?.addLine(to: CGPoint(x: scanMaxX.cgf, y: scanMaxY + (style.angleHeight / 2).cgf))
            
            // 右下角垂直线
            context?.move(to: CGPoint(x: (scanMaxX + style.angleHeight / 2).cgf, y: scanMaxY + style.angleHeight.cgf))
            context?.addLine(to: CGPoint(x: (scanMaxX + style.angleHeight / 2).cgf, y: scanMaxY - (style.angleLength).cgf))
            
            // 右上角垂直线
            context?.move(to: CGPoint(x: (scanMaxX + style.angleHeight / 2).cgf, y: scanMinY - style.angleHeight.cgf))
            context?.addLine(to: CGPoint(x: (scanMaxX + style.angleHeight / 2).cgf, y: scanMinY + angleLength.cgf))
            
            // 右上角水平线
            context?.move(to: CGPoint(x: (scanMaxX - style.angleLength).cgf, y: scanMinY - (style.angleHeight / 2).cgf))
            context?.addLine(to: CGPoint(x: scanMaxX.cgf, y: scanMinY - (style.angleHeight / 2).cgf))
            
        case .InLine:
            // 左上角水平线
            context?.move(to: CGPoint(x: (style.margin + style.lineHeight).cgf, y: scanMinY + (style.lineHeight + style.angleHeight / 2).cgf))
            context?.addLine(to: CGPoint(x: (style.margin + style.angleLength + style.lineHeight).cgf, y: scanMinY + (style.lineHeight + style.angleHeight / 2).cgf))
            
            // 左上角垂直线
            context?.move(to: CGPoint(x: (style.margin + style.lineHeight + style.angleHeight / 2).cgf, y: scanMinY + style.lineHeight.cgf))
            context?.addLine(to: CGPoint(x: (style.margin + style.lineHeight + style.angleHeight / 2).cgf, y: scanMinY + (style.angleLength + style.lineHeight).cgf))
            
            // 左下角垂直线
            context?.move(to: CGPoint(x: (style.margin + style.lineHeight + style.angleHeight / 2).cgf, y: scanMaxY - (style.angleLength + style.lineHeight).cgf))
            context?.addLine(to: CGPoint(x: (style.margin + style.lineHeight + style.angleHeight / 2).cgf, y: scanMaxY - style.lineHeight.cgf))
            
            // 左下角水平线
            context?.move(to: CGPoint(x: (style.margin + style.lineHeight).cgf, y: scanMaxY - (style.lineHeight + style.angleHeight / 2).cgf))
            context?.addLine(to: CGPoint(x: (style.margin + style.lineHeight + style.angleLength).cgf, y: scanMaxY - (style.lineHeight + style.angleHeight / 2).cgf))
            
            // 右下角水平线
            context?.move(to: CGPoint(x: (scanMaxX - style.angleLength - style.lineHeight).cgf, y: scanMaxY - (style.lineHeight + style.angleHeight / 2).cgf))
            context?.addLine(to: CGPoint(x: (scanMaxX - style.lineHeight).cgf, y: scanMaxY - (style.lineHeight + style.angleHeight / 2).cgf))
            
            // 右下角垂直线
            context?.move(to: CGPoint(x: (scanMaxX - style.lineHeight - style.angleHeight / 2).cgf, y: scanMaxY - style.lineHeight.cgf))
            context?.addLine(to: CGPoint(x: (scanMaxX - style.lineHeight - style.angleHeight / 2).cgf, y: scanMaxY - (style.lineHeight + style.angleLength).cgf))
            
            // 右上角垂直线
            context?.move(to: CGPoint(x: (scanMaxX - style.lineHeight - style.angleHeight / 2).cgf, y: scanMinY + (style.lineHeight + style.angleLength).cgf))
            context?.addLine(to: CGPoint(x: (scanMaxX - style.lineHeight - style.angleHeight / 2).cgf, y: scanMinY + (style.lineHeight).cgf))
            
            // 右上角水平线
            context?.move(to: CGPoint(x: (scanMaxX - style.lineHeight).cgf, y: scanMinY + (style.lineHeight + style.angleHeight / 2).cgf))
            context?.addLine(to: CGPoint(x: (scanMaxX - style.angleLength - style.lineHeight).cgf, y: scanMinY + (style.lineHeight + style.angleHeight / 2).cgf))
            
        case .OnLine:
            // 左上角水平线
            context?.move(to: CGPoint(x: (style.margin + style.lineHeight / 2 - style.angleHeight / 2).cgf, y: scanMinY + (style.lineHeight / 2).cgf))
            context?.addLine(to: CGPoint(x: (style.margin + style.angleLength + style.lineHeight / 2).cgf, y: scanMinY + (style.lineHeight / 2).cgf))
            
            // 左上角垂直线
            context?.move(to: CGPoint(x: (style.margin + style.lineHeight / 2 ).cgf, y: scanMinY + (style.lineHeight / 2).cgf))
            context?.addLine(to: CGPoint(x: (style.margin + style.lineHeight / 2).cgf, y: scanMinY + (style.angleLength + style.lineHeight / 2).cgf))
            
            // 左下角垂直线
            context?.move(to: CGPoint(x: (style.margin + style.lineHeight / 2).cgf, y: scanMaxY - (style.angleLength + style.lineHeight / 2).cgf))
            context?.addLine(to: CGPoint(x: (style.margin + style.lineHeight / 2).cgf, y: scanMaxY - (style.lineHeight / 2).cgf))
            
            // 左下角水平线
            context?.move(to: CGPoint(x: (style.margin + style.lineHeight / 2 - style.angleHeight / 2).cgf, y: scanMaxY - (style.lineHeight / 2).cgf))
            context?.addLine(to: CGPoint(x: (style.margin + style.lineHeight / 2 + style.angleLength).cgf, y: scanMaxY - (style.lineHeight / 2).cgf))
            
            // 右下角水平线
            context?.move(to: CGPoint(x: (scanMaxX - style.angleLength - style.lineHeight / 2).cgf, y: scanMaxY - (style.lineHeight / 2).cgf))
            context?.addLine(to: CGPoint(x: (scanMaxX - style.lineHeight / 2).cgf, y: scanMaxY - (style.lineHeight / 2).cgf))
            
            // 右下角垂直线
            context?.move(to: CGPoint(x: (scanMaxX - style.lineHeight / 2).cgf, y: scanMaxY - (style.lineHeight / 2 - style.angleHeight / 2).cgf))
            context?.addLine(to: CGPoint(x: (scanMaxX - style.lineHeight / 2).cgf, y: scanMaxY - (style.lineHeight / 2 + style.angleLength).cgf))
            
            // 右上角垂直线
            context?.move(to: CGPoint(x: (scanMaxX - style.lineHeight / 2).cgf, y: scanMinY + (style.lineHeight / 2 + style.angleLength).cgf))
            context?.addLine(to: CGPoint(x: (scanMaxX - style.lineHeight / 2).cgf, y: scanMinY + (style.lineHeight / 2).cgf))
            
            // 右上角水平线
            context?.move(to: CGPoint(x: (scanMaxX - style.lineHeight / 2 + style.angleHeight / 2).cgf, y: scanMinY + (style.lineHeight / 2).cgf))
            context?.addLine(to: CGPoint(x: (scanMaxX - style.lineHeight / 2 - style.angleLength).cgf, y: scanMinY + (style.lineHeight / 2).cgf))
        }
        
        // 开始绘制角区域
        context?.strokePath()
        
        scanAreaBlock?(rectOfInterest)
        
        // 若无扫描动画,则直接返回,不添加动画视图
        guard style.anmiationStyle != .None else { return }
        // 若无资源图片,则直接返回,不添加动画视图
        guard style.animationImage != nil else { return }
        
        self.addSubview(animationView)
        let animationSize = style.animationImage?.size
        animationView.image = style.animationImage
        animationView.frame = CGRect(x: style.margin + 5, y: Int(scanMinY), width: autoWidth - 10, height: animationSize!.height.i)
        
        switch style.anmiationStyle {
        case .None: return
        case .LineMove: startScanAnimation()
        case .LineCenter: moveCenter()
        }
    }
    
    /// 开始扫描动画(从上至下移动)
    private func startScanAnimation() {
        let autoWidth = frame.width.i - style.margin * 2
        UIView.animate(withDuration: 3) {
            self.animationView.transform = CGAffineTransform(translationX: 0, y: (autoWidth - self.animationView.frame.height.i * 2).cgf)
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.animationView.transform = .identity
            self.startScanAnimation()
        }
    }
    
    /// 结束扫描动画
    private func stopScanAnimation() {
        animationView.removeFromSuperview()
    }
    
    /// 将扫描图片移动至居中展示
    private func moveCenter() {
        let autoWidth = frame.width.i - style.margin * 2
        self.animationView.transform = CGAffineTransform(translationX: 0, y: (autoWidth / 2).cgf)
    }
}
