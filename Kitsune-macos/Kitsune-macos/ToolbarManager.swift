//
//  ToolbarManager.swift
//  Kitsune
//
//  Created by Jean-Romain on 08/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa

class ToolbarManager {

    static var toolbar: NSToolbar? {
        return NSApplication.shared.mainWindow?.toolbar
    }

    static var accountButton: NSButton? {
        return itemWithTag(1)?.view as? NSButton
    }

    static var filterButton: NSButton? {
        return itemWithTag(2)?.view as? NSButton
    }

    static var segmentedControl: NSSegmentedControl? {
        return itemWithTag(3)?.view as? NSSegmentedControl
    }

    static var searchBar: NSSearchField? {
        return itemWithTag(4)?.view as? NSSearchField
    }

    private static func itemWithTag(_ tag: Int) -> NSToolbarItem? {
        return toolbar?.items.first(where: { (item) -> Bool in
            return item.tag == tag
        })
    }

    static func didLogin() {
        accountButton?.image = NSImage(named: "Account")
    }

    static func didLogout() {
        accountButton?.image = NSImage(imageLiteralResourceName: "NSTouchBarUserAddTemplate")
    }

    static func hide() {
        toolbar?.isVisible = false
    }

    static func show() {
        toolbar?.isVisible = false
    }

}
