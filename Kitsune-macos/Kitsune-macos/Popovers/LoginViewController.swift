//
//  LoginViewController.swift
//  Kitsune
//
//  Created by Jean-Romain on 09/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import MangaDexLib

protocol LoginDelegate: AnyObject {

    func didLogin()
    func didLogout()

}

class LoginViewController: NSViewController {

    weak var delegate: LoginDelegate?
    var api: MDApi?
    private var popover = NSPopover()
    private(set) var isBeingPresented = false

    @IBOutlet var loginField: NSTextField!
    @IBOutlet var passwordField: NSSecureTextField!
    @IBOutlet var twoFactorField: NSTextField!
    @IBOutlet var twoFactorCheckbox: NSButton!
    @IBOutlet var errorLabel: NSTextField!
    @IBOutlet var loginButton: NSButton!
    @IBOutlet var registerButton: NSButton!
    @IBOutlet var loadingIndicator: NSProgressIndicator!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        errorLabel.isHidden = true
        loadingIndicator.isHidden = true
        twoFactorCheckbox.target = self
        twoFactorCheckbox.action = #selector(toggleTwoFactor)
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
        loginButton.isEnabled = false

        loginField.isHidden = true
        passwordField.isHidden = true
        twoFactorField.isHidden = true
        twoFactorCheckbox.isHidden = true
    }

    private func didFinishLoading() {
        loadingIndicator.stopAnimation(nil)
        loadingIndicator.isHidden = true
        loginButton.isEnabled = true

        loginField.isHidden = false
        passwordField.isHidden = false
        twoFactorField.isHidden = false
        twoFactorCheckbox.isHidden = false
    }

    @IBAction func login(_ sender: Any) {
        let login = loginField.stringValue
        let password = passwordField.stringValue
        let code = twoFactorField.stringValue
        let useTwoFactor = (twoFactorCheckbox.state == .on)

        let auth: MDAuth
        if useTwoFactor {
            auth = MDAuth(username: login, password: password, code: code, remember: true)
        } else {
            auth = MDAuth(username: login, password: password, remember: true)
        }

        didStartLoading()

        api?.login(with: auth, completion: { (response) in
            DispatchQueue.main.async {
                if response.error != nil {
                    self.errorLabel.isHidden = false
                    self.errorLabel.stringValue = String(describing: response.error!)
                } else if self.api?.isLoggedIn() == true {
                    self.errorLabel.isHidden = true
                    self.errorLabel.stringValue = ""
                    self.delegate?.didLogin()
                    self.close()
                }
                self.didFinishLoading()
            }
        })
    }

    @IBAction func register(_ sender: Any) {
        let url = URL(string: "\(MDApi.baseURL)/signup")!
        NSWorkspace.shared.open(url)
    }

    @objc func toggleTwoFactor() {
        if twoFactorCheckbox.state == .on {
            twoFactorField.isEnabled = true
        } else {
            twoFactorField.isEnabled = false
            twoFactorField.stringValue = ""
        }
    }

}

extension LoginViewController: NSPopoverDelegate {

    func popoverWillClose(_ notification: Notification) {
        close()
    }

}
