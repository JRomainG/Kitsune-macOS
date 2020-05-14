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
    @IBOutlet var loadingIndicator: NSProgressIndicator!
    @IBOutlet var errorLabel: NSTextField!
    private var monitor: Any?

    var paginationEnabled = false {
        didSet {
            configureFooter()
        }
    }
    var currentPage: Int = 0 {
        didSet {
            updatePagePopupButtonItem()
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
        loadingIndicator.isDisplayedWhenStopped = false
        loadingIndicator.stopAnimation(nil)
        errorLabel.isHidden = true

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
    }

    override func didBecomeContentController() {
        configureToolbar()

        // Catch key events to skip pages
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (event) -> NSEvent? in
            if self.handleKeyDown(with: event) {
                return nil
            }
            return event
        }
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

    override func canScrollToNavigate() -> Bool {
        return false
    }

    func handleKeyDown(with event: NSEvent) -> Bool {
        // Don't override shortcut to skip chapter
        guard event.modifierFlags.intersection(.command) == NSEvent.ModifierFlags.init(rawValue: 0) else {
            return false
        }

        switch event.keyCode {
        case 0x7B:
            // Left arrow
            paginationEnabled ? pageDown(nil) : contentMoveUp()
            return true
        case 0x7C:
            // Right arrow
            paginationEnabled ? pageUp(nil) : contentMoveDown()
            return true
        case 0x7D:
            // Down arrow
            paginationEnabled ? contentMoveDown() : pageUp(nil)
            return true
        case 0x7E:
            // Up arrow
            paginationEnabled ? contentMoveUp() : pageDown(nil)
            return true
        default:
            break
        }
        return false
    }

    override func pageControllerdidTransition(to controller: PageContentViewController) {
        if let eventMonitor = monitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }

    @objc func goBack() {
        pageController?.navigateBack(nil)
    }

    @objc func refresh() {
        var resetChapter = chapter
        resetChapter?.pages = nil
        chapter = resetChapter
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

        pagePopupButton.removeAllItems()
        let pageCount = chapter?.pages?.count ?? 0
        for index in 0..<(pageCount) {
            pagePopupButton.addItem(withTitle: "\(index + 1) / \(pageCount)")
        }
        pagePopupButton.isHidden = !paginationEnabled
        updatePagePopupButtonItem()
    }

    func updatePagePopupButtonItem() {
        pagePopupButton.selectItem(at: currentPage)
    }

    @IBAction func selectPage(_ sender: Any) {
        scroll(to: pagePopupButton.indexOfSelectedItem)
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
            loadingIndicator.startAnimation(nil)
            errorLabel.isHidden = true
            chapterProvider.getChapterInfo { (chapter, error) in
                guard let newChapter = chapter else {
                    return
                }
                DispatchQueue.main.async {
                    if let displayError = error {
                        self.errorLabel.isHidden = false
                        self.errorLabel.stringValue = String(describing: displayError)
                    }
                    self.loadingIndicator.stopAnimation(nil)
                    self.chapter = newChapter
                }
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
