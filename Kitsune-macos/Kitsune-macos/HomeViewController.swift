//
//  HomeViewController.swift
//  Kitsune-macos
//
//  Created by Jean-Romain on 04/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa

class HomeViewController: NSViewController {

    @IBOutlet var collectionView: NSCollectionView!

    let itemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "mangaCVItem")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureCollectionView()
        collectionView.needsLayout = true
    }

    func configureCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 200, height: 290)
        flowLayout.sectionInset = NSEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        flowLayout.minimumInteritemSpacing = 20
        flowLayout.minimumLineSpacing = 20
        collectionView.collectionViewLayout = flowLayout

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isSelectable = true
        collectionView.allowsEmptySelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.enclosingScrollView?.borderType = .noBorder

        let nib = NSNib(nibNamed: "MangaCVItem", bundle: nil)
        collectionView.register(nib, forItemWithIdentifier: itemIdentifier)
    }

}

extension HomeViewController: NSCollectionViewDataSource {

    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 100
    }

    func collectionView(_ collectionView: NSCollectionView,
                        itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: itemIdentifier, for: indexPath)
        guard let collectionViewItem = item as? MangaCVItem else {
            return item
        }
        collectionViewItem.title = "Test"
        return collectionViewItem
    }

}

extension HomeViewController: NSCollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        print("Did select at", indexPaths.first!.item)
    }

}
