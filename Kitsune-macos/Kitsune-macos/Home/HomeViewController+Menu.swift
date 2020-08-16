//
//  HomeViewController+Menu.swift
//  Kitsune
//
//  Created by Jean-Romain on 16/08/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import MangaDexLib

extension HomeViewController: NSMenuDelegate {

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
    }

    override func rightMouseDown(with event: NSEvent) {
        let point = collectionView.convert(event.locationInWindow, from: nil)
        collectionView.indexPathForItem(at: point)
        super.rightMouseDown(with: event)
    }

    @objc func handleClick(gesture: NSClickGestureRecognizer?) {
        guard let location = gesture?.location(in: collectionView) else {
            return
        }
        if let indexPath = collectionView.indexPathForItem(at: location) {
            collectionView.selectItems(at: Set([indexPath]), scrollPosition: .centeredHorizontally)
            collectionView.menu?.popUp(positioning: nil, at: location, in: collectionView)
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()

        guard let index = collectionView.selectionIndexes.first else {
            return
        }

        let manga = mangas[index]
        guard let mangaId = manga.mangaId else {
            return
        }

        menu.addItem(withTitle: "Show details", action: #selector(didClickShowDetails), keyEquivalent: "")

        if ArchiveManager.hasManga(mangaId: mangaId) {
            // Manga is downloaded, show a "delete" option
            menu.addItem(withTitle: "Delete", action: #selector(didClickDelete), keyEquivalent: "")
        }
    }

    @objc func didClickShowDetails(_ sender: AnyObject) {
        showMangaInfo(gesture: nil)
    }

    @objc func didClickDelete(_ sender: AnyObject) {
        guard let index = collectionView.selectionIndexes.first else {
            return
        }
        let archive = MangaArchive(from: mangas[index])
        ArchiveManager.deleteManga(archive)
        currentProvider.refresh()
    }

}
