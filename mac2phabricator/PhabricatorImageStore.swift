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
import Foundation
import Crashlytics
import AFNetworking

extension NSImage {
    func resizeImage(width: CGFloat, height: CGFloat) -> NSImage {
        let img = NSImage(size: NSSize(width: width, height: height))
        
        img.lockFocus()
        let ctx = NSGraphicsContext.current()
        ctx?.imageInterpolation = .high
        self.draw(in: NSMakeRect(0, 0, width, height), from: NSMakeRect(0, 0, size.width, size.height), operation: NSCompositingOperation.copy, fraction: 1)
        img.unlockFocus()
        
        return img
    }
}

class PhabricatorImageStore {
    
    static let shared = PhabricatorImageStore()
    
    let imagesKey = "Images"
    let settingsKey = "Settings"
    
    /// Returns an array of all the images store in UserDefaults.
    var images: [PhabricatorImage] {
        get {
            guard let data = UserDefaults.standard.object(forKey: imagesKey) as? Data else {
                return []
            }
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? [PhabricatorImage] ?? []
        }
        set {
            UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: newValue),
                                      forKey: imagesKey)
        }
    }
    
    var settings: PhabricatorSettings {
        get {
            guard let data = UserDefaults.standard.object(forKey: settingsKey) as? Data else {
                return PhabricatorSettings()
            }
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? PhabricatorSettings ?? PhabricatorSettings()
        }
        set {
            UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: newValue),
                                      forKey: settingsKey)
        }
    }
    
    /// Stores the specified image.
    /// - parameter image: The image to store
    func addImage(_ image: PhabricatorImage) {
        images.insert(image, at: 0)
    }
    
    /// Removes all stored images.
    func clearAll() {
        UserDefaults.standard.removeObject(forKey: imagesKey)
        UserDefaults.standard.removeObject(forKey: settingsKey)
    }
    
    func addObserver(_ observer: NSObject) {
        UserDefaults.standard.addObserver(observer,
                                          forKeyPath: imagesKey,
                                          options: [],
                                          context: nil)
    }
    
    // MARK: Preview Images
    
    var cachedImages = [URL: NSImage]()
    
    /// Attempts to retrieve a preview image of the specified image.
    /// - parameter image: The image for which to request a preview image.
    /// - parameter completionHandler: The completion handler to call if the
    /// image has been retrieved successfully.
    // TODO: completionHandler should take in a NSImage?
    func requestPreviewImage(forImage image: PhabricatorImage, completionHandler: @escaping (NSImage) -> Void) {

        let manager = AFHTTPSessionManager()
        manager.responseSerializer = AFJSONResponseSerializer()
        let apiKey  = PhabricatorImageStore.shared.settings.apiKey
        let params = [
            "api.token": apiKey,
            "phid": image.phId,
            "output": "json"
        ]
        manager.get(
            "https://phabricator.pinadmin.com/api/file.download",
            parameters: params,
            success: {
                (task: URLSessionDataTask, responseObject: Any?) in
//                print("success")
//                print(responseObject!)
                
                DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                    let resultObj = (responseObject as! NSDictionary)["result"]! as! String
                    let imageData = NSData(base64Encoded: resultObj, options: [])
                    guard let data = imageData as Data? else {
                        // TOOD: Implement error handling
                        print("error")
                        return
                    }
                    
                    let image = NSImage(data: data)?.resizeImage(width: 40, height: 40)
                    DispatchQueue.main.async(execute: {
                        completionHandler(image!)
                    })
                }
        }, failure: {
            (task: URLSessionDataTask?, error: Error) in
            // TOOD: Implement error handling
            print("error")
        })
    }

    
}
