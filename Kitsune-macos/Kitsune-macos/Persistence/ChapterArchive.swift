//
//  ChapterArchive.swift
//  Kitsune
//
//  Created by Jean-Romain on 20/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Foundation
import MangaDexLib

class ChapterArchive: NSObject, NSCoding {

    let chapterId: Int
    let mangaId: Int
    var title: String?
    var volume: String?
    var chapter: String?
    var pages: [PageArchive]
    var groupId: Int?
    var groupName: String?
    var timestamp: UInt?
    var originalLang: MDLanguage?
    var longStrip: Int?

    var archiveRoot: URL? {
        didSet {
            for page in pages {
                page.archiveRoot = archiveRoot
            }
        }
    }

    func encode(with coder: NSCoder) {
        coder.encode(chapterId, forKey: "id")
        coder.encode(mangaId, forKey: "mangaId")
        coder.encode(title, forKey: "title")
        coder.encode(volume, forKey: "volume")
        coder.encode(chapter, forKey: "chapter")
        coder.encode(pages, forKey: "pages")
        coder.encode(groupId, forKey: "groupId")
        coder.encode(groupName, forKey: "groupName")
        coder.encode(timestamp, forKey: "timestamp")
        coder.encode(originalLang?.rawValue, forKey: "lang")
        coder.encode(longStrip, forKey: "longStrip")
    }

    required init?(coder: NSCoder) {
        // Force decode these as integers as they are required
        chapterId = coder.decodeInteger(forKey: "id")
        mangaId = coder.decodeInteger(forKey: "mangaId")

        // Try to decode, but don't crash on nil values
        title = coder.decodeObject(forKey: "title") as? String
        volume = coder.decodeObject(forKey: "volume") as? String
        chapter = coder.decodeObject(forKey: "chapter") as? String
        pages = coder.decodeObject(forKey: "pages") as? [PageArchive] ?? []
        groupId = coder.decodeObject(forKey: "groupId") as? Int
        groupName = coder.decodeObject(forKey: "groupName") as? String
        timestamp = coder.decodeObject(forKey: "timestamp") as? UInt
        longStrip = coder.decodeObject(forKey: "longStrip") as? Int

        if let lang = coder.decodeObject(forKey: "lang") as? Int {
            originalLang = MDLanguage(rawValue: lang)
        }
    }

    init(from mdChapter: MDChapter) {
        chapterId = mdChapter.chapterId!
        mangaId = mdChapter.mangaId!
        title = mdChapter.title
        volume = mdChapter.volume
        chapter = mdChapter.chapter
        groupId = mdChapter.groupId
        groupName = mdChapter.groupName
        timestamp = mdChapter.timestamp
        originalLang = mdChapter.getOriginalLang()
        longStrip = mdChapter.longStrip

        self.pages = []
        for page in mdChapter.getPageUrls() ?? [] {
            pages.append(PageArchive(url: page))
        }
    }

}

extension MDChapter {

    init(from archive: ChapterArchive) {
        self.init(chapterId: archive.chapterId)
        title = archive.title
        volume = archive.volume
        chapter = archive.chapter
        groupId = archive.groupId
        groupName = archive.groupName
        timestamp = archive.timestamp
        originalLangCode = "gb"
        longStrip = archive.longStrip
    }

}
