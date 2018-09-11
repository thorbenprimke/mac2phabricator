//
//  PhabricatorSettings.swift
//

import Foundation

class PhabricatorSettings: NSObject, NSCoding {
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(apiKey, forKey: "apiKey")
        aCoder.encode(phabEndpoint, forKey: "phabEndpoint")
    }
    
    required init?(coder aDecoder: NSCoder) {
        apiKey = aDecoder.decodeObject(forKey: "apiKey") as! String
        let phabEndpointRaw = aDecoder.decodeObject(forKey: "phabEndpoint")
        if (phabEndpointRaw != nil) {
            phabEndpoint = phabEndpointRaw as! String
        } else {
            phabEndpoint = ""
        }
    }
    
    var apiKey: String
    var phabEndpoint: String
    
    init(apiKey: String = "", phabEndpoint: String = "") {
        self.apiKey = apiKey
        self.phabEndpoint = phabEndpoint
    }
}
