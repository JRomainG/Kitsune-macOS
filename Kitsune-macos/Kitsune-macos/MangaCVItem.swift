//
//  MangaCVItem.swift
//  Kitsune
//
//  Created by Jean-Romain on 04/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import SDWebImage

class MangaCVItem: NSCollectionViewItem {

    @IBOutlet var containerView: NSView!

    var manga: MangaItem? {
        didSet {
            textField?.stringValue = manga?.title ?? "-"

            imageView?.sd_setImage(with: manga?.coverUrl,
                                   placeholderImage: nil,
                                   options: .scaleDownLargeImages,
                                   progress: nil) { (_, _, _, _) in
                                    self.updateImageBackgroundColor()
            }
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
        updateImageBackgroundColor()
        updateBorderColor()
    }

    private func updateImageBackgroundColor() {
        if imageView?.image == nil {
            imageView?.layer?.backgroundColor = NSColor(named: "CVItemBackground")?.cgColor
        } else {
            imageView?.layer?.backgroundColor = NSColor.clear.cgColor
        }
    }

    private func updateBorderColor() {
        if isSelected {
            containerView.layer?.borderColor = NSColor.selectedControlColor.cgColor
        } else {
            containerView.layer?.borderColor = NSColor.clear.cgColor
        }
    }

}
