//
//  SettingsViewController.swift
//
//

import Foundation
import Cocoa

class SettingsViewController: NSViewController  {
    
    @IBOutlet weak var APIKeyInputField: NSTextFieldCell!
    @IBOutlet weak var PhabEndpointInputField: NSTextField!
    
    override func viewDidLoad() {
        APIKeyInputField.stringValue = PhabricatorImageStore.shared.settings.apiKey
        PhabEndpointInputField.stringValue = PhabricatorImageStore.shared.settings.phabEndpoint
        super.viewDidLoad()
    }
    
    @IBAction func OnSaveClicked(_ sender: Any) {
        let settings  = PhabricatorImageStore.shared.settings
        settings.apiKey = APIKeyInputField.stringValue
        settings.phabEndpoint = PhabEndpointInputField.stringValue
        PhabricatorImageStore.shared.settings = settings

        self.view.window?.close()
    }

    @IBAction func OnCancelClicked(_ sender: Any) {
        self.view.window?.close()
    }
}
