//
//  ViewController.swift
//  IPAEdit
//
//  Created by Ethan Goodhart on 7/7/21.
//

import Cocoa
import ZIPFoundation

class ViewController: NSViewController {
    @IBOutlet weak var ipaName: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    
    var appPath = URL(fileURLWithPath: "")
    var currentlyExtracting = false
    var ipaCopy = ""
    var ipaFileName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate), name: NSApplication.willTerminateNotification, object: nil)
    }
    
    @objc func applicationWillTerminate(notification: Notification) {
        if currentlyExtracting {
            if FileManager.default.fileExists(atPath: ipaCopy + ".zip") {
                do { try FileManager.default.removeItem(atPath: ipaCopy + ".zip") } catch { print(error) }
            }

            if FileManager.default.fileExists(atPath: ipaCopy) {
                do { try FileManager.default.removeItem(atPath: ipaCopy) } catch { print(error) }
            }
        }
    }
    
    func openEditController() {
        DispatchQueue.main.async {
            do {
                let payloadContents = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: self.ipaCopy + "/Payload"), includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles])
                self.appPath = payloadContents.first!
                self.performSegue(withIdentifier: "editsegue", sender: self)
            } catch {
                print("Error extracting payload from IPA \(error)")
            }
        }
    }
    
    func extractPayloadFromIPA(path: URL) {
        ipaCopy = path.path.components(separatedBy: ".ipa")[0] + "_IPAEdit"
        
        if FileManager.default.fileExists(atPath: ipaCopy) && !FileManager.default.fileExists(atPath: ipaCopy + ".zip") {
            openEditController()
        } else {
            let p = Progress()
            
            if FileManager.default.fileExists(atPath: ipaCopy) {
                do {
                    try FileManager.default.removeItem(atPath: ipaCopy)
                } catch {
                    print("Error deleting ipa folder")
                }
            }
            
            DispatchQueue.global(qos: .userInteractive).async {
                do {
                    self.currentlyExtracting = true
                    
                    if !FileManager.default.fileExists(atPath: self.ipaCopy + ".zip") {
                        try FileManager.default.copyItem(atPath: path.path, toPath: self.ipaCopy + ".zip")
                    }
                    
                    try FileManager.default.unzipItem(at: URL(fileURLWithPath: self.ipaCopy + ".zip"), to: URL(fileURLWithPath: self.ipaCopy), progress: p)
                    try FileManager.default.removeItem(atPath: self.ipaCopy + ".zip")
                    self.currentlyExtracting = false
                    self.openEditController()
                } catch {
                    print("Error extracting payload from IPA \(error)")
                }
            }
            
            DispatchQueue.global(qos: .background).async {
                while (p.fractionCompleted < 1.0) {
                    DispatchQueue.main.async {
                        if (self.progressBar.isHidden) {
                            self.progressBar.isHidden = false
                        }
                        
                        if (self.ipaName.isHidden) {
                            self.ipaName.isHidden = false
                        }
                        
                        self.progressBar.doubleValue = p.fractionCompleted * 100
                    }
                }
                
                DispatchQueue.main.async {
                    self.progressBar.isHidden = true
                }
            }
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "editsegue" {
            self.view.window?.close()
            ((segue.destinationController as! NSWindowController).contentViewController as! EditController).appPath = self.appPath
            ((segue.destinationController as! NSWindowController).contentViewController as! EditController).ipaFileName = self.ipaFileName
        }
    }
    
    @IBAction func chooseIPAPressed(_ sender: Any) {
        let dialog = NSOpenPanel()
        dialog.title = "Select an .ipa file"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = false
        dialog.allowedFileTypes = ["ipa"]

        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url

            if (result != nil) {
                ipaName.stringValue = result!.lastPathComponent
                ipaFileName = result!.lastPathComponent.components(separatedBy: ".ipa")[0]
                extractPayloadFromIPA(path: result!)
            }
        } else {
            return
        }
    }
    
}
