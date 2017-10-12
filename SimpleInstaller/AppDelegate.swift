//
//  AppDelegate.swift
//  SimpleInstaller
//
//  Created by Steve Küng on 21.09.17.
//  Copyright © 2017 Steve Küng. All rights reserved.
//

import Cocoa
import IOKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var backgroundController: BackgroundWindowController!
    var mainPageController: MainPageController!
    var mainWindowController: MainWindowController!
    var mainViewController: MainViewController!
    
    var workflow: String?
    var target: String?
    var workflows: Array<Dictionary<String, Any>>? = nil
    var disks: Array<String>? = nil
    var processID: Int32 = 0
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
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

