//
//  Mac2PhabApplication.swift
//

import Foundation
import Cocoa
import AppKit

class Mac2PhabApplication : NSApplication {

    private let commandKey = NSEventModifierFlags.command.rawValue

    override func sendEvent(_ event: NSEvent) {
        if (event.type == NSEventType.keyDown) {
            if (event.modifierFlags.rawValue & NSEventModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
                switch event.charactersIgnoringModifiers! {
                    case "x":
                        if sendAction(#selector(NSText.cut(_:)), to:nil, from:self) { return }
                    case "c":
                        if sendAction(#selector(NSText.copy(_:)), to:nil, from:self) { return }
                    case "v":
                        if sendAction(#selector(NSText.paste(_:)), to:nil, from:self) { return }
                    case "z":
                        // TODO: Figure out who to call undo
                        if sendAction(Selector(("undo:")), to:nil, from:self) { return }
                    case "a":
                        if sendAction(#selector(NSResponder.selectAll(_:)), to:nil, from:self) { return }
                    case "w":
                        if sendAction(#selector(NSWindow.performClose(_:)), to: nil, from: self) { return }
                    default:
                        break
                }
            }
        }
        super.sendEvent(event)
    }
}
