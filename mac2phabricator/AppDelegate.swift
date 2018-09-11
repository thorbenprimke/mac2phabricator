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
import Fabric
import Crashlytics
import LetsMove

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let statusItemController = StatusItemController()
    var screenshotMonitor: ScreenshotMonitor?
    
    var hasFinishedLaunching = false
    var queuedFileURLs = [URL]()
    let imageClient: ImageClient
    
    // MARK: NSApplicationDelegate
    
    override init() {
        imageClient = PhabricatorClient.shared
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // Register initial defaults
        var initialDefaults = ["NSApplicationCrashOnExceptions": true]
        
        Preference.allValues.forEach {
            initialDefaults[$0.rawValue] = $0.defaultValue
        }
        
        UserDefaults.standard.register(defaults: initialDefaults)
        
        // Crashlytics integration
        Fabric.with([Crashlytics.self])
        Crashlytics.sharedInstance().setUserName(NSUserName())
        
        // Monitor for new screenshots
        screenshotMonitor = ScreenshotMonitor(eventHandler: screenshotEventHandler)
        screenshotMonitor?.startMonitoring()
        
        // Assign NSUserNotificationCenter delegate
        NSUserNotificationCenter.default.delegate = UserNotificationController.shared
        
        // Handle the notification supplied if the application has been launched from the notification center
        if let userNotification = notification.userInfo?[NSApplicationLaunchUserNotificationKey] as? NSUserNotification {
            UserNotificationController.shared.userNotificationCenter(.default, didActivate: userNotification)
        }
        
        // Register Apple Event handler
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleAppleEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL))
        
        PFMoveToApplicationsFolderIfNecessary()
        
        hasFinishedLaunching = true
        
        queuedFileURLs.forEach {
            imageClient.uploadImage(withURL: $0, isScreenshot: false)
        }
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let fileURL = URL(fileURLWithPath: filename)
        
        if hasFinishedLaunching {
            imageClient.uploadImage(withURL: fileURL, isScreenshot: false)
        } else {
            queuedFileURLs.append(fileURL)
        }
        
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        screenshotMonitor?.stopMonitoring()
    }
    
    // MARK: ScreenshotMonitor Event Handler
    
    func screenshotEventHandler(url: URL) {
        imageClient.uploadImage(withURL: url, isScreenshot: true)
    }
    
    // MARK: NSAppleEventManager Event Handler
    
    func handleAppleEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        // Attempt to parse response URL
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
            let url = URL(string: urlString) else {
                NSLog("Unable to determine URL from AppleEvent")
                return
        }
    }

}

protocol ImageClient {
    func uploadImage(withURL imageURL: URL, isScreenshot: Bool)
}

