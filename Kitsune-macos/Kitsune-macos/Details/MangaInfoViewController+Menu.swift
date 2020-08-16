//
//  MangaInfoViewController+Menu.swift
//  Kitsune
//
//  Created by Jean-Romain on 16/08/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import MangaDexLib

extension MangaInfoViewController: NSMenuDelegate {

    private func getMenuIndexes() -> IndexSet {
        if tableView.selectedRowIndexes.isEmpty {
            return IndexSet(integer: tableView.clickedRow)
        } else {
            return tableView.selectedRowIndexes
        }
    }

    private func areAllChaptersDownloaded(indexes: IndexSet) -> Bool {
        guard let mangaId = manga?.mangaId else {
            return false
        }
        for index in indexes {
            let chapter = chapters[index]
            guard let chapterId = chapter.chapterId else {
                return false
            }
            if !ArchiveManager.hasChapter(chapterId: chapterId, mangaId: mangaId) {
                return false
            }
        }
        return true
    }

    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()
        let indexes = getMenuIndexes()

        if indexes.count == 1 {
            // There is only one chapter, add corresponding option
            let index = indexes.first!
            let chapter = chapters[index]
            guard let chapterId = chapter.chapterId, let mangaId = manga?.mangaId else {
                return
            }

            menu.addItem(withTitle: "Read", action: #selector(didClickRead(_:)), keyEquivalent: "")

            if ArchiveManager.hasChapter(chapterId: chapterId, mangaId: mangaId) {
                // Chapter is downloaded, show a "delete" option
                menu.addItem(withTitle: "Delete", action: #selector(didClickDelete), keyEquivalent: "")
            } else {
                menu.addItem(withTitle: "Download", action: #selector(didClickDownload(_:)), keyEquivalent: "")
            }
        } else {
            // There are multiple chapters, check if all of them are downloaded
            if areAllChaptersDownloaded(indexes: indexes) {
                menu.addItem(withTitle: "Delete", action: #selector(didClickDelete), keyEquivalent: "")
            } else {
                menu.addItem(withTitle: "Download", action: #selector(didClickDownload(_:)), keyEquivalent: "")
            }
        }

    }

    @objc func didClickRead(_ sender: AnyObject) {
        let selection = IndexSet(integer: tableView.clickedRow)
        tableView.selectRowIndexes(selection, byExtendingSelection: false)
        goNext()
    }

    @objc func didClickDownload(_ sender: AnyObject) {
        guard let manga = self.manga else {
            return
        }
        let indexes = getMenuIndexes()
        var selected: [MDChapter] = []
        for index in indexes {
            selected.append(chapters[index])
        }
        DownloadedMangaProvider.shared.download(chapters: selected, for: manga)
    }

    @objc func didClickDelete(_ sender: AnyObject) {
        guard let mangaId = manga?.mangaId else {
            return
        }
        let indexes = getMenuIndexes()
        for index in indexes {
            let chapter = chapters[index]
            let archive = ChapterArchive(from: chapter, with: mangaId)
            ArchiveManager.deleteChapter(archive)
        }
        if isDownloadPage {
            refresh()
        }
    }

}
