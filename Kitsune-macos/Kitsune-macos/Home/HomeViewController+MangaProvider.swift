//
//  HomeViewController+MangaProvider.swift
//  Kitsune
//
//  Created by Jean-Romain on 09/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa

extension HomeViewController: MangaProviderDelegate {

    @objc func segmentSelected(_ sender: Any) {
        guard let control = sender as? NSSegmentedControl else {
            return
        }
        // Save the offset
        let contentView = collectionView.enclosingScrollView?.contentView
        savedOffsets[currentProviderIndex] = contentView?.bounds.origin ?? .zero

        currentProviderIndex = control.selectedSegment

        if currentProvider.mangas.count == 0 {
            currentProvider.startLoading()
        }

        // Update the content
        collectionView.reloadData()
        quickLookVC?.close()

        // Restore the offset
        collectionView.scroll(savedOffsets[currentProviderIndex])

        // Enable sort button if necessary
        toggleSortButton()
    }

    func didStartInitialLoad(provider: MangaProvider) {
        DispatchQueue.main.async {
            self.toggleLoadingView()
        }
    }

    func didStartLoadingMore(provider: MangaProvider) {
        print("Provider \(provider) did start loading more")
    }

    func didFinishLoading(provider: MangaProvider) {
        guard provider == currentProvider else {
            return
        }

        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.toggleLoadingView()
        }
    }

    func didFailLoading(provider: MangaProvider, error: Error) {
        guard provider == currentProvider else {
            return
        }

        DispatchQueue.main.async {
            self.toggleLoadingView()
            self.toggleErrorView()
        }
    }

}
