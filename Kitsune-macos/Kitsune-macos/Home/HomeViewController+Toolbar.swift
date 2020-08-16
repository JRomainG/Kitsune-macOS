//
//  HomeViewController+Toolbar.swift
//  Kitsune
//
//  Created by Jean-Romain on 09/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import MangaDexLib

extension HomeViewController {

    func configureToolbar() {
        showToolbarButtons()

        if api.isLoggedIn() {
            ToolbarManager.didLogin(from: view)
        } else {
            ToolbarManager.didLogout(from: view)
        }

        let control = ToolbarManager.segmentedControl(in: view)

        // Create a segment for each manga provider
        control?.segmentCount = mangaProviders.count
        for index in 0..<mangaProviders.count {
            let provider = mangaProviders[index]
            control?.setLabel(provider.title, forSegment: index)
        }

        control?.selectSegment(withTag: currentProviderIndex)
        control?.target = self
        control?.action = #selector(segmentSelected(_:))

        if let accountButton = ToolbarManager.accountButton(in: view) {
            accountButton.target = self
            accountButton.action = #selector(toggleAccountPanel)
        }
        if let sortButton = ToolbarManager.sortButton(in: view) {
            sortButton.target = self
            sortButton.action = #selector(toggleSortPanel)
        }
        if let refreshButton = ToolbarManager.refreshButton(in: view) {
            refreshButton.target = self
            refreshButton.action = #selector(refresh)
        }
        toggleSortButton()
    }

    func showToolbarButtons() {
        ToolbarManager.accountButton(in: view)?.isHidden = false
        ToolbarManager.sortButton(in: view)?.isHidden = false
        ToolbarManager.refreshButton(in: view)?.isHidden = false
        ToolbarManager.segmentedControl(in: view)?.isHidden = false
        ToolbarManager.searchBar(in: view)?.isHidden = false
        ToolbarManager.previousButton(in: view)?.isHidden = false
        ToolbarManager.previousButton(in: view)?.isEnabled = false
    }

    /// Enables or disables the sort button based on displayed content
    func toggleSortButton() {
        guard let sortButton = ToolbarManager.sortButton(in: view) else {
            return
        }
        switch currentProvider.type {
        case .listed, .search, .followed:
            sortButton.isEnabled = true
        default:
            sortButton.isEnabled = false
        }
    }

    /// Toggles the sort options view
    @objc func toggleSortPanel() {
        guard let popup = sortOrderVC else {
            return
        }
        if popup.isBeingPresented {
            popup.close()
        } else {
            popup.selectedOrder = currentProvider.sortOrder
            popup.open(in: self, from: view)
        }
    }

    /// Toggles the login or logout view
    @objc func toggleAccountPanel() {
        if api.isLoggedIn() {
            toggleLogoutPanel()
        } else {
            toggleLoginPanel()
        }
    }

    /// Toggles the login view
    func toggleLoginPanel() {
        guard let popup = loginVC else {
            return
        }
        if popup.isBeingPresented {
            popup.close()
        } else {
            popup.open(in: self, from: view)
        }
    }

    /// Toggles the logout view
    func toggleLogoutPanel() {
        guard let popup = logoutVC else {
            return
        }
        if popup.isBeingPresented {
            popup.close()
        } else {
            popup.open(in: self, from: view)
        }
    }

    /// Close all the popovers
    func closePopovers() {
        quickLookVC?.close()
        closeToolbarPopovers()
    }

    /// Close all the popovers coming from the toolbar
    func closeToolbarPopovers() {
        sortOrderVC?.close()
        loginVC?.close()
    }

}

extension HomeViewController: SortOptionsDelegate {

    func didUpdateSortOrder(controller: SortOptionsViewController, order: MDSortOrder) {
        currentProvider.cancelRequests()
        currentProvider.sortOrder = order
        collectionView.reloadData()
        collectionView.scroll(.zero)
        quickLookVC?.close()
        toggleLoadingView()
    }

}

extension HomeViewController: LoginDelegate {

    func didLogin() {
        ToolbarManager.didLogin(from: view)
    }

    func didLogout() {
        ToolbarManager.didLogout(from: view)
    }

}
