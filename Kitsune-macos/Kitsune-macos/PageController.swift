//
//  PageController.swift
//  Kitsune
//
//  Created by Jean-Romain on 11/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa

class PageController: NSPageController {

    var contentViewControllers: [String: PageContentViewController] = [:]
    var currentController: PageContentViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        self.delegate = self
        self.arrangedObjects = ["homeViewController",
                                "mangaInfoViewController"]
        currentController = selectedViewController as? PageContentViewController
        currentController?.didBecomeContentController()
    }

    override func viewDidAppear() {
        currentController?.didBecomeContentController()
    }

    override func scrollWheel(with event: NSEvent) {
        // Prevent scrolling to go to next or previous
        return
    }

    override func navigateForward(_ sender: Any?) {
        // Allow presented view controller to block transition
        if !canNavigateForward() {
            return
        }
        pagecontrollerWillTransition(to: selectedIndex + 1)
        super.navigateForward(sender)
    }

    override func navigateBack(_ sender: Any?) {
        // Allow presented view controller to block transition
        if !canNavigateBack() {
            return
        }
        pagecontrollerWillTransition(to: selectedIndex - 1)
        super.navigateBack(sender)
    }

    func canNavigateForward() -> Bool {
        if selectedIndex == arrangedObjects.count - 1 {
            return false
        }

        if let viewController = selectedViewController as? PageContentViewController {
            return viewController.canNavigateForward()
        }

        return true
    }

    func canNavigateBack() -> Bool {
        if selectedIndex == 0 {
            return false
        }

        if let viewController = selectedViewController as? PageContentViewController {
            return viewController.canNavigateBack()
        }

        return true
    }

    func pagecontrollerWillTransition(to index: Int) {
        if index == 0 {
            ToolbarManager.willTransitionToHomeViewController(from: view)
        } else {
            ToolbarManager.willTransitionToDetailViewController(from: view)
        }

        guard let nextObject = arrangedObjects[index] as? String,
            let nextController = contentViewControllers[nextObject] else {
            return
        }
        currentController?.pageControllerWillTransition(to: nextController)
    }

}

extension PageController: NSPageControllerDelegate {

    func pageController(_ pageController: NSPageController,
                        identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        return object as? String ?? ""
    }

    func pageController(_ pageController: NSPageController,
                        viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController {
        if let controller = contentViewControllers[identifier] {
            return controller
        }

        let controller = storyboard!.instantiateController(withIdentifier: identifier)

        if let viewController = controller as? PageContentViewController {
            viewController.pageController = self
            contentViewControllers[identifier] = viewController
            return viewController
        }

        return PageContentViewController()
    }

    func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
        pageController.completeTransition()
        currentController?.didBecomeContentController()
    }

    func pageController(_ pageController: NSPageController, didTransitionTo object: Any) {
        guard let identifier = object as? String,
            let controller = contentViewControllers[identifier] else {
            return
        }
        currentController?.pageControllerdidTransition(to: controller)
        currentController = controller
    }

}
