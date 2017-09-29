//
//  MainPageController.swift
//  SimpleInstaller
//
//  Created by Steve Küng on 21.09.17.
//  Copyright © 2017 Steve Küng. All rights reserved.
//

import Cocoa

class MainPageController: NSPageController, NSPageControllerDelegate {

    var myViewArray = ["one", "two"]
    
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var backButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        self.arrangedObjects = myViewArray
        self.transitionStyle = .horizontalStrip
        NSApplication.shared.mainWindow?.isMovable = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            var next = false
            repeat {
                next = Utilities().loadConfig()
                
                
            } while(next == false)
            self.navigateForward(self)
        }
    }
    
    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController {
        switch identifier._rawValue{
        case "one":
            return NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle:nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "LoadingViewController")) as! NSViewController
        case "two":
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

