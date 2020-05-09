//
//  ListedMangaProvider.swift
//  Kitsune
//
//  Created by Jean-Romain on 08/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Foundation
import MangaDexLib

class ListedMangaProvider: MangaProvider {

    var sortOrder: MDSortOrder = .bestRating {
        didSet {
            state = .idle
            startLoading()
        }
    }

    override init(api: MDApi) {
        super.init(api: api)
        type = .listed
    }

    override func load(append: Bool = false) {
        super.load(append: append)

        api.getListedMangas(page: page, sort: sortOrder) { (response) in
            self.finishLoading(with: response, append: append, pagingEnabled: true)
        }
    }

}
