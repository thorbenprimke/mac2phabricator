/* This file is part of mac2imgur.
 *
 * mac2imgur is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 
 * mac2imgur is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 
 * You should have received a copy of the GNU General Public License
 * along with mac2imgur.  If not, see <http://www.gnu.org/licenses/>.
 */

import Cocoa
import Crashlytics

class StatusItemMenuController: MenuController {
    
    let preferencesMenuController = PreferencesMenuController()
    let uploadsMenuController = UploadsMenuController()
    let aboutMenuController = AboutMenuController()
    var windowController: NSWindowController?
    
    // MARK: MenuController
    
    override func buildMenu() {
        super.buildMenu()

        menu.addItem(withTitle: "Settings",
                     action: #selector(openSettings),
                     target: self)
        
        menu.addItem(withTitle: "Upload Images…",
                     action: #selector(selectImages),
                     target: self)
        
        menu.addItem(.separator())
        menu.addItem(withTitle: uploadsMenuController.menuTitle,
                     submenu: self.uploadsMenuController.menu)
        menu.addItem(.separator())
        menu.addItem(withTitle: preferencesMenuController.menuTitle,
                     submenu: self.preferencesMenuController.menu)
        menu.addItem(.separator())
        menu.addItem(withTitle: aboutMenuController.menuTitle,
                     submenu: self.aboutMenuController.menu)
        
        let appName = NSRunningApplication.current.localizedName ??
            ProcessInfo.processInfo.processName
        
        menu.addItem(withTitle: "Quit \(appName)",
                     action: #selector(NSApp.terminate(_:)),
                     target: nil)
        
    }
    
    /// Opens a file selection prompt for uploading images
    @objc func selectImages() {
        let panel = NSOpenPanel()
        panel.title = "Select Images"
        panel.prompt = "Upload"
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedFileTypes = [kUTTypeImage as String]
        
        panel.begin { (result) -> Void in
            if result == NSApplication.ModalResponse.OK {
                for url in panel.urls {
                    PhabricatorClient.shared.uploadImage(withURL: url,
                                                   isScreenshot: false)
                }
            }
        }
        
        // Show in front of all other applications
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func openSettings() {
        // var windowController : NSWindowController!
        guard let controller = windowController else {
            let mainStoryBoard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Settings"), bundle: nil)
            windowController = mainStoryBoard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "SettingsWindowController")) as? NSWindowController
            windowController?.window?.delegate = self
            windowController?.showWindow(self)
            return
        }
       
        // Activate the app and focus the settings window
        NSApp.activate(ignoringOtherApps: true)
        controller.window?.makeKeyAndOrderFront(self)
    }
}

extension StatusItemMenuController : NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        windowController = nil
    }
}
