//
//  MangaArchive.swift
//  Kitsune
//
//  Created by Jean-Romain on 20/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Foundation
import MangaDexLib

class MangaArchive: NSObject, NSCoding {

    let mangaId: Int
    var title: String?
    var author: String?
    var artist: String?
    var mangaDescription: String?
    var readingStatus: MDReadingStatus?
    var publicationStatus: MDPublicationStatus?
    var tags: [Int]
    var chapters: [ChapterArchive]

    func encode(with coder: NSCoder) {
        coder.encode(mangaId, forKey: "id")
        coder.encode(title, forKey: "title")
        coder.encode(author, forKey: "author")
        coder.encode(artist, forKey: "artist")
        coder.encode(mangaDescription, forKey: "description")
        coder.encode(readingStatus?.rawValue, forKey: "readingStatus")
        coder.encode(publicationStatus?.rawValue, forKey: "publicationStatus")
        coder.encode(tags, forKey: "tags")
    }

    required init?(coder: NSCoder) {
        mangaId = coder.decodeInteger(forKey: "id")
        title = coder.decodeObject(forKey: "title") as? String
        author = coder.decodeObject(forKey: "author") as? String
        artist = coder.decodeObject(forKey: "artist") as? String
        mangaDescription = coder.decodeObject(forKey: "description") as? String
        tags = coder.decodeObject(forKey: "tags") as? [Int] ?? []
        chapters = []

        if let readingStatusCode = coder.decodeObject(forKey: "readingStatus") as? Int {
            readingStatus = MDReadingStatus(rawValue: readingStatusCode)
        }
        if let publicationStatusCode = coder.decodeObject(forKey: "publicationStatus") as? Int {
            publicationStatus = MDPublicationStatus(rawValue: publicationStatusCode)
        }
    }

    init(from mdManga: MDManga) {
        mangaId = mdManga.mangaId!
        title = mdManga.title
        author = mdManga.author
        artist = mdManga.artist
        mangaDescription = mdManga.description
        readingStatus = mdManga.readingStatus
        publicationStatus = mdManga.publicationStatus
        tags = mdManga.tags ?? []

        chapters = []
        for chapter in mdManga.chapters ?? [] {
            chapters.append(ChapterArchive(from: chapter))
        }

        chapters = chapters.filter { (chapter) -> Bool in
            return chapter.originalLang == .english
        }
    }

}

extension MDManga {

    init(from archive: MangaArchive) {
        self.init(mangaId: archive.mangaId)
        title = archive.title
        author = archive.author
        artist = archive.artist
        description = archive.mangaDescription
        readingStatus = archive.readingStatus
        publicationStatus = archive.publicationStatus
        tags = archive.tags

        // If there are any, convert chapter archives to MDChapters
        if !archive.chapters.isEmpty {
            chapters = []
            for chapter in archive.chapters {
                chapters?.append(MDChapter(from: chapter))
            }
        }
    }

}
