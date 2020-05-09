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
        if api.isLoggedIn() {
            ToolbarManager.didLogin(from: view)
        } else {
            ToolbarManager.didLogout(from: view)
        }

        let control = ToolbarManager.segmentedControl(in: view)
        control?.segmentCount = 4
        control?.setLabel("Latest", forSegment: 0)
        control?.setLabel("Featured", forSegment: 1)
        control?.setLabel("Browse", forSegment: 2)
        control?.setLabel("Followed", forSegment: 3)
        control?.selectSegment(withTag: 0)
        control?.action = #selector(segmentSelected(_:))

        if let sortButton = ToolbarManager.sortButton(in: view) {
            sortButton.target = self
            sortButton.action = #selector(toggleSortPanel)
        }
        toggleSortButton()
    }

    /// Enables or disables the sort button based on displayed content
    func toggleSortButton() {
        guard let sortButton = ToolbarManager.sortButton(in: view) else {
            return
        }
        switch currentProvider.type {
        case .listed, .search:
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
    }

}

extension HomeViewController: SortOptionsDelegate {

    func didUpdateSortOrder(controller: SortOptionsViewController, order: MDSortOrder) {
        if let listedProvider = currentProvider as? ListedMangaProvider {
            listedProvider.cancelRequests()
            listedProvider.sortOrder = order
            collectionView.reloadData()
            collectionView.scroll(.zero)
            quickLookVC?.close()
            toggleLoadingView()
        }
    }

}
