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

    override var title: String {
        return "Latest"
    }

    override init(api: MDApi) {
        super.init(api: api)
        type = .latest
    }

    override func load(append: Bool = false) {
        super.load(append: append)

        api.getLatestMangas(page: page) { (response) in
            self.finishLoading(with: response, append: append, pagingEnabled: true)
        }
    }

}
