//
//  HomeViewController+CollectionView.swift
//  Kitsune
//
//  Created by Jean-Romain on 09/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa

extension HomeViewController {

    /// Returns how many items fit in the current collection view's width
    func numberOfColumns() -> Int {
        guard let layout = collectionView.collectionViewLayout as? NSCollectionViewFlowLayout else {
            return 1
        }

        let inset = layout.sectionInset.left + layout.sectionInset.right
        let availableWidth = collectionView.frame.size.width + layout.minimumInteritemSpacing - inset
        return Int(availableWidth / (layout.itemSize.width + layout.minimumInteritemSpacing))
    }

    /// Moves the selected index path by the given number of items
    func moveSelection(by nItems: Int) {
        guard let indexPath = collectionView.selectionIndexPaths.first else {
            return
        }

        // Find out the index of the new selected element
        var newItem = indexPath.item + nItems
        newItem = max(0, min(mangas.count - 1, newItem))
        let newIndexPath = IndexPath(item: newItem, section: indexPath.section)

        // Force-stop scroll
        for recognizer in collectionView.gestureRecognizers {
            recognizer.isEnabled = false
            recognizer.isEnabled = true
        }

        // Update the selection
        collectionView.deselectItems(at: [indexPath])
        collectionView.selectItems(at: [newIndexPath], scrollPosition: .top)
        quickLookVC?.manga = mangas[newItem]
    }

    @objc func refresh() {
        collectionView.scroll(.zero)
        currentProvider.refresh()
        collectionView.reloadData()
    }

}

extension HomeViewController: NSCollectionViewDataSource {

    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return mangas.count
    }

    func collectionView(_ collectionView: NSCollectionView,
                        itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: itemIdentifier, for: indexPath)
        guard let collectionViewItem = item as? MangaCVItem else {
            return item
        }
        collectionViewItem.manga = mangas[indexPath.item]
        return collectionViewItem
    }

}

extension HomeViewController: NSCollectionViewDelegate {

    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let index = indexPaths.first?.item else {
            return
        }
        quickLookVC?.manga = mangas[index]
    }

    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        quickLookVC?.close()
    }

    @objc func collectionViewDidScroll(notification: NSNotification?) {
        guard currentProvider.hasMorePages,
            currentProvider.state == .idle,
            let contentView = collectionView.enclosingScrollView?.contentView else {
            return
        }

        let offset = contentView.bounds.origin.y + contentView.bounds.height
        let size = collectionView.bounds.size.height

        // Start loading more 2 rows before the end
        if offset >= size - 2 * (defaultItemSize.height + defaultLineSpacing) {
            currentProvider.loadMore()
        }
    }

}
