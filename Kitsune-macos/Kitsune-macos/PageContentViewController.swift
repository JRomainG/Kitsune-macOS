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
        view.wantsLayer = true
        updateBackgroundColor()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        NSAppearance.current = view.effectiveAppearance
        updateBackgroundColor()
    }

    private func updateBackgroundColor() {
        // Views need a background, or the animation is ugly
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    /// Number of controllers to remove from the history when this controller is unloaded
    func popOnUnload() -> Int {
        return 0
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
