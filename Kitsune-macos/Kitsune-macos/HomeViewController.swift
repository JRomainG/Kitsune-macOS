//
//  HomeViewController.swift
//  Kitsune-macos
//
//  Created by Jean-Romain on 04/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import Quartz
import MangaDexLib

class HomeViewController: NSViewController {

    @IBOutlet var collectionView: NSCollectionView!
    var quickLookVC: QuickLookViewController?

    let itemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "mangaCVItem")
    let defaultItemSize = NSSize(width: 248, height: 420)

    let api = MDApi()
    var mangaProviders: [MangaProvider] = []
    var currentProviderIndex: Int = 0

    var currentProvider: MangaProvider {
        return mangaProviders[currentProviderIndex]
    }

    var mangas: [MDManga] {
        return currentProvider.mangas
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureCollectionView()
        collectionView.needsLayout = true

        // Init a QuickLookViewController for manga previews
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateController(withIdentifier: "quickLookViewController")
        quickLookVC = controller as? QuickLookViewController

        // Create providers used to download manga info
        mangaProviders = [
            LatestMangaProvider(api: api)
        ]
        quickLookVC?.mangaProvider = currentProvider

        // Mark provider as loading while the API is getting ready
        for provider in mangaProviders {
            provider.isLoading = true
            provider.delegate = self
        }

        api.getHomepage { (response) in
            print("Should show announcement:", response.announcement?.textBody)

            for provider in self.mangaProviders {
                provider.isLoading = false
            }
            self.currentProvider.startLoading()
        }

        // Catch key events to generated preview / open manga
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (event) -> NSEvent? in
            if self.handleKeyDown(with: event) {
                return nil
            }
            return event
        }
    }

    override func viewDidAppear() {
        // Update toolbar here, is it's not loaded yet in "viewDidLoad"
        if api.isLoggedIn() {
            ToolbarManager.didLogin()
        } else {
            ToolbarManager.didLogout()
        }

        let control = ToolbarManager.segmentedControl
        control?.segmentCount = 4
        control?.setLabel("Latest", forSegment: 0)
        control?.setLabel("Featured", forSegment: 1)
        control?.setLabel("Browse", forSegment: 2)
        control?.setLabel("Updates", forSegment: 3)
        control?.selectSegment(withTag: 0)
        control?.action = #selector(segmentSelected(_:))
    }

    func configureCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = defaultItemSize
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

    /// Toggles the quick look view
    func togglePreviewPanel() {
        guard let popup = quickLookVC else {
            return
        }
        if popup.isBeingPresented {
            popup.close()
        } else {
            popup.open(in: self, from: view)
        }
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

}

extension HomeViewController: MangaProviderDelegate {

    @objc
    func segmentSelected(_ sender: Any) {
        guard let control = sender as? NSSegmentedControl else {
            return
        }
        let type = MangaProvider.ProviderType(rawValue: control.selectedSegment)
        switch type {
        case .latest:
            collectionView.reloadData()
        default:
            break
        }

        quickLookVC?.close()
        quickLookVC?.mangaProvider = currentProvider
    }

    func didStartLoading(provider: MangaProvider) {
        print("Provider \(provider) did start loading")
    }
    func didStartLoadingMore(provider: MangaProvider) {
        print("Provider \(provider) did start loading more")
    }

    func didFinishLoading(provider: MangaProvider) {
        print("Provider \(provider) did finish loading")
        guard provider == currentProvider else {
            return
        }
        DispatchQueue.main.sync {
            collectionView.reloadData()
        }
    }

    func didFailLoading(provider: MangaProvider, error: Error) {
        print("Provider \(provider) did fail:", error)
    }

}
