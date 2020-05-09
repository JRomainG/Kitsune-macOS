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
    @IBOutlet var loadingView: LoadingView!
    @IBOutlet var errorLabel: NSTextField!
    var quickLookVC: QuickLookViewController?

    let itemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "mangaCVItem")
    let defaultItemSize = NSSize(width: 248, height: 320)
    let defaultItemSpacing: CGFloat = 20
    let defaultLineSpacing: CGFloat = 20

    let api = MDApi()
    var mangaProviders: [MangaProvider] = []
    var savedOffsets: [CGPoint] = []

    var currentProviderIndex: Int = 0 {
        didSet {
            quickLookVC?.mangaProvider = currentProvider
            toggleErrorLabel()
            toggleLoadingView()

            // Call a "viewDidScroll" event to check if more should be loaded
            collectionViewDidScroll(notification: nil)
        }
    }

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
            LatestMangaProvider(api: api),
            FeaturedMangaProvider(api: api),
            ListedMangaProvider(api: api),
            FollowedMangaProvider(api: api)
        ]
        savedOffsets = [NSPoint](repeating: .zero, count: mangaProviders.count)
        quickLookVC?.mangaProvider = currentProvider

        // Perform a first request, and then setup providers
        api.getHomepage { (response) in
            print("Should show announcement:", response.announcement?.textBody)

            for provider in self.mangaProviders {
                provider.delegate = self
                provider.becomeReady()
            }
            self.currentProvider.startLoading()
        }
        toggleLoadingView()

        // Catch key events to generated preview / open manga
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (event) -> NSEvent? in
            if self.handleKeyDown(with: event) {
                return nil
            }
            return event
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        // Update toolbar here, as it's not always loaded yet in "viewDidLoad"
        configureToolbar()
    }

    func configureCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = defaultItemSize
        flowLayout.sectionInset = NSEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        flowLayout.minimumInteritemSpacing = defaultItemSpacing
        flowLayout.minimumLineSpacing = defaultLineSpacing
        collectionView.collectionViewLayout = flowLayout

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isSelectable = true
        collectionView.allowsEmptySelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.enclosingScrollView?.borderType = .noBorder
        collectionView.scroll(.zero)

        // Receive scroll events to know when to load more pages
        let clipView = collectionView.enclosingScrollView?.contentView
        clipView?.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(collectionViewDidScroll(notification:)),
                                               name: NSView.boundsDidChangeNotification,
                                               object: clipView)

        let nib = NSNib(nibNamed: "MangaCVItem", bundle: nil)
        collectionView.register(nib, forItemWithIdentifier: itemIdentifier)
    }

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

    /// Show or hide the loading view if necessary
    func toggleLoadingView() {
        if currentProvider.state == .waiting || currentProvider.state == .initialLoad {
            loadingView.isHidden = false
            loadingView.loadingIndicator.startAnimation(nil)
        } else {
            loadingView.isHidden = true
            loadingView.loadingIndicator.stopAnimation(nil)
        }
    }

    /// Show or hide the error label if necessary
    func toggleErrorLabel() {
        if let error = currentProvider.error {
            errorLabel.stringValue = String(describing: error)
            errorLabel.isHidden = false
        } else {
            errorLabel.stringValue = ""
            errorLabel.isHidden = true
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
    }

    func didStartInitialLoad(provider: MangaProvider) {
        print("Provider \(provider) did start initial load")
        DispatchQueue.main.async {
            self.toggleLoadingView()
        }
    }

    func didStartLoadingMore(provider: MangaProvider) {
        print("Provider \(provider) did start loading more")
    }

    func didFinishLoading(provider: MangaProvider) {
        print("Provider \(provider) did finish loading")
        guard provider == currentProvider else {
            return
        }

        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.toggleLoadingView()
        }
    }

    func didFailLoading(provider: MangaProvider, error: Error) {
        print("Provider \(provider) did fail:", error)
        guard provider == currentProvider else {
            return
        }

        DispatchQueue.main.async {
            self.toggleLoadingView()
            self.toggleErrorLabel()
        }
    }

}
