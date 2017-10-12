//
//  MainPageController.swift
//  SimpleInstaller
//
//  Created by Steve Küng on 21.09.17.
//  Copyright © 2017 Steve Küng. All rights reserved.
//

import Cocoa

class MainPageController: NSPageController, NSPageControllerDelegate {
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    
    var myViewArray = ["loading", "workflow", "main"]
    
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var backButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate.mainPageController = self
        delegate = self
        self.arrangedObjects = myViewArray
        self.transitionStyle = .horizontalStrip
        
        DispatchQueue.global(qos: .userInitiated).async {
            Utilities().loadConfig()
        }
    }
    
    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController {
        switch identifier._rawValue{
        case "loading":
            return NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle:nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "LoadingViewController")) as! NSViewController
        case "workflow":
            return NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle:nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "WorkflowViewController")) as! NSViewController
        case "main":
            return NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle:nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "MainViewController")) as! NSViewController
        default:
            return self.storyboard?.instantiateController(withIdentifier: identifier._rawValue as NSStoryboard.SceneIdentifier) as! NSViewController
        }
    }
    
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        return NSPageController.ObjectIdentifier(rawValue: String(describing: object))
    }
    
    func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
        self.completeTransition()
    }
    
    override func scrollWheel(with event: NSEvent) {
        //override trackpad swipe
    }
}

