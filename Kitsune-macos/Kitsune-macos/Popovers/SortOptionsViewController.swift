//
//  SortOptionsViewController.swift
//  Kitsune
//
//  Created by Jean-Romain on 09/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import MangaDexLib

protocol SortOptionsDelegate: AnyObject {

    func didUpdateSortOrder(controller: SortOptionsViewController, order: MDSortOrder)

}

class SortOptionsViewController: NSViewController {

    @IBOutlet var tableView: NSTableView!

    let sortOrders: [MDSortOrder] = [
        .bestRating,
        .worstRating,
        .mostViews,
        .leastViews,
        .mostFollows,
        .leastFollows,
        .mostComments,
        .leastComments,
        .oldestUpdated,
        .recentlyUpdated,
        .alphabetical,
        .reverseAlphabetical
    ]

    let sortOrderTitles: [MDSortOrder: String] = [
        .bestRating: "Ratings (+)",
        .worstRating: "Ratings (-)",
        .mostViews: "Views (+)",
        .leastViews: "Views (-)",
        .mostFollows: "Follows (+)",
        .leastFollows: "Follows (-)",
        .mostComments: "Comments (+)",
        .leastComments: "Comments (-)",
        .oldestUpdated: "Last update",
        .recentlyUpdated: "Oldest update",
        .alphabetical: "Alphabetical",
        .reverseAlphabetical: "Reverse alphabetical"
    ]

    var delegate: SortOptionsDelegate?
    private var popover = NSPopover()
    private(set) var isBeingPresented = false

    var selectedOrder: MDSortOrder = .bestRating {
        didSet {
            delegate?.didUpdateSortOrder(controller: self, order: selectedOrder)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        tableView.dataSource = self
        tableView.delegate = self
    }

    func open(in viewController: NSViewController, from view: NSView) {
        guard let button = ToolbarManager.sortButton(in: view) else {
            return
        }

        isBeingPresented = true
        popover.contentViewController = self
        popover.behavior = .transient
        popover.delegate = self
        popover.show(relativeTo: button.frame, of: button, preferredEdge: .maxY)
    }

    func close() {
        popover.close()
        isBeingPresented = false
    }

}

extension SortOptionsViewController: NSPopoverDelegate {

    func popoverWillClose(_ notification: Notification) {
        close()
    }

}

extension SortOptionsViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return sortOrders.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier(rawValue: "textImageCell")
        let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView

        let order = sortOrders[row]
        cell?.textField?.stringValue = sortOrderTitles[order] ?? ""

        if order == selectedOrder {
            cell?.imageView?.image = NSImage(imageLiteralResourceName: "NSMenuOnStateTemplate")
        } else {
            cell?.imageView?.image = nil
        }
        return cell
    }

}

extension SortOptionsViewController: NSTableViewDelegate {

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard tableView.selectedRow > -1 else {
            return
        }
        let order = sortOrders[tableView.selectedRow]
        selectedOrder = order
        tableView.deselectAll(nil)
        tableView.reloadData()
        close()
    }

}
