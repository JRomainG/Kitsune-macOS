//
//  ArchiveManager.swift
//  Kitsune
//
//  Created by Jean-Romain on 20/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Foundation

class ArchiveManager {

    /// Write a manga to disk, including all its chapters
    static func saveManga(_ manga: MangaArchive) {
        do {
            try ArchiveManager.archive(manga)
            for chapter in manga.chapters {
                ArchiveManager.saveChapter(chapter)
            }
        } catch {
            print("Failed to archive manga: \(error)")
        }
    }

    /// Add a chapter to a saved manga on disk
    static func saveChapter(_ chapter: ChapterArchive) {
        do {
            try ArchiveManager.archive(chapter)
        } catch {
            print("Failed to archive chapter: \(error)")
        }
    }

    /// Reload all saved mangas
    static func restoreMangas() -> [MangaArchive]? {
        guard let root = ArchiveManager.getDownloadsFolder() else {
            return nil
        }
        do {
            var mangas: [MangaArchive] = []
            for file in try ArchiveManager.getFolders(at: root) {
                if ArchiveManager.isFolder(file),
                    let mangaId = Int(file.lastPathComponent),
                    let manga = restoreManga(mangaId: mangaId) {
                    mangas.append(manga)
                }
            }
            return mangas
        } catch {
            print("Failed to restore manga list: \(error)")
            return nil
        }
    }

    /// Reload a manga from the disk
    static func restoreManga(mangaId: Int, fetchChapters: Bool = false) -> MangaArchive? {
        guard let root = ArchiveManager.getMangaFolder(mangaId: mangaId) else {
            return nil
        }
        do {
            // Restore the manga's core info
            let url = root.appendingPathComponent("manga.xml")
            let fileData = try Data(contentsOf: url)
            let unarchiver = NSKeyedUnarchiver(forReadingWith: fileData)
            let manga = unarchiver.decodeObject() as? MangaArchive
            unarchiver.finishDecoding()

            // Also restore chapters, if necessary
            if fetchChapters {
                for file in try ArchiveManager.getFolders(at: root) {
                    if ArchiveManager.isFolder(file),
                        let chapterId = Int(file.lastPathComponent),
                        let chapter = restoreChapter(chapterId: chapterId, mangaId: mangaId) {
                        manga?.chapters.append(chapter)
                    }
                }
            }
            return manga
        } catch {
            print("Failed to restore manga: \(error)")
            return nil
        }
    }

    /// Reload a chapter from the disk, including its pages
    ///
    /// Note: Chapter page images are lazily loaded when requested
    static func restoreChapter(chapterId: Int, mangaId: Int) -> ChapterArchive? {
        guard let root = ArchiveManager.getChapterFolder(chapterId: chapterId, mangaId: mangaId) else {
            return nil
        }
        do {
            let url = root.appendingPathComponent("chapter.xml")
            let fileData = try Data(contentsOf: url)
            let unarchiver = NSKeyedUnarchiver(forReadingWith: fileData)
            let chapter = unarchiver.decodeObject() as? ChapterArchive
            chapter?.archiveRoot = root
            unarchiver.finishDecoding()
            return chapter
        } catch {
            print("Failed to restore chapter: \(error)")
            return nil
        }
    }

    /// Archive a manga's info, without its chapters
    private static func archive(_ manga: MangaArchive) throws {
        guard let root = ArchiveManager.getMangaFolder(mangaId: manga.mangaId) else {
            return
        }
        try ArchiveManager.initFolder(at: root)
        let path = root.appendingPathComponent("manga.xml")
        try ArchiveManager.archive(object: manga, at: path)
    }

    /// Archive a chapter's info, including all its pages
    private static func archive(_ chapter: ChapterArchive) throws {
        guard let root = ArchiveManager.getChapterFolder(chapterId: chapter.chapterId, mangaId: chapter.mangaId) else {
            return
        }
        try ArchiveManager.initFolder(at: root)
        let path = root.appendingPathComponent("chapter.xml")
        chapter.archiveRoot = root
        try ArchiveManager.archive(object: chapter, at: path)
    }

    private static func archive(object: NSCoding, at path: URL) throws {
        // Save data as xml so it's human readable
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.requiresSecureCoding = false
        archiver.outputFormat = .xml
        archiver.encode(object)
        archiver.finishEncoding()
        try data.write(to: path)
    }

    private static func getDownloadsFolder() -> URL? {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard var folderUrl = urls.last else {
            return nil
        }
        folderUrl.appendPathComponent(Bundle.main.bundleIdentifier ?? "")
        folderUrl.appendPathComponent("downloads")
        do {
            try initFolder(at: folderUrl)
        } catch {
            return nil
        }
        return folderUrl
    }

    private static func getMangaFolder(mangaId: Int) -> URL? {
        let folderUrl = ArchiveManager.getDownloadsFolder()
        return folderUrl?.appendingPathComponent("\(mangaId)")
    }

    private static func getChapterFolder(chapterId: Int, mangaId: Int) -> URL? {
        let folderUrl = ArchiveManager.getMangaFolder(mangaId: mangaId)
        return folderUrl?.appendingPathComponent("\(chapterId)")
    }

    private static func isFolder(_ url: URL) -> Bool {
        var isDir = ObjCBool(false)
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        return exists && isDir.boolValue
    }

    private static func initFolder(at url: URL) throws {
        guard !isFolder(url) else {
            return
        }
        let fileManager = FileManager()
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: [
            .extensionHidden: false
        ])
    }

    private static func getFolders(at root: URL) throws -> [URL] {
        let fileManager = FileManager()
        return try fileManager.contentsOfDirectory(at: root,
                                                   includingPropertiesForKeys: nil,
                                                   options: .skipsSubdirectoryDescendants)
    }

}
