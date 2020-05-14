//
//  LinkButton.swift
//  Kitsune
//
//  Created by Jean-Romain on 14/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa

class LinkButton: NSButton {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func commonInit() {
        autoresizingMask = [.width, .height]
        bezelStyle = .roundRect
        isBordered = false
        if #available(OSX 10.14, *) {
            contentTintColor = .controlAccentColor
        }
        translatesAutoresizingMaskIntoConstraints = false
    }

}
