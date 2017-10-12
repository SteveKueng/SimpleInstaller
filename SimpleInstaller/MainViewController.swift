//
//  ViewController.swift
//  SimpleInstaller
//
//  Created by Steve Küng on 21.09.17.
//  Copyright © 2017 Steve Küng. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    let utilities = Utilities()
    
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var progressCirc: NSProgressIndicator!
    @IBOutlet weak var processLabel: NSTextField!
    @IBOutlet weak var percentLabel: NSTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.progressCirc.startAnimation(self)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        appDelegate.mainViewController = self
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}
