//
//  ChapterPageView.swift
//  Kitsune
//
//  Created by Jean-Romain on 13/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa

protocol ChapterPageDelegate: AnyObject {

    func didStartLoading(view: ChapterPageView)
    func didFinishLoading(view: ChapterPageView)
    func didFailLoading(view: ChapterPageView, error: Error)

}

extension ChapterPageDelegate {

    func didStartLoading(view: ChapterPageView) {}
    func didFinishLoading(view: ChapterPageView) {}
    func didFailLoading(view: ChapterPageView, error: Error) {}

}

class ChapterPageView: NSImageView {

    var loadingIndicator = NSProgressIndicator()
    var errorLabel = ErrorLabel()
    var reloadButton = LinkButton()
    weak var delegate: ChapterPageDelegate?

    private(set) var url: URL?
    private(set) var isLoading = false {
        didSet {
            if isLoading {
                loadingIndicator.startAnimation(nil)
            } else {
                loadingIndicator.stopAnimation(nil)
            }
        }
    }
    private(set) var error: Error? {
        didSet {
            if error == nil {
                errorLabel.stringValue = ""
                errorLabel.isHidden = true
                reloadButton.isHidden = true
            } else {
                errorLabel.stringValue = String(describing: error)
                errorLabel.sizeToFit()
                errorLabel.isHidden = false
                reloadButton.isHidden = false
            }
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        autoresizingMask = [.height, .width]
        imageScaling = .scaleProportionallyDown
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        loadingIndicator.autoresizingMask = [.maxXMargin, .maxYMargin, .minXMargin, .minYMargin]
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.style = .spinning
        loadingIndicator.isIndeterminate = true
        loadingIndicator.controlSize = .regular
        loadingIndicator.sizeToFit()
        loadingIndicator.isDisplayedWhenStopped = false
        loadingIndicator.stopAnimation(nil)
        addSubview(loadingIndicator)
        loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        errorLabel.isHidden = true
        addSubview(errorLabel)
        errorLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        errorLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        reloadButton.title = "Reload"
        reloadButton.target = self
        reloadButton.action = #selector(reload)
        reloadButton.isHidden = true
        addSubview(reloadButton)
        reloadButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        reloadButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor).isActive = true
    }

    func cancelOperations() {
        sd_cancelCurrentImageLoad()
        errorLabel.stringValue = "Canceled"
        errorLabel.isHidden = false
        reloadButton.isHidden = false
    }

    @objc func reload() {
        setImage(with: url)
    }

    func setImage(with url: URL?) {
        self.url = url
        isLoading = true
        error = nil
        delegate?.didStartLoading(view: self)
        sd_setImage(with: url,
                    placeholderImage: NSImage(named: "PagePlaceholder"),
                    options: .decodeFirstFrameOnly) { (_, error, _, _) in
                        DispatchQueue.main.async {
                            if error != nil {
                                self.error = error
                                self.delegate?.didFailLoading(view: self, error: error!)
                            } else {
                                self.delegate?.didFinishLoading(view: self)
                            }
                            self.isLoading = false
                        }
        }
    }

    func getHorizontalMargin() -> CGFloat {
        guard let image = self.image else {
            return 0
        }
        let imageSize = image.size
        var scale = min(frame.height / imageSize.height, frame.width / imageSize.width)
        scale = min(scale, 1)
        return frame.width - imageSize.width * scale
    }

}
