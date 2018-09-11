//
//  PhabricatorImage.swift
//

import Foundation
import Cocoa

class PhabricatorImage: NSObject, NSCoding {

    func encode(with aCoder: NSCoder) {
        aCoder.encode(phId, forKey: "phId")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(objectName, forKey: "objectName")
    }
    
    required init?(coder aDecoder: NSCoder) {
        phId = aDecoder.decodeObject(forKey: "phId") as! String
        name = aDecoder.decodeObject(forKey: "name") as! String
        objectName = aDecoder.decodeObject(forKey: "objectName") as! String
    }

    var phId: String
    var name: String
    var objectName: String
 
    init(phId: String, name: String, objectName: String) {
        self.phId = phId
        self.name = name
        self.objectName = objectName
    }

    func copyURL() {
        NSPasteboard.general().clearContents()
        NSPasteboard.general().setString(objectName, forType: NSStringPboardType)
    }
    
    func openPageURL() {
        let url = URL(string: PhabricatorImageStore.shared.settings.phabEndpoint + objectName)
        NSWorkspace.shared().open(url!)
    }
}
