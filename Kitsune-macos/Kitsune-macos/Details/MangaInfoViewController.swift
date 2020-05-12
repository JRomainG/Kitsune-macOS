//
//  MangaInfoViewController.swift
//  Kitsune
//
//  Created by Jean-Romain on 10/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import MangaDexLib

class MangaInfoViewController: PageContentViewController {

    @IBOutlet var imageView: NSImageView!
    @IBOutlet var bookmarkImageView: NSImageView!
    @IBOutlet var titleLabel: NSTextField!
    @IBOutlet var authorLabel: NSTextField!
    @IBOutlet var formatLabel: NSTextField!
    @IBOutlet var contentLabel: NSTextField!
    @IBOutlet var genreLabel: NSTextField!
    @IBOutlet var themeLabel: NSTextField!
    @IBOutlet var statusLabel: NSTextField!
    @IBOutlet var descriptionTextView: NSTextView!
    @IBOutlet var linkButton: NSButton!
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var detailLoadingIndicator: NSProgressIndicator!
    @IBOutlet var chaptersLoadingIndicator: NSProgressIndicator!

    var mangaProvider: MangaProvider?

    var manga: MDManga? {
        didSet {
            DispatchQueue.main.async {
                self.linkButton?.isEnabled = (self.manga != nil)
                let bookmarked = self.manga?.readingStatus != .unfollowed && self.manga?.readingStatus != nil
                self.bookmarkImageView?.isHidden = !bookmarked
                self.updateContent()
                self.updateChapterList()
            }
        }
    }

    var chapters: [MDChapter] = []

    lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "Manga details download queue"
        queue.maxConcurrentOperationCount = 2
        return queue
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        detailLoadingIndicator.isHidden = true
        chaptersLoadingIndicator.isHidden = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.doubleAction = #selector(goNext)
    }

    @IBAction func openInBrowser(_ sender: NSButton) {
        guard let mangaId = manga?.mangaId else {
            return
        }
        let url = MDPath.mangaDetails(mangaId: mangaId, mangaTitle: manga?.title)
        NSWorkspace.shared.open(url)
    }

    @objc private func updateContent() {
        downloadDetails()
        downloadInfo()
        toggleLoadingIndicator()

        titleLabel.stringValue = manga?.title ?? "-"
        descriptionTextView.string = manga?.description ?? ""
        authorLabel.stringValue = manga?.displayAuthor ?? "-"
        statusLabel.stringValue = "Pub. status: \(manga?.displayStatus ?? "-")"
        contentLabel.stringValue = "Content: \(manga?.displayContents ?? "-")"
        formatLabel.stringValue = "Format: \(manga?.displayFormats ?? "-")"
        genreLabel.stringValue = "Genre: \(manga?.displayGenres ?? "-")"
        themeLabel.stringValue = "Theme: \(manga?.displayThemes ?? "-")"

        let placeholder = NSImage(named: "CoverPlaceholder")
        imageView.image = placeholder

        if let url = manga?.getCoverUrl(size: .large) {
            imageView.sd_setImage(with: url,
                                  placeholderImage: placeholder,
                                  options: .decodeFirstFrameOnly,
                                  completed: nil)
        }

        self.tableView.reloadData()
    }

    func updateChapterList() {
        chapters = manga?.chapters ?? []
        chapters = chapters.filter { (chapter) -> Bool in
            return chapter.getOriginalLang() == .english
        }.sorted { (first, second) -> Bool in
            // Sort by volume, chapter, and then default to release date
            if let firstVolume = Float(first.volume ?? ""),
                let secondVolume = Float(second.volume ?? ""),
                firstVolume != secondVolume {
                return firstVolume > secondVolume
            }
            if let firstChapter = Float(first.chapter ?? ""),
                let secondChapter = Float(second.chapter ?? ""),
                firstChapter != secondChapter {
                return firstChapter > secondChapter
            }
            guard let firstReleaseDate = first.timestamp else {
                return false
            }
            guard let secondReleaseDate = second.timestamp else {
                return true
            }
            return firstReleaseDate > secondReleaseDate
        }
        self.tableView.deselectAll(nil)
        self.tableView.reloadData()
    }

    func toggleLoadingIndicator() {
        if shouldDownloadInfo() {
            detailLoadingIndicator?.startAnimation(nil)
            detailLoadingIndicator?.isHidden = false
        } else {
            detailLoadingIndicator.isHidden = true
            detailLoadingIndicator.stopAnimation(nil)
        }

        if shouldDownloadDetails() {
            // We need manga details to know which chapters are read
            chaptersLoadingIndicator?.startAnimation(nil)
            chaptersLoadingIndicator?.isHidden = false
        } else {
            chaptersLoadingIndicator.isHidden = true
            chaptersLoadingIndicator.stopAnimation(nil)
        }
    }

    func shouldDownloadDetails() -> Bool {
        guard mangaProvider?.api.isLoggedIn() == true else {
            return false
        }
        return manga?.readingStatus == nil
    }

    func shouldDownloadInfo() -> Bool {
        return manga?.description == nil
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

    override func didBecomeContentController() {
        configureToolbar()
    }

    override func canNavigateForward() -> Bool {
        return tableView.selectedRow != -1
    }

    override func pageControllerWillTransition(to controller: PageContentViewController) {
        guard tableView.selectedRow != -1,
            let readerViewController = controller as? ChapterReaderViewController else {
            return
        }
        let chapter = chapters[tableView.selectedRow]
        readerViewController.chapter = chapter
        readerViewController.manga = manga
    }

    func configureToolbar() {
        ToolbarManager.accountButton(in: view)?.isHidden = true
        ToolbarManager.sortButton(in: view)?.isHidden = true
        ToolbarManager.refreshButton(in: view)?.isHidden = false
        ToolbarManager.segmentedControl(in: view)?.isHidden = true
        ToolbarManager.searchBar(in: view)?.isHidden = true
        ToolbarManager.previousButton(in: view)?.isHidden = false
        ToolbarManager.previousButton(in: view)?.isEnabled = true

        if let previousButton = ToolbarManager.previousButton(in: view) {
            previousButton.target = self
            previousButton.action = #selector(goBack)
        }
        if let refreshButton = ToolbarManager.refreshButton(in: view) {
            refreshButton.target = self
            refreshButton.action = #selector(refresh)
        }
    }

    @objc func goBack() {
        pageController?.navigateBack(nil)
    }

    @objc func goNext() {
        pageController?.navigateForward(nil)
    }

    @objc func refresh() {
        tableView.scroll(.zero)
        var resetManga = manga
        resetManga?.description = nil
        resetManga?.chapters = nil
        resetManga?.currentVolume = nil
        resetManga?.currentChapter = nil
        resetManga?.artist = nil
        resetManga?.author = nil
        manga = resetManga
        tableView.reloadData()
    }

}

extension MangaInfoViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        guard !shouldDownloadDetails() else {
            return 0
        }
        return chapters.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let chapter = chapters[row]
        switch tableColumn {
        case tableView.tableColumns[0]:
            return chapter.displayTitle
        case tableView.tableColumns[1]:
            return chapter.releaseDate
        default:
            return chapter.groupName ?? "-"
        }
    }

}

extension MangaInfoViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, row: Int) {
        guard let textCell = cell as? NSTextFieldCell else {
            return
        }
        let chapter = chapters[row]
        textCell.isEnabled = !chapter.isRead(for: manga)
    }

}
