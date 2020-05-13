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

    func follows(chapter: MDChapter) -> Bool {
        if let otherChapter = Float(chapter.chapter ?? ""),
            let thisChapter = Float(self.chapter ?? "") {
            // Chapters are filled in, we can rely on them
            if thisChapter > otherChapter && thisChapter <= otherChapter + 1 {
                // The chapters follow one another, it's fine if their volume is the same
                // Some chapters may have "half" values (like 1.5)
                return chapter.volume == self.volume
            } else if otherChapter < 2 {
                // Check if the other chapter is at the start of a new volume
                // Sometimes, chapters start at 0
                if let otherVolume = Float(chapter.volume ?? ""),
                    let thisVolume = Float(self.volume ?? "") {
                    return otherVolume > thisVolume && otherVolume <= thisVolume + 1
                }
                return true
            }
            return false
        } else if let otherVolume = Float(chapter.volume ?? ""),
            let thisVolume = Float(self.volume ?? "") {
            // Volumes are filled in, but not chapters
            return thisVolume >= otherVolume && thisVolume <= otherVolume + 1
        }
        // Missing information, assume it's fine
        return true
    }

    private func comesBefore(volume: String?, chapter: String?, strict: Bool = true) -> Bool {
        if let otherVolume = Float(volume ?? ""),
            let thisVolume = Float(self.volume ?? ""),
            otherVolume != thisVolume {
            return otherVolume > thisVolume
        }
        if let otherChapter = Float(chapter ?? ""),
            let thisChapter = Float(self.chapter ?? "") {
            if strict {
                return otherChapter > thisChapter
            } else {
                return otherChapter >= thisChapter
            }
        }
        return false
    }

    func comesBefore(chapter: MDChapter) -> Bool {
        return comesBefore(volume: chapter.volume, chapter: chapter.chapter)
    }

    func isRead(for manga: MDManga?) -> Bool {
        return comesBefore(volume: manga?.currentVolume, chapter: manga?.currentChapter, strict: false)
    }

}
