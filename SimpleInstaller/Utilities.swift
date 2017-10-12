//
//  Utilities.swift
//  SimpleInstaller
//
//  Created by Steve Küng on 25.09.17.
//  Copyright © 2017 Steve Küng. All rights reserved.
//

import Foundation
import Cocoa

class Utilities {
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    
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
    func errorDialog(error: String, detail: String?) {
        let alert = NSAlert()
        alert.messageText = error
        alert.informativeText = detail ?? ""
        alert.alertStyle = .critical
        alert.addButton(withTitle: "reload")
        alert.addButton(withTitle: "restart")
        
        DispatchQueue.main.async {
            alert.beginSheetModal(for: self.appDelegate.mainWindowController.window!, completionHandler: { (modalResponse) -> Void in
                if modalResponse != NSApplication.ModalResponse.alertFirstButtonReturn {
                    self.reboot()
                } else {
                    let mainPC = self.appDelegate.mainPageController
                    mainPC?.navigateForward(to: "loading")
                    self.loadConfig()
                }
            })
        }
    }
    
    func findWorkflow(Name: String) -> Dictionary<String,Any>? {
        if appDelegate.workflows != nil {
            for workflow in appDelegate.workflows! {
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
    
    func getInstallerApp(path: String) -> String? {
        let fileNames = try! FileManager.default.contentsOfDirectory(atPath: path)
        for fileName in fileNames {
            if fileName.hasSuffix("app") {
                print(fileName)
                return path + "/" + fileName
            }
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
        appDelegate.processID = task.processIdentifier
    }
    
    func runWorkflow() {
        let mainVC = appDelegate.mainViewController!
        var volume: String?
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let workflow = self.findWorkflow(Name: self.appDelegate.workflow!) {
                print(workflow)
                for component in workflow["components"] as! Array<Dictionary<String,Any>> {
                    print(component)
                    switch component["type"] as! String {
                    case "eraseDisk"  :
                        volume = disk().eraseDisk(disk: self.appDelegate.target!, name: "Macintosh HD", format: "APFS")
                    case "installer"  :
                        if let mountpoint = self.mount(dmg: component["url"] as! String) {
                            if let installerApp = self.getInstallerApp(path: mountpoint) {
                                DispatchQueue.main.async {
                                    mainVC.processLabel.stringValue = ""
                                    mainVC.progressCirc.stopAnimation(self)
                                    mainVC.progressBar.doubleValue = 1.0
                                }
                                self.startInstallation(installer: installerApp, progressBar: mainVC.progressBar, label: mainVC.processLabel, percentLabel: mainVC.percentLabel, target: volume!)
                                self.finishInstallation()
                            } else {
                                self.errorDialog(error: "could not find installer", detail: mountpoint)
                            }
                        } else {
                            self.errorDialog(error: "could not mount installer", detail: component["url"] as? String)
                        }
                    default :
                        print("type unkown!")
                    }
                }
            } else {
                //workflow not found
                self.errorDialog(error: "workflow not found!", detail: self.appDelegate.workflow!)
            }
        }
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
    func loadConfig() {
        let url = Preferences().get_config_settings(preference_key: "serverurl")
        let additional_headers = Preferences().get_config_settings(preference_key: "additional_headers")
        let (plist, errorMessage, errorDetail) = Preferences().loadPlist(url: url as! String, additionalHeaders: additional_headers as! Dictionary<String, String>)
        if plist != nil {
            appDelegate.workflows = plist!["workflows"] as? Array<Dictionary<String, Any>>
            appDelegate.disks = disk().getDisks()
            appDelegate.mainPageController.navigateForward(appDelegate.mainPageController)
        } else {
            errorDialog(error: errorMessage!, detail: errorDetail)
        }
    }    
    
    func finishInstallation() {
        self.trap() { signal in
            _ = Utilities().terminateStartosinstall()
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
        task.launchPath = "/bin/kill"
        task.arguments = [ "-SIGUSR1", String(appDelegate.processID)]
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus == 0
    }
}
