//
//  AppDelegate.swift
//  SimpleInstaller
//
//  Created by Steve Küng on 21.09.17.
//  Copyright © 2017 Steve Küng. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var backgroundController: BackgroundWindowController!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        #if !DEBUG
            let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
            backgroundController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "backgroundWindow")) as! BackgroundWindowController
            backgroundController.showWindow(self)
        #endif
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

