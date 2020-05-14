//
//  ChapterReaderViewController+Pagination.swift
//  Kitsune
//
//  Created by Jean-Romain on 13/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa

extension ChapterReaderViewController {

    override func pageUp(_ sender: Any?) {
        if paginationEnabled {
            DispatchQueue.main.async {
                self.scroll(to: self.currentPage + 1, hugContent: true)
            }
        } else {
            var offset = getOffset()
            offset.y -= scrollView.frame.size.height / scrollView.magnification
            DispatchQueue.main.async {
                self.scroll(to: offset)
            }
        }
    }

    override func pageDown(_ sender: Any?) {
        if paginationEnabled {
            DispatchQueue.main.async {
                self.scroll(to: self.currentPage - 1, hugContent: true)
            }
        } else {
            var offset = getOffset()
            offset.y += scrollView.frame.size.height / scrollView.magnification
            DispatchQueue.main.async {
                self.scroll(to: offset)
            }
        }
    }

    /// Move in the other direction than with pageUp / pageDown to reveal more content
    func contentMoveUp() {
        if paginationEnabled {
            var offset = getOffset()
            offset.y += scrollView.frame.size.height / scrollView.magnification
            DispatchQueue.main.async {
                self.scroll(to: offset)
            }
        } else {
            var offset = getOffset()
            offset.x -= scrollView.frame.size.width / scrollView.magnification
            DispatchQueue.main.async {
                self.scroll(to: offset)
            }
        }
    }

    /// Move in the other direction than with pageUp / pageDown to reveal more content
    func contentMoveDown() {
        if paginationEnabled {
            var offset = getOffset()
            offset.y -= scrollView.frame.size.height / scrollView.magnification
            DispatchQueue.main.async {
                self.scroll(to: offset)
            }
        } else {
            var offset = getOffset()
            offset.x += scrollView.frame.size.width / scrollView.magnification
            DispatchQueue.main.async {
                self.scroll(to: offset)
            }
        }
    }

    private func scroll(to offset: NSPoint, animated: Bool = true) {
        NSAnimationContext.runAnimationGroup { (context) in
            context.duration = animated ? 0.25 : 0
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            context.allowsImplicitAnimation = true
            self.scrollView.contentView.scroll(offset)
        }
    }

    func scroll(to page: Int, animated: Bool = true, hugContent: Bool = false) {
        guard page >= 0, page < chapter?.pages?.count ?? 0 else {
            return
        }

        let currentOffset = getOffset()
        var pageOffset: NSPoint
        if paginationEnabled {
            // We only want to trigger a scroll if necessary:
            // when zoomed-in, it's sometimes unnecessary to scroll the view
            let overflow = currentOffset.x / scrollView.frame.width - CGFloat(page)
            if overflow > 1 - 1 / scrollView.magnification {
                // The user scrolled a bit outside this page, but not enough to change,
                // so scroll back to the end of the previous page
                let inpageOffset = scrollView.frame.width * (1 - 1 / scrollView.magnification)
                pageOffset = NSPoint(x: scrollView.frame.width * CGFloat(page) + inpageOffset,
                                     y: scrollView.frame.height)

                // Try to hide as much white as possible when moving back
                if hugContent {
                    let imageView = imageViews[page]
                    let additionalOffset = imageView.getHorizontalMargin() / 2
                    let maxOffset = getPageMaxOffset(for: imageView)
                    pageOffset.x -= max(0, min(maxOffset, additionalOffset))
                }
            } else if overflow < 0 {
                // The user either scrolled enough to go to the next page, or not enough to
                // go to the previous page, so just scroll to the begining of the page
                pageOffset = NSPoint(x: scrollView.frame.width * CGFloat(page),
                                     y: scrollView.frame.height)

                // Try to hide as much white as possible when moving forward
                if hugContent {
                    let imageView = imageViews[page]
                    let additionalOffset = imageView.getHorizontalMargin() / 2
                    let maxOffset = getPageMaxOffset(for: imageView)
                    pageOffset.x += max(0, min(maxOffset, additionalOffset))
                }
            } else {
                // Don't scroll
                pageOffset = currentOffset
            }
        } else {
            pageOffset = NSPoint(x: currentOffset.x,
                                 y: scrollView.frame.height * CGFloat(page))
        }

        scroll(to: pageOffset, animated: animated)
        currentPage = page
    }

    func getOffset() -> NSPoint {
        let documentFrame = scrollView.documentView?.frame ?? .zero
        var offset = scrollView.documentVisibleRect.origin
        offset.y -= documentFrame.height - scrollView.frame.size.height
        return offset
    }

    func getPageMaxOffset(for imageView: ChapterPageView) -> CGFloat {
        // We don't want to scroll any further than where the image is centered
        let maxOffset = scrollView.frame.size.width - 0.75 * imageView.getHorizontalMargin()

        // We have to take the zoom into account
        return (1 - 1 / scrollView.magnification) * maxOffset

    }

    @objc func scrollViewDidEndScrolling(notification: NSNotification?) {
        guard paginationEnabled else {
            return
        }
        let relativeOffset = getOffset().x / scrollView.frame.width
        var page = trunc(relativeOffset)
        let pageOffset = relativeOffset - page
        if pageOffset > 1 - 1 / (2 * scrollView.magnification) {
            // The user scrolled enough in the next page to consider that they wanted to change
            page += 1
        }
        scroll(to: Int(page))
    }

    @objc func scrollViewDidFinishZooming(notification: NSNotification?) {
        guard paginationEnabled else {
            return
        }
        scroll(to: currentPage)
    }

    @objc func scrollViewDidResize(notification: NSNotification?) {
        guard paginationEnabled else {
            return
        }
        scroll(to: currentPage, animated: false)
        scrollView.horizontalPageScroll = view.frame.size.width
        scrollView.pageScroll = view.frame.size.height
    }

    func newHorizontalContentImageView() -> ChapterPageView {
        let imageView = newImageView()

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

    func newVerticalContentImageView() -> ChapterPageView {
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

    func newImageView() -> ChapterPageView {
        let imageView = ChapterPageView(frame: scrollView.bounds)
        imageView.delegate = self
        scrollView.documentView?.addSubview(imageView)
        return imageView
    }

    func removeImageViews() {
        if let constraints = scrollView.documentView?.constraints {
            scrollView.documentView?.removeConstraints(constraints)
        }
        for imageView in imageViews {
            imageView.cancelOperations()
            imageView.removeFromSuperview()
        }
        scrollView.documentView?.frame = .zero
        imageViews.removeAll()

        scrollView.setMagnification(1, centeredAt: .zero)
        scroll(to: 0, animated: false)
    }

}

extension ChapterReaderViewController: ChapterPageDelegate {
}
