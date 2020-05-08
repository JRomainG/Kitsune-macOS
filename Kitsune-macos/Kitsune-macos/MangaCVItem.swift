//
//  MangaCVItem.swift
//  Kitsune
//
//  Created by Jean-Romain on 04/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import MangaDexLib
import SDWebImage

class MangaCVItem: NSCollectionViewItem {

    @IBOutlet var containerView: NSView!

    var manga: MDManga? {
        didSet {
            // Update the display
            textField?.stringValue = manga?.title ?? "-"
            downloadCover()
        }
    }

    override var isSelected: Bool {
        didSet {
            super.isSelected = isSelected
            updateBorderColor()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.postsFrameChangedNotifications = false
        view.postsBoundsChangedNotifications = false

        textField?.maximumNumberOfLines = 2

        imageView?.wantsLayer = true
        imageView?.layer?.cornerRadius = 4.0
        imageView?.image = NSImage(named: "CoverPlaceholder")

        containerView.wantsLayer = true
        containerView.layer?.borderWidth = 1
        containerView.layer?.cornerRadius = 4.0

        view.addConstraint(NSLayoutConstraint(item: containerView as Any,
                                               attribute: .height,
                                               relatedBy: .lessThanOrEqual,
                                               toItem: view,
                                               attribute: .height,
                                               multiplier: 1,
                                               constant: -2))

        view.addConstraint(NSLayoutConstraint(item: containerView as Any,
                                               attribute: .width,
                                               relatedBy: .lessThanOrEqual,
                                               toItem: view,
                                               attribute: .width,
                                               multiplier: 1,
                                               constant: -2))
    }

    override func viewDidLayout() {
        // When the computer's theme (e.g. dark mode) is changed, NSAppearance.current is not updated
        // Thus, the values read from NSColor are still the ones for the old theme, so we manually change it
        NSAppearance.current = view.effectiveAppearance
        updateBorderColor()
    }

    private func updateBorderColor() {
        if isSelected {
            containerView.layer?.borderColor = NSColor.selectedControlColor.cgColor
        } else {
            containerView.layer?.borderColor = NSColor.clear.cgColor
        }
    }

    func downloadCover() {
        guard let coverUrl = manga?.coverUrl,
            let url = URL(string: coverUrl) else {
            return
        }

        let placeholder = NSImage(named: "CoverPlaceholder")
        imageView?.sd_setImage(with: url,
                               placeholderImage: placeholder,
                               options: .scaleDownLargeImages,
                               completed: nil)
    }

}
