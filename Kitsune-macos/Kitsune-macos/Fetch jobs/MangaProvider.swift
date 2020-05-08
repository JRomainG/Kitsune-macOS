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

    func didStartLoading(provider: MangaProvider)
    func didStartLoadingMore(provider: MangaProvider)
    func didFinishLoading(provider: MangaProvider)
    func didFailLoading(provider: MangaProvider, error: Error)

}

extension MangaProviderDelegate {

    // Make those optionals by providing a default implementation
    func didStartLoading(provider: MangaProvider) {}
    func didStartLoadingMore(provider: MangaProvider) {}
    func didFinishLoading(provider: MangaProvider) {}
    func didFailLoading(provider: MangaProvider, error: Error) {}
    func didUpdateManga(provider: MangaProvider, at index: Int) {}

}

class MangaProvider: NSObject {

    enum ProviderType: Int {
        case latest
        case featured
        case listed
        case updates
        case search
    }

    var type: ProviderType = .latest
    var isLoading = false
    var page = 1
    var mangas: [MDManga] = []

    var api: MDApi
    weak var delegate: MangaProviderDelegate?

    init(api: MDApi) {
        self.api = api
    }

    func startLoading() {
        page = 1
        mangas = []
        isLoading = true
        delegate?.didStartLoading(provider: self)
    }

    func loadMore() {
        page += 1
        delegate?.didStartLoadingMore(provider: self)
    }

    func getDetails(for manga: MDManga, completion: @escaping (MDManga?) -> Void) {
        guard let mangaId = manga.mangaId else {
            completion(nil)
            return
        }

        api.getMangaDetails(mangaId: mangaId, title: manga.title) { (response) in
            // Update the array so the info is kept for later
            let index = self.mangas.firstIndex { (manga) -> Bool in
                return manga.mangaId == mangaId
            }
            if index != nil, let manga = response.manga {
                self.mangas[index!] = manga
            }

            completion(response.manga)
        }
    }

}
