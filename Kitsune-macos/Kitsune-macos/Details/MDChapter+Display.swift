//
//  MDChapter+Display.swift
//  Kitsune
//
//  Created by Jean-Romain on 11/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import MangaDexLib

extension MDChapter {

    var displayTitle: String {
        var output = ""

        if let volume = self.volume, !volume.isEmpty,
            let chapter = self.chapter, !chapter.isEmpty {
            output += "Vol. \(volume) chap. \(chapter)"
        } else if let chapter = self.chapter, !chapter.isEmpty {
            output += "Chap. \(chapter)"
        } else if let volume = self.volume, !volume.isEmpty {
            output += "Vol. \(volume)"
        }

        if let title = self.title, !title.isEmpty {
            if output.isEmpty {
                output = title
            } else {
                output += ": \(title)"
            }
        }

        if output.isEmpty {
            output = "-"
        }

        return output
    }

    var releaseDate: String {
        guard let timestamp = self.timestamp else {
            return "-"
        }

        let date = Date(timeIntervalSince1970: Double(timestamp))

        if #available(OSX 10.15, *) {
            let dateFormatter = RelativeDateTimeFormatter()
            dateFormatter.unitsStyle = .full
            return dateFormatter.localizedString(for: date, relativeTo: Date())
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = NSLocale.current
        dateFormatter.timeZone = .autoupdatingCurrent
        return dateFormatter.string(from: date)
    }

    func isRead(for manga: MDManga?) -> Bool {
        if let readVolume = Float(manga?.currentVolume ?? ""),
            let chapterVolume = Float(volume ?? ""),
            readVolume > chapterVolume {
            return true
        }
        if let readChapter = Float(manga?.currentChapter ?? ""),
            let chapter = Float(chapter ?? ""),
            readChapter >= chapter {
            return true
        }
        return false
    }

}
