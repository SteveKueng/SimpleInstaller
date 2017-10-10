//
//  Utilities.swift
//  SimpleInstaller
//
//  Created by Steve Küng on 25.09.17.
//  Copyright © 2017 Steve Küng. All rights reserved.
//

import Foundation
import Cocoa

var workflows: Array<Dictionary<String, Any>>? = nil

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
    
    func findWorkflow(Name: String) -> Dictionary<String,Any>? {
        if workflows != nil {
            for workflow in workflows! {
                if workflow["name"] as? String == Name {
                    return workflow
                }
            }
        }
        return nil
    }
    
    func run(command: String, arguments: Array<String>) -> Dictionary<String,Any>? {
        let process = Process()
        process.launchPath = command
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        
        let output_from_command = try? PropertyListSerialization.propertyList(from: pipe.fileHandleForReading.readDataToEndOfFile(), options: [], format: nil) as! Dictionary<String,Any>
        return output_from_command
    }
    
    func mount(dmg: String) -> String? {
        if let output_from_command = run(command: "/usr/bin/hdiutil", arguments: ["attach", "-plist", dmg]) {
            let systemEntities = output_from_command["system-entities"] as! Array<Dictionary<String,Any>>
            for entities in systemEntities {
                if let mountPoint = entities["mount-point"] {
                    return String(describing: mountPoint)
                }
            }
        }
        return nil
    }
    
    func diskutil(verb: String, arguments: Array<String>) -> Bool {
        let process = Process()
        process.launchPath = "/usr/sbin/diskutil"
        process.arguments = [verb] + arguments
        process.launch()
        process.waitUntilExit()
        return process.terminationStatus == 0
        
    }
    
    func eraseDisk(disk: String, name: String, format: String) -> String? {
        sleep(3)
        
        _ = self.diskutil(verb: "unmountDisk", arguments: [disk])
        if self.diskutil(verb: "eraseDisk", arguments: [format, name, disk]) {
            return "/Volumes/"+name
        }
        return nil
    }
    
    func startInstallation(installer: String, progressBar: NSProgressIndicator, label: NSTextField, percentLabel: NSTextField, target: String) {
        let command = Bundle.main.resourcePath! + "/ptyexec"
        let task = Process()
        task.launchPath = command
        
        #if DEBUG
            task.arguments = ["/bin/sh", Bundle.main.resourcePath! + "/testInstall.sh"]
        #else
            task.arguments = [installer + "/Contents/Resources/startosinstall", "--applicationpath", installer, "--agreetolicense", "--rebootdelay", "300", "--pidtosignal", String(getpid()), "--volume", target]
        #endif
        
        let pipe = Pipe()
        task.standardOutput = pipe
        let outHandle = pipe.fileHandleForReading
        outHandle.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                if line != "" {
                    let matches = self.matches(for: "\\d+.\\d+", in: line)
                    if matches.count > 0 {
                        for match in matches {
                            if let number = Double(match) {
                                DispatchQueue.main.async {
                                    progressBar.doubleValue = number
                                    percentLabel.stringValue = String(format: "%.0f", number) + "%"
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            label.stringValue = line
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
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    // load config
    func loadConfig() -> Bool {
        var answer = false
        let url = Preferences().get_config_settings(preference_key: "serverurl")
        let additional_headers = Preferences().get_config_settings(preference_key: "additional_headers")
        let (plist, errorMessage, errorDetail) = Preferences().loadPlist(url: url as! String, additionalHeaders: additional_headers as! Dictionary<String, String>)
        if plist != nil {
            workflows = plist!["workflows"] as? Array<Dictionary<String, Any>>
            answer = true
        } else {
            let group = DispatchGroup()
            group.enter()
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
    
    func setStartupDiskAtPath(path: String) -> Bool {
        let task = Process()
        task.launchPath = "/usr/sbin/bless"
        task.arguments = [ "--mount", path, "--setBoot" ]
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus == 0
    }
    
    func finishInstallation() {
        self.trap() { signal in
            _ = Utilities().terminateStartosinstall()
            sleep(3)
            //Utilities().reboot()
            //NSApp.terminate(nil)
        }
        print("wait for SIGUSR1...")
        sigsuspend(nil)
    }
    
    func trap(action: @convention(c) (Int32) -> ()) {
        // From Swift, sigaction.init() collides with the Darwin.sigaction() function.
        // This local typealias allows us to disambiguate them.
        typealias SignalAction = sigaction
        
        var signalAction = SignalAction(__sigaction_u: unsafeBitCast(action, to: __sigaction_u.self), sa_mask: 0, sa_flags: 0)
        
        withUnsafePointer(to: &signalAction) { actionPointer in
            sigaction(30, actionPointer, nil)
        }
    }
    
    func terminateStartosinstall() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/killall"
        task.arguments = [ "-SIGUSR1", "startosinstall" ]
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus == 0
    }
}
