//
//  LatestMangaProvider.swift
//  Kitsune
//
//  Created by Jean-Romain on 08/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Foundation
import MangaDexLib

class LatestMangaProvider: MangaProvider {

    override init(api: MDApi) {
        super.init(api: api)
        type = .latest
    }

    override func startLoading() {
        guard !isLoading else {
            return
        }

        super.startLoading()
        load()
    }

    override func loadMore() {
        guard !isLoading else {
            return
        }

        super.loadMore()
        load()
    }

    private func load(append: Bool = false) {
        api.getLatestMangas(page: page) { (response) in
            self.isLoading = false

            if response.error != nil {
                self.delegate?.didFailLoading(provider: self, error: response.error!)
            } else {
                self.mangas = response.mangas ?? []
                self.delegate?.didFinishLoading(provider: self)
            }
        }
    }

}
