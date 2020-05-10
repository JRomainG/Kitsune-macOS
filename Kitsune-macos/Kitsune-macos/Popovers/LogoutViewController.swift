//
//  LogoutViewController.swift
//  Kitsune
//
//  Created by Jean-Romain on 09/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import MangaDexLib

class LogoutViewController: NSViewController {

    weak var delegate: LoginDelegate?
    var api: MDApi?
    private var popover = NSPopover()
    private(set) var isBeingPresented = false

    @IBOutlet var logoutButton: NSButton!
    @IBOutlet var loadingIndicator: NSProgressIndicator!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        loadingIndicator.isHidden = true
    }

    func open(in viewController: NSViewController, from view: NSView) {
        guard let button = ToolbarManager.accountButton(in: view) else {
            return
        }

        isBeingPresented = true
        popover.contentViewController = self
        popover.delegate = self
        popover.behavior = .transient
        popover.show(relativeTo: button.frame, of: button, preferredEdge: .maxY)
    }

    func close() {
        popover.close()
        isBeingPresented = false
    }

    private func didStartLoading() {
        loadingIndicator.startAnimation(nil)
        loadingIndicator.isHidden = false
        logoutButton.isEnabled = false
    }

    private func didFinishLoading() {
        loadingIndicator.stopAnimation(nil)
        loadingIndicator.isHidden = true
        logoutButton.isEnabled = true
        self.close()
    }

    @IBAction func logout(_ sender: Any) {
        didStartLoading()

        api?.logout(completion: { (_) in
            DispatchQueue.main.async {
                if self.api?.isLoggedIn() == false {
                    self.delegate?.didLogout()
                }
                self.didFinishLoading()
            }

        })
    }

}

extension LogoutViewController: NSPopoverDelegate {

    func popoverWillClose(_ notification: Notification) {
        close()
    }

}
