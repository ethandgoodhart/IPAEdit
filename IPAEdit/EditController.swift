//
//  EditController.swift
//  IPAEdit
//
//  Created by Ethan Goodhart on 7/8/21.
//

import Cocoa
import ZIPFoundation

class EditController: NSViewController, NSTextFieldDelegate {
    @IBOutlet weak var displayName: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var version: NSTextField!
    @IBOutlet weak var iconImg: NSImageView!
    @IBOutlet weak var categoryPicker: NSPopUpButton!
    
    var appPath = URL(fileURLWithPath: "")
    var plistPath = ""
    var ipaPlist = NSMutableDictionary()
    var iconImages: [URL] = []
    var ipaFileName = ""
    var lastVersion = ""
    
    let app_categories = ["public.app-category.business", "public.app-category.developer-tools", "public.app-category.education", "public.app-category.entertainment", "public.app-category.finance", "public.app-category.games", "public.app-category.action-games", "public.app-category.adventure-games", "public.app-category.arcade-games", "public.app-category.board-games", "public.app-category.card-games", "public.app-category.casino-games", "public.app-category.dice-games", "public.app-category.educational-games", "public.app-category.family-games", "public.app-category.kids-games", "public.app-category.music-games", "public.app-category.puzzle-games", "public.app-category.racing-games", "public.app-category.role-playing-games", "public.app-category.simulation-games", "public.app-category.sports-games", "public.app-category.strategy-games", "public.app-category.trivia-games", "public.app-category.word-games", "public.app-category.graphics-design", "public.app-category.healthcare-fitness", "public.app-category.lifestyle", "public.app-category.medical", "public.app-category.music", "public.app-category.news", "public.app-category.photography", "public.app-category.productivity", "public.app-category.reference", "public.app-category.social-networking", "public.app-category.sports", "public.app-category.travel", "public.app-category.utilities", "public.app-category.video", "public.app-category.weather"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        iconImg.wantsLayer = true
        iconImg.layer!.cornerRadius = 8.0
        
        displayName.delegate = self
        version.delegate = self
    }
    
    func alert(text: String) {
        let alert = NSAlert()
        alert.messageText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func controlTextDidChange(_ obj: Notification) {
        let textField = obj.object as! NSTextField
        
        if textField == displayName {
            ipaPlist["CFBundleDisplayName"] = textField.stringValue
            ipaPlist.write(toFile: plistPath, atomically: true)
        } else if textField == version {
            if textField.stringValue.components(separatedBy: ".").filter({$0 != ""}).count != 4 {
                alert(text: "App Version must have 4 valid digits!")
                textField.stringValue = lastVersion
            } else {
                lastVersion = textField.stringValue
                ipaPlist["CFBundleVersion"] = textField.stringValue
                var short = textField.stringValue.components(separatedBy: ".")
                short.removeLast()
                ipaPlist["CFBundleShortVersionString"] = short.joined(separator: ".")
                ipaPlist.write(toFile: plistPath, atomically: true)
            }
        }
    }
    
    @IBAction func categoryValueDidChange(_ sender: Any) {
        ipaPlist["LSApplicationCategoryType"] = categoryPicker.selectedItem?.title
        ipaPlist.write(toFile: plistPath, atomically: true)
    }
    
    override func viewWillAppear() {
        plistPath = appPath.appendingPathComponent("Info.plist").path
        ipaPlist = NSMutableDictionary(contentsOfFile: plistPath)!
        
        if ipaPlist["CFBundleDisplayName"] == nil {
            ipaPlist["CFBundleDisplayName"] = "DisplayName"
            ipaPlist.write(toFile: plistPath, atomically: true)
        }
        
        if ipaPlist["CFBundleVersion"] == nil {
            ipaPlist["CFBundleVersion"] = "1.0.0.0"
            ipaPlist.write(toFile: plistPath, atomically: true)
        }
        
        if ipaPlist["CFBundleShortVersionString"] == nil {
            ipaPlist["CFBundleShortVersionString"] = "1.0.0"
            ipaPlist.write(toFile: plistPath, atomically: true)
        }
        
        if ipaPlist["LSApplicationCategoryType"] == nil {
            ipaPlist["LSApplicationCategoryType"] = "public.app-category.developer-tools"
            ipaPlist.write(toFile: plistPath, atomically: true)
        }
        
        lastVersion = ipaPlist["CFBundleVersion"] as! String
        version.stringValue = ipaPlist["CFBundleVersion"] as! String
        displayName.stringValue = ipaPlist["CFBundleDisplayName"] as! String
        
        categoryPicker.removeAllItems()
        categoryPicker.addItems(withTitles: app_categories)
        categoryPicker.selectItem(at: categoryPicker.indexOfItem(withTitle: ipaPlist["LSApplicationCategoryType"] as! String))
        
        let primaryIconDict = ((ipaPlist["CFBundleIcons"] as! NSMutableDictionary)["CFBundlePrimaryIcon"] as! NSMutableDictionary)
        
        if primaryIconDict["CFBundleIconName"] != nil {
            primaryIconDict.removeObject(forKey: "CFBundleIconName")
            ipaPlist.write(toFile: plistPath, atomically: true)
        }
    
        let iconNames = (primaryIconDict["CFBundleIconFiles"] as! NSArray) as! [String]
        
        for i in iconNames {
            do {
                let versions = try FileManager.default.contentsOfDirectory(at: appPath, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]).filter { $0.lastPathComponent.hasPrefix(i) }
                for v in versions {
                    iconImages.append(v.absoluteURL)
                    
                    if v == versions.last {
                        iconImg.image = NSImage(contentsOf: v)
                    }
                }
            } catch {
                print(error)
            }
        }
    }

    @IBAction func changeBtnClicked(_ sender: Any) {
        let dialog = NSOpenPanel()
        dialog.title = "Select an image to use as the app icon"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = false
        dialog.allowedFileTypes = ["png"]

        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url

            if (result != nil) {
                let uploadedImg = NSImage(contentsOf: result!)!
                
                for ic in iconImages {
                    let icimg = NSImage(contentsOf: ic)!
                    
                    if uploadedImg.size != icimg.size {
                        uploadedImg.resized(to: icimg.size)?.save(to: ic, options: .atomic)
                    } else {
                        uploadedImg.save(to: ic, options: .atomic)
                    }
                }
                
                iconImg.image = NSImage(contentsOf: iconImages.last!)
            }
        } else {
            return
        }
    }
    
    @IBAction func generateNewIPA(_ sender: Any) {
        let p = Progress()
        
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                var exportedFileName = self.ipaFileName + " [IPAEdit]"
                var oc = ""
                
                while FileManager.default.fileExists(atPath: self.appPath.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(exportedFileName + oc + ".ipa").path) {
                    
                    if oc == "" {
                        oc = " 1"
                    } else {
                        oc = " \(Int(oc.components(separatedBy: " ")[1])! + 1)"
                    }
                }
                
                exportedFileName = exportedFileName + oc
                
                if !FileManager.default.fileExists(atPath: self.appPath.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(exportedFileName + ".zip").path) {
                    try FileManager.default.zipItem(at: self.appPath.deletingLastPathComponent(), to: self.appPath.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(exportedFileName + ".zip"), progress: p)
                }
            
                try FileManager.default.moveItem(at: self.appPath.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(exportedFileName + ".zip"), to: self.appPath.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(exportedFileName + ".ipa"))
                NSWorkspace.shared.selectFile(self.appPath.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(exportedFileName + ".ipa").path, inFileViewerRootedAtPath: "")
            } catch {
                print(error)
            }
        }
        
        DispatchQueue.global(qos: .background).async {
            while (p.fractionCompleted < 1.0) {
                DispatchQueue.main.async {
                    if (self.progressBar.isHidden) {
                        self.progressBar.isHidden = false
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

extension NSImage {
    @objc var CGImage: CGImage? {
        get {
            guard let imageData = self.tiffRepresentation else { return nil }
            guard let sourceData = CGImageSourceCreateWithData(imageData as CFData, nil) else { return nil }
            return CGImageSourceCreateImageAtIndex(sourceData, 0, nil)
        }
    }
    
    var size: NSSize {
        get {
            return NSBitmapImageRep(cgImage: self.CGImage!).size
        }
    }
    
    func resized(to newSize: NSSize) -> NSImage? {
        if let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) {
            bitmapRep.size = newSize
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
            draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()

            let resizedImage = NSImage(size: newSize)
            resizedImage.addRepresentation(bitmapRep)
            return resizedImage
        }

        return nil
    }

    func save(to url: URL, options: Data.WritingOptions = .atomic) {
        do {
            try NSBitmapImageRep(data: tiffRepresentation!)!.representation(using: .png, properties: [:])!.write(to: url, options: options)
        } catch {
            print(error)
        }
    }
}
