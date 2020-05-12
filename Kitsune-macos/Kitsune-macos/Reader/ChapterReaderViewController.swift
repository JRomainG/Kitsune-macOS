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

    @IBOutlet var previewButton: NSButton!
    @IBOutlet var nextButton: NSButton!
    @IBOutlet var titleLabel: NSTextField!
    @IBOutlet var pagePopupButton: NSPopUpButton!
    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var imageView: NSImageView!

    var manga: MDManga?
    var chapter: MDChapter?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
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

    @objc func goBack() {
        pageController?.navigateBack(nil)
    }

    @IBAction func previousChapter(_ sender: Any) {
    }

    @IBAction func nextChapter(_ sender: Any) {
    }

}
