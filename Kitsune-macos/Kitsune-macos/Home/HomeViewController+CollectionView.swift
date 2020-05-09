//
//  HomeViewController+CollectionView.swift
//  Kitsune
//
//  Created by Jean-Romain on 09/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa

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
            print("Try to start loading more:", offset, size)
            currentProvider.loadMore()
        }
    }

}
