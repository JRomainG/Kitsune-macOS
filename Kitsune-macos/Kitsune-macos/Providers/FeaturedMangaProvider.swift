//
//  FeaturedMangaProvider.swift
//  Kitsune
//
//  Created by Jean-Romain on 08/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Foundation
import MangaDexLib

class FeaturedMangaProvider: MangaProvider {

    override var title: String {
        return "Featured"
    }

    override init(api: MDApi) {
        super.init(api: api)
        type = .featured
    }

    override func loadMore() {
        // There is only one page
        return
    }

    override func load(append: Bool = false) {
        super.load(append: append)

        api.getFeaturedMangas { (response) in
            self.finishLoading(with: response, append: append, pagingEnabled: false)
        }
    }

}
