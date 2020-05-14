//
//  ErrorLabel.swift
//  Kitsune
//
//  Created by Jean-Romain on 14/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa

class ErrorLabel: NSTextField {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        autoresizingMask = [.width, .height]
        translatesAutoresizingMaskIntoConstraints = false
        isEditable = false
        isSelectable = true
        isBordered = false
        font = .boldSystemFont(ofSize: 18)
        textColor = .secondaryLabelColor
        stringValue = ""
    }

}
