//
//  MainWindowController.swift
//  SimpleInstaller
//
//  Created by Steve Küng on 26.09.17.
//  Copyright © 2017 Steve Küng. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
        appDelegate.mainWindowController = self
        //self.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

}
