//
//  QuickLookViewController.swift
//  Kitsune
//
//  Created by Jean-Romain on 08/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import MangaDexLib
import SDWebImage

class QuickLookViewController: NSViewController {

    @IBOutlet var imageView: NSImageView!
    @IBOutlet var titleLabel: NSTextField!
    @IBOutlet var subtitleLabel: NSTextField!
    @IBOutlet var tagsLabel: NSTextField!
    @IBOutlet var descriptionTextView: NSTextView!

    var mangaProvider: MangaProvider?

    private var popover = NSPopover()
    private(set) var isBeingPresented = false
    lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "Manga details download queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    var manga: MDManga? {
        didSet {
            updateContent(cancelPending: true)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    func open(in viewController: NSViewController, from view: NSView) {
        isBeingPresented = true
        popover.contentViewController = self
        popover.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        updateContent()
    }

    func close() {
        popover.close()
        isBeingPresented = false
        operationQueue.cancelAllOperations()
    }

    @objc private func updateContent(cancelPending: Bool = false) {
        // If them displayed manga changed, stop loading
        if cancelPending {
            operationQueue.cancelAllOperations()
        }

        // Ignore these changes if the view is hidden
        guard isBeingPresented else {
            return
        }

        if manga?.description == nil {
            // Details haven't been downloaded
            let operation = MangaDetailDownload()
            operation.manga = manga
            operation.provider = mangaProvider
            operation.completionBlock = {
                guard !operation.isCancelled else {
                    return
                }
                DispatchQueue.main.async {
                    self.manga = operation.manga ?? self.manga
                }
            }
            operationQueue.addOperation(operation)
        }

        titleLabel.stringValue = manga?.title ?? "-"
        subtitleLabel.stringValue = manga?.author ?? "-"
        tagsLabel.stringValue = manga?.tags?.map(String.init).joined(separator: ", ") ?? "-"
        descriptionTextView.string = manga?.description ?? "-"

        let placeholder = NSImage(named: "CoverPlaceholder")
        imageView.image = placeholder

        if let url = manga?.getCoverUrl() {
            imageView.sd_setImage(with: url,
                                  placeholderImage: placeholder,
                                  options: .scaleDownLargeImages,
                                  completed: nil)
        }
    }

}

class MangaDetailDownload: Operation {

    var manga: MDManga?
    var provider: MangaProvider?
    let semaphore = DispatchSemaphore(value: 0)

    override func main() {
        guard let manga = self.manga else {
            return
        }

        if isCancelled {
            return
        }

        // Wait a bit before fetching details so as not to flood
        // This is useful so details aren't fetched if the user is skipping accross manga quickly
        _ = semaphore.wait(timeout: .now() + 0.25)

        if isCancelled {
            return
        }

        provider?.getDetails(for: manga, completion: { (manga) in
            self.manga = manga
            self.semaphore.signal()
        })

        // Wait until download is done
        semaphore.wait()
    }

}
