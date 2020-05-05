//
//  HomeViewController.swift
//  Kitsune-macos
//
//  Created by Jean-Romain on 04/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import Quartz

class HomeViewController: NSViewController {

    @IBOutlet var collectionView: NSCollectionView!

    let itemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "mangaCVItem")
    var mangas: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureCollectionView()
        collectionView.needsLayout = true


        // Catch key events to generated preview / open manga
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (event) -> NSEvent? in
            if self.handleKeyDown(with: event) {
                return nil
            }
            return event
        }
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

    func handleKeyDown(with event: NSEvent) -> Bool {
        // Make sure an item is selected, otherwise don't handle the event
        guard let indexPath = collectionView.selectionIndexPaths.first else {
            return false
        }

        switch event.keyCode {
        case 0x24, 0x4C:
            // Return key
            print("return at", indexPath)
            return true
        case 0x31:
            // Space key
            togglePreviewPanel()
            return true
        case 0x7B:
            // Left arrow
            moveSelection(by: -1)
            return true
        case 0x7C:
            // Right arrow
            moveSelection(by: 1)
            return true
        case 0x7D:
            // Down arrow
            moveSelection(by: numberOfColumns())
            return true
        case 0x7E:
            // Up arrow
            moveSelection(by: -numberOfColumns())
            return true
        default:
            break
        }
        return false
    }

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
        let newIndexPath = IndexPath(item: newItem, section: indexPath.section)

        collectionView.deselectItems(at: [indexPath])
        collectionView.selectItems(at: [newIndexPath], scrollPosition: .top)
        QLPreviewPanel.shared()?.currentPreviewItemIndex = newItem
    }

    /// Toggles the quick look view
    func togglePreviewPanel() {
        }

        }
    }

}

extension HomeViewController: NSCollectionViewDataSource {

    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
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
}
