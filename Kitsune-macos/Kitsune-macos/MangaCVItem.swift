//
//  MangaCVItem.swift
//  Kitsune
//
//  Created by Jean-Romain on 04/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa

class MangaCVItem: NSCollectionViewItem {

    override var isSelected: Bool {
        didSet {
            super.isSelected = isSelected
            updateImageBorderColor()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.postsFrameChangedNotifications = false
        view.postsBoundsChangedNotifications = false
        imageView?.wantsLayer = true
        imageView?.layer?.masksToBounds = true
        imageView?.layer?.cornerRadius = 4.0
        imageView?.layer?.borderWidth = 1
    }

    override func viewDidLayout() {
        // When the computer's theme (e.g. dark mode) is changed, NSAppearance.current is not updated
        // Thus, the values read from NSColor are still the ones for the old theme, so we manually change it
        NSAppearance.current = view.effectiveAppearance
        updateImageBackgroundColor()
        updateImageBorderColor()
    }

    private func updateImageBackgroundColor() {
        imageView?.layer?.backgroundColor = NSColor(named: "CVItemBackground")?.cgColor
    }

    private func updateImageBorderColor() {
        if isSelected {
            imageView?.layer?.borderColor = NSColor.selectedControlColor.cgColor
        } else {
            imageView?.layer?.borderColor = NSColor.clear.cgColor
        }
    }

}
