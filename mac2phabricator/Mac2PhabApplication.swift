//
//  Mac2PhabApplication.swift
//

import Foundation
import Cocoa
import AppKit

// Apparently these aren't declared anywhere, but are implemented by NSWindow
@objc protocol MenuActions {
    func redo(_ sender: Any?)
    func undo(_ sender: Any?)
}


class Mac2PhabApplication : NSApplication {

    private let commandKey = NSEvent.ModifierFlags.command.rawValue

    override func sendEvent(_ event: NSEvent) {
        if (event.type == NSEvent.EventType.keyDown) {
            if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
                switch event.charactersIgnoringModifiers! {
                    case "x":
                        if sendAction(#selector(NSText.cut(_:)), to:nil, from:self) { return }
                    case "c":
                        if sendAction(#selector(NSText.copy(_:)), to:nil, from:self) { return }
                    case "v":
                        if sendAction(#selector(NSText.paste(_:)), to:nil, from:self) { return }
                    case "z":
                        if sendAction(#selector(MenuActions.undo(_:)), to:nil, from:self) { return }
                    case "a":
                        if sendAction(#selector(NSResponder.selectAll(_:)), to:nil, from:self) { return }
                    case "w":
                        if sendAction(#selector(NSWindow.performClose(_:)), to: nil, from: self) { return }
                    default:
                        break
                }
            } else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == (NSEvent.ModifierFlags.command.rawValue |  NSEvent.ModifierFlags.shift.rawValue) {
                if event.charactersIgnoringModifiers! == "Z" {
                    if sendAction(#selector(MenuActions.redo(_:)), to: nil, from: self) { return }
                }
            }
        }
        super.sendEvent(event)
    }
}
