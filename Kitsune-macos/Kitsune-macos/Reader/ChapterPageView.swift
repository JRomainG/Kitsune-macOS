//
//  ChapterPageView.swift
//  Kitsune
//
//  Created by Jean-Romain on 13/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa

class ChapterPageView: NSImageView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        autoresizingMask = [.height, .width]
        imageScaling = .scaleProportionallyDown
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentHuggingPriority(.defaultHigh, for: .vertical)
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        image = NSImage(named: "PagePlaceholder")
    }

    func setImage(with url: URL?) {
        sd_setImage(with: url,
                    placeholderImage: NSImage(named: "PagePlaceholder"),
                    options: .decodeFirstFrameOnly,
                    completed: nil)
    }

}
