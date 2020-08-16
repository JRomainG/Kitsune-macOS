//
//  PageArchive.swift
//  Kitsune
//
//  Created by Jean-Romain on 20/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import MangaDexLib
import SDWebImage

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
    var archiveRoot: URL?

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

    func getImagePath() -> URL? {
        guard var path = archiveRoot else {
            return nil
        }
        path.appendPathComponent(url?.lastPathComponent ?? "")
        return path
    }

    func loadImage() {
        guard let path = getImagePath() else {
            return
        }
        image = NSImage(contentsOf: path)
    }

    func saveImage() {
        guard let path = getImagePath(), let imageRep = _image?.representations.first as? NSBitmapImageRep else {
            return
        }
        do {
            print("Saving image to \(path)")
            let data = imageRep.representation(using: .jpeg, properties: [:])
            try data?.write(to: path)
        } catch {
            print("Failed to save image: \(error)")
        }
    }

    func downloadImage(save: Bool = true, completion: @escaping (Error?) -> Void) {
        SDWebImageManager.shared.loadImage(with: url,
                                           options: .decodeFirstFrameOnly,
                                           progress: nil) { (image, _, error, _, _, _) in
            self.image = image
            if save {
                self.saveImage()
            }
            completion(error)
        }
    }

}
