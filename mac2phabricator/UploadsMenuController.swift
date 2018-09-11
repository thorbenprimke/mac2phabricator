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

class UploadsMenuController: MenuController {
    
    // MARK: MenuController
    
    override init() {
        super.init()
        
        PhabricatorImageStore.shared.addObserver(self)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        rebuildMenu()
    }
    
    override var menuTitle: String {
        return "Recent Uploads"
    }
    
    override func buildMenu() {
        super.buildMenu()
        
        for image in PhabricatorImageStore.shared.images {
            let menuItem = NSMenuItem()
            menuItem.representedObject = image
            menuItem.title = image.name
            menuItem.submenu = uploadItemMenu(forImage: image)
            
            PhabricatorImageStore.shared.requestPreviewImage(
                forImage: image,
                completionHandler: { (image) in
                    image.size = NSSize(width: 40, height: 40)
                    menuItem.image = image
            })
            
            menu.addItem(menuItem)
        }
        menu.addItem(.separator())
        
        if PhabricatorImageStore.shared.images.isEmpty {
            menu.addItem(withTitle: "No Recent Uploads")
        } else {
            menu.addItem(withTitle: "Clear Uploads",
                         action: #selector(clearUploads),
                         target: self)
        }
    }
    
    // MARK: General
    
    func uploadItemMenu(forImage image: PhabricatorImage) -> NSMenu {
        let menu = NSMenu()
        
        menu.addItem(withTitle: "Copy Image URL",
                     action: #selector(PhabricatorImage.copyURL),
                     target: image)
        
        menu.addItem(.separator())
        return menu
    }

    func clearUploads() {
        PhabricatorImageStore.shared.clearAll()
    }
}
