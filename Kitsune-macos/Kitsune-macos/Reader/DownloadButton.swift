//
//  DownloadButton.swift
//  Kitsune
//
//  Created by Jean-Romain on 15/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa

class DownloadButton: LinkButton {

    var loadingIndicator = NSProgressIndicator()

    override func commonInit() {
        super.commonInit()
        image = NSImage(named: "Download")
        loadingIndicator.autoresizingMask = [.maxXMargin, .maxYMargin, .minXMargin, .minYMargin]
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.style = .spinning
        loadingIndicator.isIndeterminate = true
        loadingIndicator.controlSize = .small
        loadingIndicator.sizeToFit()
        loadingIndicator.isDisplayedWhenStopped = false
        loadingIndicator.stopAnimation(nil)
        addSubview(loadingIndicator)
        loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    func startLoading() {
        image = nil
        isEnabled = false
        loadingIndicator.startAnimation(nil)
    }

    func stopLoading() {
        image = NSImage(named: "Download")
        isEnabled = true
        loadingIndicator.stopAnimation(nil)
    }

}
