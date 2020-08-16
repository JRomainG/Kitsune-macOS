//
//  MangaInfoViewController+Download.swift
//  Kitsune
//
//  Created by Jean-Romain on 15/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import MangaDexLib

extension MangaInfoViewController {

    func shouldDownloadDetails() -> Bool {
        guard mangaProvider?.api.isLoggedIn() == true else {
            return false
        }
        return manga?.readingStatus == nil
    }

    func shouldDownloadInfo() -> Bool {
        return manga?.description == nil
    }

    func shouldDownloadChapters() -> Bool {
        return !shouldDownloadInfo() && !shouldDownloadDetails() && (manga?.chapters == nil)
    }

    func downloadDetails() {
        guard shouldDownloadDetails() else {
            return
        }
        let operation = MangaDetailOperation()
        operation.manga = manga
        operation.provider = mangaProvider
        operation.completionBlock = {
            guard !operation.isCancelled,
                let manga = operation.manga,
                let currentManga = self.manga else {
                return
            }
            self.manga = MangaProvider.merged(first: currentManga, second: manga)
        }
        operationQueue.addOperation(operation)
    }

    func downloadInfo() {
        guard shouldDownloadInfo() else {
            return
        }

        let operation = MangaInfoOperation()
        operation.manga = manga
        operation.provider = mangaProvider
        operation.completionBlock = {
            guard !operation.isCancelled,
                let manga = operation.manga,
                let currentManga = self.manga else {
                return
            }
            self.manga = MangaProvider.merged(first: currentManga, second: manga)
        }
        operationQueue.addOperation(operation)
    }

    func downloadChapters() {
        guard shouldDownloadChapters(), let manga = self.manga else {
            return
        }
        mangaProvider?.getChapters(for: manga, page: 0, completion: { (newManga, _) in
            if newManga != nil {
                self.manga = newManga
            }
        })
    }

    @objc func refresh() {
        tableView.scroll(.zero)
        var resetManga = manga
        resetManga?.description = nil
        resetManga?.chapters = nil
        resetManga?.readingStatus = nil
        resetManga?.publicationStatus = nil
        resetManga?.lastChapter = nil
        resetManga?.currentVolume = nil
        resetManga?.currentChapter = nil
        resetManga?.artist = nil
        resetManga?.author = nil
        manga = resetManga
        tableView.reloadData()
    }

    @IBAction func bookmark(_ sender: Any) {
        guard let readingStatus = manga?.readingStatus,
            let mangaId = manga?.mangaId else {
            return
        }

        let newState: MDReadingStatus
        switch readingStatus {
        case .unfollowed:
            newState = .reading
        default:
            newState = .unfollowed
        }

        mangaProvider?.api.setReadingStatus(mangaId: mangaId, status: newState, completion: { (response) in
            guard response.error == nil else {
                return
            }
            DispatchQueue.main.async {
                self.refresh()
            }
        })
    }

    @IBAction func download(_ sender: Any) {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.addItem(withTitle: "Download selected", action: #selector(downloadSelected), keyEquivalent: "")
        menu.addItem(withTitle: "Download unread", action: #selector(downloadUnread), keyEquivalent: "")
        menu.addItem(withTitle: "Download all", action: #selector(downloadAll), keyEquivalent: "")
        menu.items.first?.isEnabled = !tableView.selectedRowIndexes.isEmpty
        menu.popUp(positioning: nil, at: downloadButton.frame.origin, in: view)
    }

    @objc func downloadSelected() {
        guard !tableView.selectedRowIndexes.isEmpty, let manga = self.manga else {
            return
        }

        var chapters: [MDChapter] = []
        for index in tableView.selectedRowIndexes {
            chapters.append(self.chapters[index])
        }
        DownloadedMangaProvider.shared.download(chapters: chapters, for: manga)
    }

    @objc func downloadUnread() {
        guard let manga = self.manga else {
            return
        }
        let chapters = self.chapters.filter { (chapter) -> Bool in
            return !chapter.isRead(for: manga)
        }
        DownloadedMangaProvider.shared.download(chapters: chapters, for: manga)
    }

    @objc func downloadAll() {
        guard let manga = self.manga else {
            return
        }
        DownloadedMangaProvider.shared.download(chapters: chapters, for: manga)
    }

}
