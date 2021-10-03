//
//  ViewController.swift
//  HandyScanner
//
//  Created by well on 2021/10/3.
//

extension UIViewController {
    func defaultBackgroundColor() { view.backgroundColor = .white }
}

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        defaultBackgroundColor()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        navigationController?.pushViewController(HandyScannerViewController(), animated: true)
    }
}

