//
//  disk.swift
//  SimpleInstaller
//
//  Created by Steve Küng on 11.10.17.
//  Copyright © 2017 Steve Küng. All rights reserved.
//

import Foundation

class disk {
    func diskutilList(arguments: Array<String>) -> Dictionary<String,Any>? {
        let process = Process()
        process.launchPath = "/usr/sbin/diskutil"
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        
        let output_from_command = try? PropertyListSerialization.propertyList(from: pipe.fileHandleForReading.readDataToEndOfFile(), options: [], format: nil) as! Dictionary<String,Any>
        return output_from_command
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
        print("test2")
        _ = self.diskutil(verb: "unmountDisk", arguments: [disk])
        if self.diskutil(verb: "eraseDisk", arguments: [format, name, disk]) {
            return "/Volumes/"+name
        }
        return nil
    }
    
    func getDisks() -> Array<String> {
        var disks = Array<String>()
        if let diskList = self.diskutilList(arguments: ["list", "-plist"]) {
            for disk in diskList["WholeDisks"] as! Array<Any> {
                if let diskInfo = self.diskutilList(arguments: ["info", "-plist", disk as! String]) {
                    if diskInfo["VirtualOrPhysical"] as! String != "Virtual" {
                        disks.append("/dev/" + (disk as! String))
                    }
                }
            }
        }
        return disks
    }
    
    func setStartupDiskAtPath(path: String) -> Bool {
        let task = Process()
        task.launchPath = "/usr/sbin/bless"
        task.arguments = [ "--mount", path, "--setBoot" ]
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus == 0
    }
}
