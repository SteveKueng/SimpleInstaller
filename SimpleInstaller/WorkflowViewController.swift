//
//  WorkflowViewController.swift
//  SimpleInstaller
//
//  Created by Steve Küng on 11.10.17.
//  Copyright © 2017 Steve Küng. All rights reserved.
//

import Cocoa

class WorkflowViewController: NSViewController {
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var workflowPouUp: NSPopUpButton!
    @IBOutlet weak var targetPopUp: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        if let workflows = appDelegate.workflows {
            for workflow in workflows {
                workflowPouUp.addItem(withTitle: workflow["name"] as! String)
            }
        }
        targetPopUp.addItems(withTitles: appDelegate.disks!)
    }
    
    @IBAction func runWorkflow(_ sender: Any) {
        let mainPC = appDelegate.mainPageController
        
        appDelegate.workflow = workflowPouUp.titleOfSelectedItem
        appDelegate.target = targetPopUp.titleOfSelectedItem
        mainPC!.navigateForward(mainPC)
        Utilities().runWorkflow()
    }
}
