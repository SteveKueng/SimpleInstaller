//
//  BackgroundWindowController.swift
//  SplashBuddy
//
//  Created by ftiff on 24.11.16.
//  Copyright © 2016 François Levaux-Tiffreau. All rights reserved.
//

import Cocoa

class BackgroundWindowController: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        guard let backgroundWindow = self.window else {
            return
        }
        
        guard let mainDisplayRect = NSScreen.main?.frame else {
            return
        }
        
        backgroundWindow.contentRect(forFrameRect: mainDisplayRect)
        backgroundWindow.setFrame(mainDisplayRect, display: true)
        backgroundWindow.setFrameOrigin(mainDisplayRect.origin)
        backgroundWindow.level = NSWindow.Level.floating
        
    }
    
}
