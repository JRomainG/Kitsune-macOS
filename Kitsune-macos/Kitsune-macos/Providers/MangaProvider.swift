//
//  MangaProvider.swift
//  Kitsune
//
//  Created by Jean-Romain on 08/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Foundation
import MangaDexLib

protocol MangaProviderDelegate: AnyObject {

    func didStartInitialLoad(provider: MangaProvider)
    func didStartLoadingMore(provider: MangaProvider)
    func didFinishLoading(provider: MangaProvider)
    func didFailLoading(provider: MangaProvider, error: Error)

}

extension MangaProviderDelegate {

    // Make those optionals by providing a default implementation
    func didStartInitialLoad(provider: MangaProvider) {}
    func didStartLoadingMore(provider: MangaProvider) {}
    func didFinishLoading(provider: MangaProvider) {}
    func didFailLoading(provider: MangaProvider, error: Error) {}

}

class MangaProvider: NSObject {

    enum ProviderType: Int {
        case latest
        case featured
        case listed
        case followed
        case search
    }

    enum ProviderState {
        /// Waiting for first request to homepage
        case waiting

        /// Downloading first page
        case initialLoad

        /// Downloading more pages
        case loadingMore

        /// Waiting for instructions
        ///
        /// - Note: `getDetails` is not taken into account
        case idle

        /// Download failed
        case errored
    }

    var type: ProviderType = .latest
    var state: ProviderState = .waiting
    var error: Error?

    /// Sort order, if relevant
    var sortOrder: MDSortOrder = .bestRating {
        didSet {
            if state == .idle || state == .errored {
                state = .idle
                startLoading()
            }
        }
    }

    private let mangaSemaphore = DispatchSemaphore(value: 1)

    var page = 1
    var mangas: [MDManga] = []
    var hasMorePages = false

    var api: MDApi
    weak var delegate: MangaProviderDelegate?

    init(api: MDApi) {
        self.api = api
    }

    func becomeReady() {
        guard state == .waiting else {
            return
        }
        state = .idle
    }

    func startLoading() {
        guard state == .idle else {
            return
        }

        page = 1
        mangas = []
        state = .initialLoad
        load()
        delegate?.didStartInitialLoad(provider: self)
    }

    func loadMore() {
        guard state == .idle else {
            return
        }

        page += 1
        state = .loadingMore
        load(append: true)
        delegate?.didStartLoadingMore(provider: self)
    }

    func load(append: Bool = false) {
        // To override
    }

    func finishLoading(with response: MDResponse, append: Bool, pagingEnabled: Bool) {
        guard response.error == nil else {
            state = .errored
            error = response.error
            delegate?.didFailLoading(provider: self, error: response.error!)
            return
        }

        let newMangas = response.mangas ?? []
        self.mangaSemaphore.wait()
        if append {
            mangas.append(contentsOf: newMangas)
        } else {
            mangas = newMangas
        }
        self.mangaSemaphore.signal()

        state = .idle
        hasMorePages = pagingEnabled && !newMangas.isEmpty
        delegate?.didFinishLoading(provider: self)
    }

    func cancelRequests() {
        api.requestHandler.session.getAllTasks { (tasks) in
            for task in tasks {
                task.cancel()
            }
        }
        state = .idle
    }

    func getDetails(for manga: MDManga, completion: @escaping (MDManga?) -> Void) {
        guard let mangaId = manga.mangaId else {
            completion(nil)
            return
        }

        api.getMangaDetails(mangaId: mangaId, title: manga.title) { (response) in
            // Update the array so the info is kept for later
            self.mangaSemaphore.wait()
            let index = self.mangas.firstIndex { (manga) -> Bool in
                return manga.mangaId == mangaId
            }
            if index != nil, let manga = response.manga {
                self.mangas[index!] = MangaProvider.merged(first: self.mangas[index!], second: manga)
            }
            self.mangaSemaphore.signal()
            completion(response.manga)
        }
    }

    static func merged(first: MDManga, second: MDManga) -> MDManga {
        var newManga = first
        newManga.mangaId = first.mangaId ?? second.mangaId
        newManga.title = first.title ?? second.title
        newManga.author = first.author ?? second.author
        newManga.artist = first.artist ?? second.artist
        newManga.description = first.description ?? second.description
        newManga.chapters = first.chapters ?? second.chapters
        newManga.publicationStatus = first.publicationStatus ?? second.publicationStatus
        newManga.readingStatus = first.readingStatus ?? second.readingStatus
        newManga.currentVolume = first.currentVolume ?? second.currentVolume
        newManga.currentChapter = first.currentChapter ?? second.currentChapter
        newManga.tags = first.tags ?? second.tags
        newManga.lastChapter = first.lastChapter ?? second.lastChapter
        newManga.originalLangName = first.originalLangName ?? second.originalLangName
        newManga.originalLangCode = first.originalLangCode ?? second.originalLangCode
        newManga.rated = first.rated ?? second.rated
        newManga.status = first.status ?? second.status
        return newManga
    }

}
