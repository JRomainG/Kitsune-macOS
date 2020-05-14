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

class HomeViewController: PageContentViewController {

    @IBOutlet var collectionView: NSCollectionView!
    @IBOutlet var loadingView: LoadingView!
    @IBOutlet var errorView: LoadingView!
    @IBOutlet var errorLabel: NSTextField!
    var quickLookVC: QuickLookViewController?
    var sortOrderVC: SortOptionsViewController?
    var loginVC: LoginViewController?
    var logoutVC: LogoutViewController?

    let itemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "mangaCVItem")
    let defaultItemSize = NSSize(width: 248, height: 320)
    let defaultItemSpacing: CGFloat = 20
    let defaultLineSpacing: CGFloat = 20
    var monitor: Any?

    let api = MDApi()
    var mangaProviders: [MangaProvider] = []
    var savedOffsets: [CGPoint] = []

    var currentProviderIndex: Int = 0 {
        didSet {
            quickLookVC?.mangaProvider = currentProvider
            toggleErrorView()
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
        var controller = storyboard.instantiateController(withIdentifier: "quickLookViewController")
        quickLookVC = controller as? QuickLookViewController

        // Init the toolbar popup controllers
        controller = storyboard.instantiateController(withIdentifier: "sortOptionsViewController")
        sortOrderVC = controller as? SortOptionsViewController
        sortOrderVC?.delegate = self

        controller = storyboard.instantiateController(withIdentifier: "loginViewController")
        loginVC = controller as? LoginViewController
        loginVC?.delegate = self
        loginVC?.api = api

        controller = storyboard.instantiateController(withIdentifier: "logoutViewController")
        logoutVC = controller as? LogoutViewController
        logoutVC?.delegate = self
        logoutVC?.api = api

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

    override func viewWillAppear() {
        super.viewWillAppear()
        toggleErrorView()
        toggleLoadingView()
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

        // Receive double click events to show manga info
        let gesture = NSClickGestureRecognizer(target: self, action: #selector(showMangaInfo(notification:)))
        gesture.numberOfClicksRequired = 2
        gesture.delaysPrimaryMouseButtonEvents = false
        collectionView.addGestureRecognizer(gesture)

        let nib = NSNib(nibNamed: "MangaCVItem", bundle: nil)
        collectionView.register(nib, forItemWithIdentifier: itemIdentifier)
    }

    func handleKeyDown(with event: NSEvent) -> Bool {
        // Make sure an item is selected, otherwise don't handle the event
        guard collectionView.selectionIndexPaths.first != nil,
            isDisplayedViewController else {
            return false
        }

        switch event.keyCode {
        case 0x24, 0x4C:
            // Return / Enter
            showMangaInfo(notification: nil)
            return true
        case 0x31:
            // Space
            togglePreviewPanel()
            return true
        case 0x35:
            // Escape
            collectionView.deselectAll(nil)
            closePopovers()
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

    @objc func showMangaInfo(notification: NSNotification?) {
        guard collectionView.selectionIndexPaths.first != nil, isDisplayedViewController else {
            return
        }
        pageController?.navigateForward(nil)
    }

    override func canNavigateForward() -> Bool {
        return collectionView.selectionIndexPaths.first != nil
    }

    override func pageControllerWillTransition(to controller: PageContentViewController) {
        guard let indexPath = collectionView.selectionIndexPaths.first,
            let infoViewController = controller as? MangaInfoViewController else {
            return
        }
        let manga = mangas[indexPath.item]
        infoViewController.manga = manga
        infoViewController.mangaProvider = currentProvider
    }

    override func pageControllerdidTransition(to controller: PageContentViewController) {
        if let eventMonitor = monitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }

    override func didBecomeContentController() {
        configureToolbar()

        // Catch key events to generated preview / open manga
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (event) -> NSEvent? in
            if self.handleKeyDown(with: event) {
                return nil
            }
            return event
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
    func toggleErrorView() {
        if let error = currentProvider.error {
            errorLabel.stringValue = String(describing: error)
            errorView.isHidden = false
        } else {
            errorLabel.stringValue = ""
            errorView.isHidden = true
        }
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

    @IBAction func openWebsite(_ sender: Any) {
        let url = URL(string: MDApi.baseURL)!
        NSWorkspace.shared.open(url)
    }

}
