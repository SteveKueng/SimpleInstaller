//
//  Utilities.swift
//  SimpleInstaller
//
//  Created by Steve Küng on 25.09.17.
//  Copyright © 2017 Steve Küng. All rights reserved.
//

import Foundation
import Cocoa

var workflows: Array<Dictionary<String, Any>>?

class Utilities {
    
    func reboot() {
        let process = Process()
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", "shutdown -r now"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        
        _ = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: String.Encoding.utf8)!
    }
    
    //display error
    func errorDialog(error: String, detail: String?) -> NSAlert {
        let alert = NSAlert()
        alert.messageText = error
        alert.informativeText = detail ?? ""
        alert.alertStyle = .critical
        alert.addButton(withTitle: "reload")
        alert.addButton(withTitle: "restart")
        return alert
    }
    
    func runWorkflow(Name: String, progressBar: NSProgressIndicator) {
        if let workflow = findWorkflow(Name: Name) {
            if let installer = getInstaller(workflow: workflow) {
                startInstallation(installer: installer, progressBar: progressBar)
            } else {
                //installer not found
                print("installer not found!")
            }
        } else {
            //workflow not found
            print("workflow not found!")
        }
    }
    
    func findWorkflow(Name: String) -> Dictionary<String,Any>? {
        if workflows == nil {
            //no workflows found
        } else {
            for workflow in workflows! {
                if workflow["name"] as? String == Name {
                    return workflow
                }
            }
        }
        return nil
    }
    
    func getInstaller(workflow: Dictionary<String,Any>) -> String? {
        if let components = workflow["components"] as? Array<Dictionary<String,Any>>{
            for component in components {
                if ((component["type"] as? String) == "installer") {
                    return component["url"] as? String
                }
            }
        } else {
            //components not found
            print("components not found!")
        }
        return nil
    }
    
    func mound(dmg: String) -> String {
        //hdiutil attach -plist https://MEDIA\\svc-gd-mainrepo:a64T=8qhnfyv5YPknR@munki.srgssr.ch/pkgs/OS/Apple/HighSierra/Install\ macOS\ High\ Sierra-10.13.dmg
        let process = Process()
        process.launchPath = "/usr/bin/hdiutil"
        process.arguments = ["attach", "-plist", dmg]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        
        var output_from_command = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: String.Encoding.utf8)!
        
        // remove the trailing new-line char
        if output_from_command.characters.count > 0 {
            let lastIndex = output_from_command.index(before: output_from_command.endIndex)
            output_from_command = String(output_from_command[output_from_command.startIndex ..< lastIndex])
        }
        
        //get mountpoint from dictionary
        
        
        return output_from_command
    }
    
    func startInstallation(installer: String, progressBar: NSProgressIndicator) {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "echo \"Preparing 20.404040...\"; sleep 3; echo \"Preparing 23.545915...\"; sleep 2; echo \"Preparing 30.567894...\"; sleep 5; echo \"Preparing 90.404040...\"; sleep 3; echo \"Preparing 100.000000...\""]
        //task.arguments = [""]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        let outHandle = pipe.fileHandleForReading
        
        outHandle.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                if line != "" {
                    if let number = Double(self.matches(for: "\\d+.\\d+", in: line)[0]) {
                        DispatchQueue.main.async {
                           progressBar.doubleValue = number
                        }
                    }
                }
            } else {
                print("Error decoding data: \(pipe.availableData)")
            }
        }
        task.launch()
    }
    
    func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            return results.map {
                text.substring(with: Range($0.range, in: text)!)
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    // load config
    func loadConfig() -> Bool {
        var answer = false
        let group = DispatchGroup()
        group.enter()
        let url = Preferences().get_config_settings(preference_key: "serverurl")
        let (plist, errorMessage, errorDetail) = Preferences().loadPlist(url: url as! String)
        if plist != nil {
            workflows = plist!["workflows"] as? Array<Dictionary<String, Any>>
            answer = true
        } else {
            DispatchQueue.main.async {
                let alert = self.errorDialog(error: errorMessage!, detail: errorDetail)
                alert.beginSheetModal(for: NSApplication.shared.mainWindow!, completionHandler: { (modalResponse) -> Void in
                    if modalResponse != NSApplication.ModalResponse.alertFirstButtonReturn {
                        Utilities().reboot()
                    }
                })
                group.leave()
            }
            group.wait()
        }
        return answer
    }
}
