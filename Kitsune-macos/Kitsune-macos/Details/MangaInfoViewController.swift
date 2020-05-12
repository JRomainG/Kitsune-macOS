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
    @IBOutlet var titleLabel: NSTextField!
    @IBOutlet var authorLabel: NSTextField!
    @IBOutlet var genreLabel: NSTextField!
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
                self.updateContent()

                if self.manga?.mangaId != self.mangaInfo?.mangaId {
                    self.mangaInfo = nil
                }
            }
        }
    }

    var mangaInfo: MDManga? {
        didSet {
            DispatchQueue.main.async {
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

        let authorContent: String
        if let author = mangaInfo?.author,
            let artist = mangaInfo?.artist,
            author != artist {
            authorContent = "\(author), \(artist)"
        } else if let author = mangaInfo?.author {
            authorContent = author
        } else if let artist = mangaInfo?.artist {
           authorContent = artist
        } else {
            authorContent = "-"
        }
        authorLabel.stringValue = authorContent

        let tags = mangaInfo?.tags?.map({ String(describing: $0) }).joined(separator: ", ") ?? "-"
        genreLabel.stringValue = "Tags: \(tags)"

        let publicationStatus: String
        if let status = mangaInfo?.publicationStatus {
            publicationStatus = String(describing: status)
        } else {
            publicationStatus = "-"
        }
        statusLabel.stringValue = "Pub. status: \(publicationStatus)"

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
        chapters = mangaInfo?.chapters ?? []
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
        if manga?.description == nil {
            // Some information is still loading
            detailLoadingIndicator?.startAnimation(nil)
            detailLoadingIndicator?.isHidden = false
        } else {
            detailLoadingIndicator.isHidden = true
            detailLoadingIndicator.stopAnimation(nil)
        }

        if mangaInfo == nil || manga?.description == nil {
            // We need manga details to know which chapters are read
            chaptersLoadingIndicator?.startAnimation(nil)
            chaptersLoadingIndicator?.isHidden = false
        } else {
            chaptersLoadingIndicator.isHidden = true
            chaptersLoadingIndicator.stopAnimation(nil)
        }
    }

    func downloadDetails() {
        guard manga?.description == nil else {
            return
        }

        let operation = MangaDetailOperation()
        operation.manga = manga
        operation.provider = mangaProvider
        operation.completionBlock = {
            guard !operation.isCancelled, let manga = operation.manga else {
                return
            }
            if self.manga == nil {
                self.manga = manga
            } else {
                self.manga = MangaProvider.merged(first: self.manga!, second: manga)
            }
        }
        operationQueue.addOperation(operation)
    }

    func downloadInfo() {
        guard mangaInfo == nil else {
            return
        }

        let operation = MangaInfoOperation()
        operation.manga = manga
        operation.provider = mangaProvider
        operation.completionBlock = {
            guard !operation.isCancelled else {
                return
            }
            self.mangaInfo = operation.manga
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
        readerViewController.mangaInfo = mangaInfo
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
        mangaInfo = nil
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
        guard manga?.description != nil else {
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

    func tableView(_ tableView: NSTableView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, row: Int) {
        guard let textCell = cell as? NSTextFieldCell else {
            return
        }
        let chapter = chapters[row]
        if chapter.isRead(for: manga) {
            textCell.textColor = .placeholderTextColor
        } else {
            textCell.textColor = .textColor
        }
    }

}

extension MangaInfoViewController: NSTableViewDelegate {

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard tableView.selectedRow > -1 else {
            return
        }
        print("tableViewSelectionDidChange")
    }

}
