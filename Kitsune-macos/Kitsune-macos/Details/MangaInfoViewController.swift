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
    @IBOutlet var bookmarkButton: NSButton!
    @IBOutlet var downloadButton: DownloadButton!
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
                self.updateContent()
                self.updateChapterList()
                self.toggleBookmarkButton()
                self.linkButton?.isEnabled = (self.manga != nil)
                self.downloadButton?.isEnabled = (self.manga != nil)
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

    override func handleKeyDown(with event: NSEvent) -> Bool {
        // Make sure an item is selected, otherwise don't handle the event
        guard tableView.selectedRow != -1 else {
            return false
        }

        // Check if "option" is being pressed
        let optionModifier: Bool
        if event.modifierFlags.intersection(.option) == NSEvent.ModifierFlags.init(rawValue: 0) {
            optionModifier = false
        } else {
            optionModifier = true
        }

        switch event.keyCode {
        case 0x24, 0x4C:
            // Return / Enter
            guard !optionModifier else {
                break
            }
            goNext()
            return true
        case 0x7D:
            // Down arrow
            let newRow = optionModifier ? chapters.count - 1 : tableView.selectedRow + 1
            select(row: newRow)
            return true
        case 0x7E:
            // Up arrow
            let newRow = optionModifier ? 0 : tableView.selectedRow - 1
            select(row: newRow)
            return true
        default:
            break
        }
        return false
    }

    private func select(row: Int) {
        guard row >= 0, row < chapters.count else {
            return
        }
        tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        tableView.scrollRowToVisible(row)
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

    func toggleBookmarkButton() {
        switch manga?.readingStatus {
        case .unfollowed, .all, .none:
            bookmarkButton.image = NSImage(named: "BookmarkEmpty")
        default:
            bookmarkButton.image = NSImage(named: "Bookmark")
        }
        bookmarkButton?.isHidden = (self.manga?.readingStatus == nil)
    }

    override func didBecomeContentController() {
        super.didBecomeContentController()
        configureToolbar()
    }

    override func popOnUnload() -> Int {
        // Prevent moving back to reader after leaving this view
        guard let history = pageController?.arrangedObjects.count else {
            return super.popOnUnload()
        }
        return max(0, history - 2)
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
        readerViewController.mangaProvider = mangaProvider
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

    @IBAction func openInBrowser(_ sender: NSButton) {
        guard let mangaId = manga?.mangaId else {
            return
        }
        let url = MDPath.mangaDetails(mangaId: mangaId, mangaTitle: manga?.title)
        NSWorkspace.shared.open(url)
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
