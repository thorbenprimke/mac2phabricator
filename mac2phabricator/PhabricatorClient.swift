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

import Foundation
import Cocoa
import Crashlytics
import AFNetworking

class PhabricatorClient: NSObject, ImageClient {
    
    static let shared = PhabricatorClient()
    
    var externalWebViewCompletionHandler: (() -> Void)?
    
    // MARK: Defaults keys
    
    let refreshTokenKey = "RefreshToken"
    let imgurAlbumKey = "ImgurAlbum"
    
    
    // MARK: General
    
    var uploadAlbumID: String? {
        get {
            return UserDefaults.standard.string(forKey: imgurAlbumKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: imgurAlbumKey)
        }
    }
    
    func handle(error: Error?, title: String) {
        
        UserNotificationController.shared.displayNotification(
            withTitle: title,
            informativeText: description(of: error))
        
        if let error = error {
            NSLog("%@: %@", title, error as NSError)
            Crashlytics.sharedInstance().recordError(error)
        }
    }
    
    func description(of error: Error?) -> String {

        if let error = error as NSError? {
            
            let localizedDescription = error.userInfo[NSLocalizedDescriptionKey]
            
            if localizedDescription is String {
                
                return error.localizedDescription
                
            } else if let data = localizedDescription as? [String: Any],
                let message = data["message"] as? String {
                
                return message

            }
            
        }
        
        return "An unknown error occurred."
    }
    
    /// Requests manual upload confirmation from the user if required,
    /// otherwise returns `true`
    /// - parameter upload: The upload for which confirmation is required
    func hasUploadConfirmation(forImageNamed imageName: String, imageData: Data) -> Bool {
        // Manual upload confirmation may not be required
        if !Preference.requiresUploadConfirmation.value {
            return true
        }
        
        let alert = NSAlert()
        alert.messageText = "Do you want to upload this screenshot?"
        alert.informativeText = "\"\(imageName)\" will be uploaded to phabricator, where it will be publicly accessible."
        alert.addButton(withTitle: "Upload")
        alert.addButton(withTitle: "Cancel")
        alert.icon = NSImage(data: imageData)
        
        NSApp.activate(ignoringOtherApps: true)
        return alert.runModal() == NSAlertFirstButtonReturn
    }
    
    /// Returns a PNG image representation data of the supplied image data,
    /// reduced to non-retina scale
    func downscaleRetinaImageData(_ data: Data) -> Data? {
        guard let image = NSImage(data: data) else {
            NSLog("Resize failed: Unable to create image from image data")
            return nil
        }
        
        guard let imageRep = image.representations.first else {
            NSLog("Resize failed: Unable to get image representation")
            return nil
        }
        
        if image.size.width >= CGFloat(imageRep.pixelsWide) {
            NSLog("Resize skipped: Image is not retina")
            return nil
        }
        
        guard let bitmapImageRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(image.size.width),
            pixelsHigh: Int(image.size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: NSCalibratedRGBColorSpace,
            bytesPerRow: 0,
            bitsPerPixel: 0) else {
                NSLog("Resize failed: Unable to create bitmap image representation")
                return nil
        }
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.setCurrent(NSGraphicsContext(bitmapImageRep: bitmapImageRep))
        image.draw(in: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        NSGraphicsContext.restoreGraphicsState()
        
        // Use a PNG representation of the resized image
        guard let resizedRep = bitmapImageRep.representation(using: .PNG, properties: [:]) else {
            NSLog("Resize failed: Unable to create PNG representation")
            return nil
        }
        
        return resizedRep
    }
    
    // MARK: Imgur Upload
    
    /// Uploads the image at the specified URL.
    /// - parameter imageURL: The URL to the image to be uploaded
    /// - parameter isScreenshot: Whether the image is a screenshot or not,
    /// affects which preferences will be applied to the upload
    func uploadImage(withURL imageURL: URL, isScreenshot: Bool) {
        
        var imageData: Data
        
        do {
            imageData = try Data(contentsOf: imageURL)
        } catch let error {
            uploadFailureHandler(dataTask: nil, error: error)
            return
        }
        
        let imageName = imageURL.lastPathComponent
        
        // Screenshot specific preferences
        if isScreenshot {
            
            if Preference.disableScreenshotDetection.value
                || !hasUploadConfirmation(forImageNamed: imageName, imageData: imageData) {
                return // Skip, do not upload
            }
            
            // Downscale retina image if required
            if Preference.resizeScreenshots.value,
                let resizedImageData = downscaleRetinaImageData(imageData) {
                imageData = resizedImageData
            }
            
            // Move the image to trash if required
            if Preference.deleteScreenshotsAfterUpload.value {
                NSWorkspace.shared().recycle([imageURL], completionHandler: nil)
            }
            
        }
        
        uploadImage(withData: imageData,
                    imageTitle: NSString(string: imageName).deletingPathExtension,
                    imageName: imageName)
    }
    
    class PhResult: Any {
        var result:String?
    
    }
    
    /// Uploads the specified image data
    /// - parameter imageData: The image data of which to upload
    /// - parameter imageTitle: The title of the image (defaults to "Untitled")
    func uploadImage(withData imageData: Data, imageTitle: String = "Untitled", imageName: String = "Filename.png") {
        
        // Clear clipboard if required
        if Preference.clearClipboard.value {
            NSPasteboard.general().clearContents()
        }
        
        let apiKey  = PhabricatorImageStore.shared.settings.apiKey
        let phabEndpoint = PhabricatorImageStore.shared.settings.phabEndpoint
        
        if (apiKey == "" || phabEndpoint == "") {
            UserNotificationController.shared.displayNotification(
                withTitle: "Phabricator Upload Failure",
                informativeText: "Please go to settings and set your phabricator endpoint and API key!")
            return
        }
        
        let base64Data = imageData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)
        let params = [
            "api.token": apiKey,
            "name": imageName,
            "data_base64": base64Data,
            "output": "json"
        ]
        
        let manager = AFHTTPSessionManager()
        manager.responseSerializer = AFJSONResponseSerializer()
        manager.post(
            phabEndpoint + "/api/file.upload",
            parameters: params,
            success: {
                (task: URLSessionDataTask, responseObject: Any?) in
                print("success")
                print(responseObject!)
                print("Result: ", (responseObject as! NSDictionary)["result"]!)
                let phId = (responseObject as! NSDictionary)["result"]! as! String
                self.getPhabFileInfo(phId: phId)
        }, failure: {
            (task: URLSessionDataTask?, error: Error) in
            print("error")
        })
    }
    
    func getPhabFileInfo(phId: String) {
        let manager = AFHTTPSessionManager()
        manager.responseSerializer = AFJSONResponseSerializer()
        let apiKey  = PhabricatorImageStore.shared.settings.apiKey
        let params = [
            "api.token": apiKey,
            "phid": phId,
            "output": "json"
        ]
        manager.post(
            PhabricatorImageStore.shared.settings.phabEndpoint + "/api/file.info",
            parameters: params,
            success: {
                (task: URLSessionDataTask, responseObject: Any?) in
                print("success")
                print(responseObject!)
                
                let resultObj = (responseObject as! NSDictionary)["result"]! as! NSDictionary
                
                let phabricatorImage = PhabricatorImage.init(
                    phId: phId,
                    name: resultObj["name"] as! String,
                    objectName: resultObj["objectName"] as! String)
                PhabricatorImageStore.shared.addImage(phabricatorImage)
                
                let copyToClipboardLink = "{" + phabricatorImage.objectName + "}"
                // put data into clipboard
                // Copy link to clipboard if required
                if Preference.copyLinkToClipboard.value, !copyToClipboardLink.isEmpty {
                    NSPasteboard.general().clearContents()
                    NSPasteboard.general()
                        .setString(copyToClipboardLink, forType: NSPasteboardTypeString)
                }
                
                UserNotificationController.shared.displayNotification(
                    withTitle: "Phabricator Upload Succeeded",
                    informativeText: phabricatorImage.objectName)
                
        }, failure: {
            (task: URLSessionDataTask?, error: Error) in
            print("error")
        })
    }
    
    func uploadFailureHandler(dataTask: URLSessionDataTask?, error: Error?) {
        handle(error: error, title: "Imgur Upload Failed")
    }
}
