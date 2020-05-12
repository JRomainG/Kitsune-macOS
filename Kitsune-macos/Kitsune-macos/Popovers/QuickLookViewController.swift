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
    @IBOutlet var linkButton: NSButton!
    @IBOutlet var descriptionTextView: NSTextView!
    @IBOutlet var loadingIndicator: NSProgressIndicator!

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
            DispatchQueue.main.async {
                self.linkButton?.isEnabled = (self.manga != nil)
                self.updateContent(cancelPending: true)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    @IBAction func openInBrowser(_ sender: NSButton) {
        guard let mangaId = manga?.mangaId else {
            return
        }
        let url = MDPath.mangaDetails(mangaId: mangaId, mangaTitle: manga?.title)
        NSWorkspace.shared.open(url)
    }

    func open(in viewController: NSViewController, from view: NSView) {
        guard view.window != nil else {
            return
        }
        isBeingPresented = true
        popover.contentViewController = self
        popover.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        updateContent()
    }

    func close() {
        popover.close()
        isBeingPresented = false
        loadingIndicator?.stopAnimation(nil)
        operationQueue.cancelAllOperations()
    }

    @objc private func updateContent(cancelPending: Bool = false) {
        // If the displayed manga changed, stop loading
        if cancelPending {
            operationQueue.cancelAllOperations()
        }

        // Ignore these changes if the view is hidden
        guard isBeingPresented else {
            return
        }

        if manga?.description == nil {
            // Details haven't been downloaded
            loadingIndicator?.startAnimation(nil)
            loadingIndicator?.isHidden = false

            let operation = MangaDetailOperation()
            operation.manga = manga
            operation.provider = mangaProvider
            operation.delay = 0.25
            operation.completionBlock = {
                guard !operation.isCancelled, let manga = operation.manga else {
                    return
                }
                DispatchQueue.main.async {
                    if self.manga == nil {
                        self.manga = manga
                    } else {
                        self.manga = MangaProvider.merged(first: self.manga!, second: manga)
                    }
                }
            }
            operationQueue.addOperation(operation)
        } else {
            loadingIndicator.isHidden = true
            loadingIndicator.stopAnimation(nil)
        }

        titleLabel.stringValue = manga?.title ?? "-"
        descriptionTextView.string = manga?.description ?? ""

        let placeholder = NSImage(named: "CoverPlaceholder")
        imageView.image = placeholder

        if let url = manga?.getCoverUrl(size: .large) {
            imageView.sd_setImage(with: url,
                                  placeholderImage: placeholder,
                                  options: .decodeFirstFrameOnly,
                                  completed: nil)
        }
    }

}
