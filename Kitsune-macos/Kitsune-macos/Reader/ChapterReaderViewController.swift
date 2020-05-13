//
//  ChapterReaderViewController.swift
//  Kitsune
//
//  Created by Jean-Romain on 12/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import MangaDexLib

class ChapterReaderViewController: PageContentViewController {

    @IBOutlet var previousButton: NSButton!
    @IBOutlet var nextButton: NSButton!
    @IBOutlet var titleLabel: NSTextField!
    @IBOutlet var pagePopupButton: NSPopUpButton!
    @IBOutlet var scrollView: NSScrollView!

    var paginationEnabled = false {
        didSet {
            configureFooter()
        }
    }
    var currentPage: Int = 0 {
        didSet {
            configureFooter()
        }
    }
    var documentViewConstraint: NSLayoutConstraint?
    var imageViews: [ChapterPageView] = []

    var mangaProvider: MangaProvider? {
        didSet {
            chapterProvider.mangaProvider = mangaProvider
        }
    }
    var chapterProvider = ChapterProvider()
    var manga: MDManga? {
        didSet {
            DispatchQueue.main.async {
                self.chapterProvider.manga = self.manga
                self.configureFooter()
            }
        }
    }
    var chapter: MDChapter? {
        didSet {
            DispatchQueue.main.async {
                self.chapterProvider.chapter = self.chapter
                self.configureFooter()
                self.setupPages()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        scrollView.borderType = .noBorder
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 1
        scrollView.maxMagnification = 4
        scrollView.contentView.autoresizingMask = [.height, .width]
        scrollView.documentView?.autoresizingMask = [.height, .width]
        scrollView.documentView?.translatesAutoresizingMaskIntoConstraints = false
        scrollView.postsFrameChangedNotifications = true
        scrollView.postsBoundsChangedNotifications = false

        NotificationCenter.default.addObserver(self,
                                       selector: #selector(scrollViewDidEndScrolling(notification:)),
                                       name: NSScrollView.didEndLiveScrollNotification,
                                       object: scrollView)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(scrollViewDidFinishZooming(notification:)),
                                               name: NSScrollView.didEndLiveMagnifyNotification,
                                               object: scrollView)

        NotificationCenter.default.addObserver(self,
                                       selector: #selector(scrollViewDidResize(notification:)),
                                       name: NSView.frameDidChangeNotification,
                                       object: scrollView)

        // Catch key events to skip pages
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (event) -> NSEvent? in
            if self.handleKeyDown(with: event) {
                return nil
            }
            return event
        }
    }

    override func didBecomeContentController() {
        configureToolbar()
    }

    func configureToolbar() {
        ToolbarManager.accountButton(in: view)?.isHidden = true
        ToolbarManager.sortButton(in: view)?.isHidden = true
        ToolbarManager.refreshButton(in: view)?.isHidden = true
        ToolbarManager.segmentedControl(in: view)?.isHidden = true
        ToolbarManager.searchBar(in: view)?.isHidden = true
        ToolbarManager.previousButton(in: view)?.isHidden = false
        ToolbarManager.previousButton(in: view)?.isEnabled = true

        if let previousButton = ToolbarManager.previousButton(in: view) {
            previousButton.target = self
            previousButton.action = #selector(goBack)
        }
    }

    override func canScrollToNavigate() -> Bool {
        return false
    }

    func handleKeyDown(with event: NSEvent) -> Bool {
        if paginationEnabled {
            switch event.keyCode {
            case 0x7B:
                // Left arrow
                pageDown(nil)
                return true
            case 0x7C:
                // Right arrow
                pageUp(nil)
                return true
            case 0x7D:
                // Down arrow
                contentMoveDown()
                return true
            case 0x7E:
                // Up arrow
                contentMoveUp()
                return true
            default:
                break
            }
        } else {
            switch event.keyCode {
            case 0x7B:
                // Left arrow
                contentMoveUp()
                return true
            case 0x7C:
                // Right arrow
                contentMoveDown()
                return true
            case 0x7D:
                // Down arrow
                pageUp(nil)
                return true
            case 0x7E:
                // Up arrow
                pageDown(nil)
                return true
            default:
                break
            }
        }
        return false
    }

    @objc func goBack() {
        pageController?.navigateBack(nil)
    }

    @IBAction func previousChapter(_ sender: Any) {
        guard let chapter = self.chapter, let previous = chapterProvider.getPreviousChapter() else {
            let alert = NSAlert()
            alert.messageText = "First chapter"
            alert.informativeText = "No previous chapter with the same language was found."
            alert.runModal()
            return
        }
        if chapter.follows(chapter: previous) == false && !ignoreGap(between: chapter, and: previous) {
            return
        }
        self.chapter = previous
    }

    @IBAction func nextChapter(_ sender: Any) {
        guard let chapter = self.chapter, let next = chapterProvider.getNextChapter() else {
            let alert = NSAlert()
            alert.messageText = "Last chapter"
            alert.informativeText = "No next chapter with the same language was found."
            alert.runModal()
            return
        }
        if next.follows(chapter: chapter) == false && !ignoreGap(between: chapter, and: next) {
            return
        }
        self.chapter = next
    }

    func ignoreGap(between first: MDChapter, and second: MDChapter) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Gap detected"
        alert.informativeText = """
        A gap between the two chapters was detected\n
        Current chapter: \(first.displayTitle)\n
        Next chapter: \(second.displayTitle)
        """
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Continue")
        let result = alert.runModal()
        switch result {
        case .alertFirstButtonReturn:
            // Cancel
            return false
        default:
            return true
        }
    }

    func configureFooter() {
        if let mangaTitle = manga?.title, chapter?.title != nil {
            titleLabel.stringValue = "\(mangaTitle) - \(chapter?.displayTitle ?? "")"
        } else if chapter?.title != nil {
            titleLabel.stringValue = chapter?.displayTitle ?? "-"
        } else {
            titleLabel.stringValue = "-"
        }
    }

    func setupPages() {
        removeImageViews()
        chapterProvider.cancelRequests()

        paginationEnabled = (chapter?.longStrip != 1)
        if paginationEnabled {
            scrollView.horizontalScrollElasticity = .automatic
            scrollView.verticalScrollElasticity = .none
        } else {
            scrollView.horizontalScrollElasticity = .none
            scrollView.verticalScrollElasticity = .automatic
        }

        if shouldDownloadInfo() {
            chapterProvider.getChapterInfo { (chapter) in
                guard let newChapter = chapter else {
                    return
                }
                self.chapter = newChapter
            }
        }

        for url in chapter?.getPageUrls() ?? [] {
            let imageView: ChapterPageView
            if paginationEnabled {
                imageView = newHorizontalContentImageView()
            } else {
                imageView = newVerticalContentImageView()
            }
            imageViews.append(imageView)
            imageView.setImage(with: url)
        }
    }

    func shouldDownloadInfo() -> Bool {
        return chapter?.pages == nil
    }

}
