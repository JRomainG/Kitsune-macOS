//
//  DownloadedMangaProvider.swift
//  Kitsune
//
//  Created by Jean-Romain on 20/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Foundation
import MangaDexLib
import SDWebImage

class DownloadedMangaProvider: MangaProvider {

    override var title: String {
        return "Downloads"
    }

    lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "Chapter pages download queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    static var shared: DownloadedMangaProvider = {
        let api = MDApi()
        let provider = DownloadedMangaProvider(api: api)
        return provider
    }()

    override init(api: MDApi) {
        super.init(api: api)
        type = .downloaded

        // Contrary to other providers, this one doesn't need to wait for
        // the initial MangaDex page load, so mark it as idle directly
        state = .idle
    }

    func download(chapters: [MDChapter], for manga: MDManga) {
        guard manga.mangaId != nil else {
            return
        }

        // Only create an archive for chapters which are needed
        var savedManga = manga
        savedManga.chapters = chapters
        let mangaArchive = MangaArchive(from: savedManga)
        ArchiveManager.saveManga(mangaArchive)

        for chapter in mangaArchive.chapters {
            let operation = ChapterPagesOperation()
            operation.chapter = chapter
            operation.api = api
            operation.completionBlock = {
                print("Done downloading chapter")
            }
            operationQueue.addOperation(operation)
        }
    }

    override func cancelRequests() {
        SDWebImageManager.shared.cancelAll()
        super.cancelRequests()
    }

    override func loadMore() {
        // There is only one page
        return
    }

    override func load(append: Bool = false) {
        super.load(append: append)
        let archives = ArchiveManager.restoreMangas()

        mangas = []
        for archive in archives ?? [] {
            let manga = MDManga(from: archive)
            mangas.append(manga)
        }
        finishLoading()
    }

    func finishLoading() {
        state = .idle
        hasMorePages = false
        delegate?.didFinishLoading(provider: self)
    }

    override func getChapters(for manga: MDManga, page: Int, completion: @escaping (MDManga?, Error?) -> Void) {
        guard let mangaId = manga.mangaId else {
            completion(nil, nil)
            return
        }
        let archive = ArchiveManager.restoreManga(mangaId: mangaId, fetchChapters: true)
        updateManga(with: mangaId, archive: archive, completion: completion)
    }

    func updateManga(with mangaId: Int, archive: MangaArchive?, completion: @escaping (MDManga?, Error?) -> Void) {
        let index = self.mangas.firstIndex { (manga) -> Bool in
            return manga.mangaId == mangaId
        }
        let newManga = archive != nil ? MDManga(from: archive!) : nil
        if index != nil, let manga = newManga {
            self.mangas[index!] = MangaProvider.merged(first: self.mangas[index!], second: manga)
        }
        completion(newManga, nil)
    }

}
