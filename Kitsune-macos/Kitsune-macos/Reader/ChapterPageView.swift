//
//  ChapterPageView.swift
//  Kitsune
//
//  Created by Jean-Romain on 13/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa

class ChapterPageView: NSImageView {

    var loadingIndicator = NSProgressIndicator()

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

        loadingIndicator.autoresizingMask = [.maxXMargin, .maxYMargin, .minXMargin, .minYMargin]
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.style = .spinning
        loadingIndicator.isIndeterminate = true
        loadingIndicator.controlSize = .regular
        loadingIndicator.sizeToFit()
        loadingIndicator.isDisplayedWhenStopped = false
        loadingIndicator.stopAnimation(nil)
        addSubview(loadingIndicator)
        loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    func setImage(with url: URL?) {
        loadingIndicator.startAnimation(nil)
        sd_setImage(with: url,
                    placeholderImage: NSImage(named: "PagePlaceholder"),
                    options: .decodeFirstFrameOnly) { (_, _, _, _) in
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimation(nil)
                        }
        }
    }

    func getHorizontalMargin() -> CGFloat {
        guard let image = self.image else {
            return 0
        }
        let imageSize = image.size
        var scale = min(frame.height / imageSize.height, frame.width / imageSize.width)
        scale = min(scale, 1)
        return frame.width - imageSize.width * scale
    }

}
