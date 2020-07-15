//
//  ViewController.swift
//  authKTGG
//
//  Created by Алексей Трушковский on 17.02.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit
import AVFoundation

class MainViewController: UIViewController {
    @IBAction func turnOnTorch(_ sender: UIButton) {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            let torchOn = !device.isTorchActive
            try device.setTorchModeOn(level: 1.0)
            device.torchMode = torchOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Error toggling Flashlight: \(error)")
        }
    }
    private func showTorchNotSupported() {
        let alertController = UIAlertController(title: "Flashlight is not supported", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Understand", style: .default, handler: nil))
        present(alertController, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            let appearance = self.tabBarController?.tabBar.standardAppearance
            appearance!.shadowImage = nil
            appearance!.shadowColor = nil
            appearance!.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.00)
            self.tabBarController?.tabBar.standardAppearance = appearance!
        } else {
            self.tabBarController?.tabBar.backgroundImage = UIImage()
            self.tabBarController?.tabBar.shadowImage = UIImage()
            
        }
        self.tabBarController?.tabBar.unselectedItemTintColor = UIColor(red: 0.62, green: 0.62, blue: 0.69, alpha: 1.00)
    }
  
}
