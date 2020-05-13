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

    private var documentViewConstraint: NSLayoutConstraint?

    var imageViews: [NSImageView] = []

    lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "Chapter info download queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    var mangaProvider: MangaProvider?
    var manga: MDManga?
    var chapter: MDChapter? {
        didSet {
            DispatchQueue.main.async {
                self.setupPages()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        scrollView.wantsLayer = true
        scrollView.layer?.backgroundColor = NSColor.systemPink.cgColor
        scrollView.borderType = .noBorder
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 1
        scrollView.maxMagnification = 4
        scrollView.contentView.autoresizingMask = [.height, .width]
        scrollView.documentView?.autoresizingMask = [.height, .width]
        scrollView.documentView?.translatesAutoresizingMaskIntoConstraints = false
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
    }

    @IBAction func nextChapter(_ sender: Any) {
    }

    func setupPages() {
        for imageView in imageViews {
            imageView.removeFromSuperview()
        }
        imageViews.removeAll()

        if chapter?.longStrip == 1 {
            scrollView.horizontalScrollElasticity = .none
            scrollView.verticalScrollElasticity = .automatic
        } else {
            scrollView.horizontalScrollElasticity = .automatic
            scrollView.verticalScrollElasticity = .none
        }

        downloadInfo()
        for url in chapter?.getPageUrls() ?? [] {
            let imageView: NSImageView
            if chapter?.longStrip == 1 {
                imageView = newVerticalContentImageView()
            } else {
                imageView = newHorizontalContentImageView()
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
