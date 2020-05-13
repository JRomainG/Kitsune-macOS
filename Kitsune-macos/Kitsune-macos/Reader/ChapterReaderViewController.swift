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

    var paginationEnabled = false
    var currentPage: Int = 0
    private var documentViewConstraint: NSLayoutConstraint?

    var imageViews: [NSImageView] = []

    lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "Chapter info download queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    var mangaProvider: MangaProvider?
    var manga: MDManga? {
        didSet {
            DispatchQueue.main.async {
                self.configureFooter()
            }
        }
    }
    var chapter: MDChapter? {
        didSet {
            DispatchQueue.main.async {
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

    @objc func goBack() {
        pageController?.navigateBack(nil)
    }

    @IBAction func previousChapter(_ sender: Any) {
        guard let chapter = self.chapter, let previous = getPreviousChapter() else {
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
        guard let chapter = self.chapter, let next = getNextChapter() else {
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

    func getChapters() -> [MDChapter]? {
        guard var chapters = manga?.chapters, let currentChapter = chapter else {
            return nil
        }
        chapters = chapters.filter({ (chapter) -> Bool in
            return chapter.getOriginalLang() == currentChapter.getOriginalLang()
        })
        return chapters.sorted { (first, second) -> Bool in
            return first.comesBefore(chapter: second)
        }
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

    func getPreviousChapter() -> MDChapter? {
        guard let currentChapter = chapter, let chapters = getChapters() else {
            return nil
        }

        // Find the chapters that come before this one
        let previousChapters = chapters.filter { (chapter) -> Bool in
            return chapter.comesBefore(chapter: currentChapter)
        }
        let lastChapter = previousChapters.last

        // Try to get the chapter with the same group
        let lastGroupChapter = previousChapters.last(where: { (chapter) -> Bool in
            return chapter.groupId == currentChapter.groupId
        })

        // If the group did release the chapter that is asked for, return that one
        if lastGroupChapter != nil
            && lastGroupChapter?.volume == lastChapter?.volume
            && lastGroupChapter?.chapter == lastChapter?.chapter {
            return lastGroupChapter
        }

        // Otherwise, return the one we found
        return lastChapter
    }

    func getNextChapter() -> MDChapter? {
        guard let currentChapter = chapter, let chapters = getChapters() else {
            return nil
        }

        // Find the chapters that come after this one
        let nextChapters = chapters.filter { (chapter) -> Bool in
            return currentChapter.comesBefore(chapter: chapter)
        }
        let nextChapter = nextChapters.first

        // Try to get the chapter with the same group
        let nextGroupChapter = nextChapters.first(where: { (chapter) -> Bool in
            return chapter.groupId == currentChapter.groupId
        })

        // If the group did release the chapter that is asked for, return that one
        if nextGroupChapter != nil
            && nextGroupChapter?.volume == nextChapter?.volume
            && nextGroupChapter?.chapter == nextChapter?.chapter {
            return nextGroupChapter
        }

        // Otherwise, return the one we found
        return nextChapter
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
        scrollView.scroll(.zero)
        for imageView in imageViews {
            imageView.removeFromSuperview()
        }
        imageViews.removeAll()

        paginationEnabled = (chapter?.longStrip != 1)
        if paginationEnabled {
            scrollView.horizontalScrollElasticity = .automatic
            scrollView.verticalScrollElasticity = .none
        } else {
            scrollView.horizontalScrollElasticity = .none
            scrollView.verticalScrollElasticity = .automatic
        }

        downloadInfo()
        for url in chapter?.getPageUrls() ?? [] {
            let imageView: NSImageView
            if paginationEnabled {
                imageView = newHorizontalContentImageView()
            } else {
                imageView = newVerticalContentImageView()
            }
            imageViews.append(imageView)
            imageView.sd_setImage(with: url,
                                  placeholderImage: nil,
                                  options: .decodeFirstFrameOnly,
                                  completed: nil)
        }
    }

    func shouldDownloadInfo() -> Bool {
        return chapter?.pages == nil
    }

    func downloadInfo() {
        guard shouldDownloadInfo() else {
            return
        }

        let operation = ChapterInfoOperation()
        operation.manga = manga
        operation.provider = mangaProvider
        operation.chapter = chapter
        operation.completionBlock = {
            guard !operation.isCancelled,
                let chapter = operation.chapter else {
                    return
            }
            self.chapter = chapter
        }
        operationQueue.addOperation(operation)
    }

}

extension ChapterReaderViewController {

    func scroll(to page: Int, animated: Bool = true) {
        guard paginationEnabled else {
            return
        }
        let currentOffset = scrollView.documentVisibleRect

        // We only want to trigger a scroll if necessary:
        // when zoomed-in, it's sometimes unnecessary to scroll the view
        let overflow = scrollView.documentVisibleRect.origin.x / scrollView.frame.width - CGFloat(page)
        let pageOffset: NSPoint
        if overflow > 1 - 1 / scrollView.magnification {
            // The user scrolled a bit outside this page, but not enough to change,
            // so scroll back to the end of the previous page
            let inpageOffset = scrollView.frame.width * (1 - 1 / scrollView.magnification)
            pageOffset = NSPoint(x: scrollView.frame.width * CGFloat(page) + inpageOffset,
                                 y: currentOffset.origin.y)
        } else if overflow < 0 {
            // The user either scrolled enough to go to the next page, or not enough to
            // go to the previous page, so just scroll to the begining of the page
            pageOffset = NSPoint(x: scrollView.frame.width * CGFloat(page),
                                 y: currentOffset.origin.y)
        } else {
            // Don't scroll
            pageOffset = scrollView.documentVisibleRect.origin
        }

        let context = NSAnimationContext.current
        context.duration = animated ? 0.25 : 0
        context.timingFunction = CAMediaTimingFunction(name: .easeOut)
        context.allowsImplicitAnimation = true
        scrollView.contentView.scroll(pageOffset)
        currentPage = page
    }

    @objc func scrollViewDidEndScrolling(notification: NSNotification?) {
        guard paginationEnabled else {
            return
        }
        let relativeOffset = scrollView.documentVisibleRect.origin.x / scrollView.frame.width
        var page = trunc(relativeOffset)
        let pageOffset = relativeOffset - page
        if pageOffset > 1 - 1 / (2 * scrollView.magnification) {
            // The user scrolled enough in the next page to consider that they wanted to change
            page += 1
        }
        scroll(to: Int(page))
    }

    @objc func scrollViewDidFinishZooming(notification: NSNotification?) {
        scrollView.horizontalPageScroll = view.frame.size.width * scrollView.magnification
        scrollView.pageScroll = view.frame.size.height * scrollView.magnification
        scroll(to: currentPage)
    }

    @objc func scrollViewDidResize(notification: NSNotification?) {
        scroll(to: currentPage, animated: false)
        scrollView.horizontalPageScroll = view.frame.size.width * scrollView.magnification
        scrollView.pageScroll = view.frame.size.height * scrollView.magnification
    }

    func newHorizontalContentImageView() -> NSImageView {
        let imageView = newImageView()
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        if let previous = imageViews.last {
            // The view should be right after the previous page
            var frame = previous.frame
            frame.origin.x += previous.frame.size.width
            imageView.frame = frame
            imageView.leadingAnchor.constraint(equalTo: previous.trailingAnchor).isActive = true
        } else {
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor).isActive = true
            scrollView.documentView?.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
            scrollView.documentView?.topAnchor.constraint(equalTo: imageView.topAnchor).isActive = true
            scrollView.documentView?.bottomAnchor.constraint(equalTo: imageView.bottomAnchor).isActive = true
        }

        // The view should take the whole frame
        imageView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: scrollView.contentView.heightAnchor).isActive = true

        // The document view should resize to allow scrolling
        let origin = scrollView.documentView?.frame.origin ?? scrollView.frame.origin
        let size = NSSize(width: imageView.frame.origin.x + imageView.frame.size.width,
                          height: imageView.frame.origin.y + imageView.frame.size.height)
        scrollView.documentView?.frame = NSRect(origin: origin, size: size)

        if documentViewConstraint != nil {
            documentViewConstraint?.isActive = false
            scrollView.documentView?.removeConstraint(documentViewConstraint!)
        }
        documentViewConstraint = scrollView.documentView?.trailingAnchor.constraint(equalTo: imageView.trailingAnchor)
        documentViewConstraint?.isActive = true

        return imageView
    }

    func newVerticalContentImageView() -> NSImageView {
        let imageView = newImageView()

        if let previous = imageViews.last {
            // The view should be right under the previous page
            var frame = previous.frame
            frame.origin.y += previous.frame.size.height
            imageView.frame = frame
            imageView.topAnchor.constraint(equalTo: previous.bottomAnchor).isActive = true
        } else {
            imageView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor).isActive = true
            scrollView.documentView?.topAnchor.constraint(equalTo: imageView.topAnchor).isActive = true
            scrollView.documentView?.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
            scrollView.documentView?.trailingAnchor.constraint(equalTo: imageView.trailingAnchor).isActive = true
        }

        // The view should take the whole width
        imageView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor).isActive = true

        // The document view should resize to allow scrolling
        let origin = scrollView.documentView?.frame.origin ?? scrollView.frame.origin
        let size = NSSize(width: imageView.frame.origin.x + imageView.frame.size.width,
                          height: imageView.frame.origin.y + imageView.frame.size.height)
        scrollView.documentView?.frame = NSRect(origin: origin, size: size)

        if documentViewConstraint != nil {
            documentViewConstraint?.isActive = false
            scrollView.documentView?.removeConstraint(documentViewConstraint!)
        }
        documentViewConstraint = scrollView.documentView?.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
        documentViewConstraint?.isActive = true

        return imageView
    }

    func newImageView() -> NSImageView {
        let imageView = NSImageView(frame: scrollView.bounds)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.autoresizingMask = [.height, .width]
        imageView.imageScaling = .scaleProportionallyDown
        scrollView.documentView?.addSubview(imageView)
        return imageView
    }

}
