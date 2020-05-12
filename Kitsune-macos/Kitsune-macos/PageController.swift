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
    var currentIndex: Int = 0
    let pageIdentifiers: [String] = [
        "homeViewController",
        "mangaInfoViewController",
        "chapterReaderViewController"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        delegate = self

        // Only fill in the first view controller to prevent scrolling to next one if it doesn't exist yet
        arrangedObjects = [
            pageIdentifiers[0]
        ]
        currentController = selectedViewController as? PageContentViewController
    }

    override func viewDidAppear() {
        currentController?.didBecomeContentController()
    }

    override func navigateForward(_ sender: Any?) {
        // Allow presented view controller to block transition
        // This is not called when scrolling
        if !canNavigateForward() {
            return
        }
        // Add the identifier to the arranged objects list if necessary
        if selectedIndex == arrangedObjects.count - 1 {
            let identifier = pageIdentifiers[selectedIndex + 1]
            arrangedObjects.append(identifier)
        }
        pagecontrollerWillTransition(to: selectedIndex + 1)
        super.navigateForward(sender)
    }

    override func navigateBack(_ sender: Any?) {
        // Allow presented view controller to block transition
        // This is not called when scrolling
        if !canNavigateBack() {
            return
        }
        pagecontrollerWillTransition(to: selectedIndex - 1)
        super.navigateBack(sender)
    }

    func canNavigateForward() -> Bool {
        guard selectedIndex < pageIdentifiers.count - 1 else {
            return false
        }
        if let viewController = selectedViewController as? PageContentViewController {
            return viewController.canNavigateForward()
        }
        return true
    }

    func canNavigateBack() -> Bool {
        guard selectedIndex > 0 else {
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

        let nextIdentifier = pageIdentifiers[index]
        guard let nextController = contentViewControllers[nextIdentifier] else {
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
            currentController?.pageControllerWillTransition(to: viewController)
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
        if let newIndex = pageIdentifiers.firstIndex(of: identifier),
            newIndex < currentIndex {
            // Moving back from a page
            if let popCount = currentController?.popOnUnload() {
                arrangedObjects.removeLast(popCount)
            }
        }
        currentIndex = selectedIndex
        currentController = controller
    }

}
