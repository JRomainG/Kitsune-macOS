//
//  ToolbarManager.swift
//  Kitsune
//
//  Created by Jean-Romain on 08/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa

class ToolbarManager {

    static func toolbar(in view: NSView) -> NSToolbar? {
        return view.window?.toolbar
    }

    static func accountButton(in view: NSView) -> NSButton? {
        return itemWithTag(1, in: view)?.view as? NSButton
    }

    static func sortButton(in view: NSView) -> NSButton? {
        return itemWithTag(2, in: view)?.view as? NSButton
    }

    static func segmentedControl(in view: NSView) -> NSSegmentedControl? {
        return itemWithTag(3, in: view)?.view as? NSSegmentedControl
    }

    static func searchBar(in view: NSView) -> NSSearchField? {
        return itemWithTag(4, in: view)?.view as? NSSearchField
    }

    static func previousButton(in view: NSView) -> NSButton? {
        return itemWithTag(5, in: view)?.view as? NSButton
    }

    static func refreshButton(in view: NSView) -> NSButton? {
        return itemWithTag(6, in: view)?.view as? NSButton
    }

    private static func itemWithTag(_ tag: Int, in view: NSView) -> NSToolbarItem? {
        return toolbar(in: view)?.items.first(where: { (item) -> Bool in
            return item.tag == tag
        })
    }

    static func didLogin(from view: NSView) {
        accountButton(in: view)?.image = NSImage(named: "Account")
    }

    static func didLogout(from view: NSView) {
        accountButton(in: view)?.image = NSImage(imageLiteralResourceName: "NSTouchBarUserAddTemplate")
    }

    static func hide(from view: NSView) {
        toolbar(in: view)?.isVisible = false
    }

    static func show(from view: NSView) {
        toolbar(in: view)?.isVisible = false
    }

    static func willTransitionToHomeViewController(from view: NSView) {
        accountButton(in: view)?.isHidden = false
        sortButton(in: view)?.isHidden = false
        refreshButton(in: view)?.isHidden = false
        segmentedControl(in: view)?.isHidden = false
        searchBar(in: view)?.isHidden = true // TODO
        previousButton(in: view)?.isHidden = false
        previousButton(in: view)?.isEnabled = false
    }

    static func willTransitionToDetailViewController(from view: NSView) {
        accountButton(in: view)?.isHidden = true
        sortButton(in: view)?.isHidden = true
        refreshButton(in: view)?.isHidden = false
        segmentedControl(in: view)?.isHidden = true
        searchBar(in: view)?.isHidden = true
        previousButton(in: view)?.isHidden = false
        previousButton(in: view)?.isEnabled = true
    }

}
