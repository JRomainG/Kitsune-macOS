//
//  MDManga+Display.swift
//  Kitsune
//
//  Created by Jean-Romain on 12/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import MangaDexLib

extension MDManga {

    var displayTags: String {
        var formattedTags: [String] = []
        for tag in tags ?? [] {
            if let content = MDContent(rawValue: tag) {
                formattedTags.append(String(describing: content))
            } else if let genre = MDGenre(rawValue: tag) {
                formattedTags.append(String(describing: genre))
            } else if let theme = MDTheme(rawValue: tag) {
               formattedTags.append(String(describing: theme))
           }
        }
        return formattedTags.joined(separator: ", ")
    }

}
