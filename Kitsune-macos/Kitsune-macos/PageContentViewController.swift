//
//  PageContentViewController.swift
//  Kitsune
//
//  Created by Jean-Romain on 11/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa

class PageContentViewController: NSViewController {

    var pageController: PageController?

    var isDisplayedViewController: Bool {
        return pageController?.currentController == self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    func canNavigateForward() -> Bool {
        return true
    }

    func canNavigateBack() -> Bool {
        return true
    }

    func pageControllerWillTransition(to controller: PageContentViewController) {
    }

    func pageControllerdidTransition(to controller: PageContentViewController) {
    }

    func didBecomeContentController() {
    }

}
