//
//  ViewController.swift
//  SimpleInstaller
//
//  Created by Steve Küng on 21.09.17.
//  Copyright © 2017 Steve Küng. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var progressCirc: NSProgressIndicator!
    @IBOutlet weak var processLabel: NSTextField!
    @IBOutlet weak var percentLabel: NSTextField!
    
    var workflow: String = "Install macOS"
    var volume: String = "/Volume/Macintosh HD"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.progressCirc.startAnimation(self)
        DispatchQueue.global(qos: .userInitiated).async {
            if let workflow = Utilities().findWorkflow(Name: self.workflow) {
                for component in workflow["components"] as! Array<Dictionary<String,Any>> {
                    switch component["type"] as! String {
                        case "eraseVolume"  :
                            print("eraseVolume")
                            if let volume = Utilities().eraseDisk(disk: "/dev/disk0", name: "Macintosh HD", format: "APFS") {
                                self.volume = volume
                            }
                            print(self.volume)
                        case "installer"  :
                            if let mountpoint = Utilities().mount(dmg: component["url"] as! String) {
                                let installerApp = mountpoint + "/Install macOS High Sierra.app"
                                DispatchQueue.main.async {
                                    self.processLabel.stringValue = ""
                                    self.progressCirc.stopAnimation(self)
                                    self.progressBar.doubleValue = 1.0
                                }
                                Utilities().startInstallation(installer: installerApp, progressBar: self.progressBar, label: self.processLabel, percentLabel: self.percentLabel, target: self.volume)
                                Utilities().finishInstallation()
                            }
                        default :
                            print("type unkown!")
                    }
                }
            } else {
                //workflow not found
                print("workflow not found!")
            }
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}
