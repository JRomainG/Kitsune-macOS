//
//  MangaItem.swift
//  Kitsune
//
//  Created by Jean-Romain on 05/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import Quartz

class MangaItem: NSObject {

    var title: String
    var coverUrl: URL?

    init(title: String, cover: String) {
        self.title = title
        self.coverUrl = URL(string: cover)
    }

}

extension MangaItem: QLPreviewItem {

    var previewItemTitle: String! {
        return title
    }

    var previewItemURL: URL! {
        return coverUrl ?? URL(string: "https://mangadex.org")!
    }

}
