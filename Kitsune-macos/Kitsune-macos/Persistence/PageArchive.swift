//
//  PageArchive.swift
//  Kitsune
//
//  Created by Jean-Romain on 20/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import MangaDexLib

class PageArchive: NSObject, NSCoding {

    let url: URL?
    var image: NSImage? {
        get {
            if _image == nil {
                loadImage()
            }
            return _image
        }
        set {
            _image = newValue
        }
    }
    private var _image: NSImage?

    var archiveRoot: URL? {
        didSet {
            loadImage()
        }
    }

    func encode(with coder: NSCoder) {
        coder.encode(url, forKey: "url")
        saveImage()
    }

    required init?(coder: NSCoder) {
        url = coder.decodeObject(forKey: "url") as? URL
    }

    init(url: URL, image: NSImage? = nil) {
        self.url = url
        super.init()
        self.image = image
    }

    func loadImage() {
        guard var path = archiveRoot else {
            return
        }
        path.appendPathComponent(url?.lastPathComponent ?? "")
        image = NSImage(contentsOf: path)
    }

    func saveImage() {
        guard var path = archiveRoot, let imageRep = _image?.representations.first as? NSBitmapImageRep else {
            return
        }
        path.appendPathComponent(url?.lastPathComponent ?? "")
        do {
            print("Saving image to \(path)")
            let data = imageRep.representation(using: .jpeg, properties: [:])
            try data?.write(to: path)
        } catch {
            print("Failed to save image: \(error)")
        }
    }

}
