//
//  HandyScannerViewController.swift
//  HandyScanner
//
//  Created by well on 2021/10/3.
//

class HandyScannerViewController: UIViewController {
    /// 让控制器持有scanHelper对象,不然会被提前释放
    let scanHelper = HandyScannerHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        defaultBackgroundColor()
        var config = HandyScannerConfig()
        config.animationImage = UIImage(named: "scan_animation")
        scanHelper.start(supView: view, scanConfig: config) { [weak self] (res) in
            guard let self = self else { return }
            print(res)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    deinit {
        print("HandyScannerViewController deinit~")
    }
}
