//
//  MangaOperation.swift
//  Kitsune
//
//  Created by Jean-Romain on 11/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Cocoa
import MangaDexLib

class MangaOperation: Operation {

    var manga: MDManga?
    var provider: MangaProvider?
    var delay: Double = 0
    var error: Error?

    let semaphore = DispatchSemaphore(value: 0)

}

class MangaDetailOperation: MangaOperation {

    override func main() {
        guard let manga = self.manga else {
            return
        }

        if isCancelled {
            return
        }

        // Wait a bit before fetching so as not to flood
        _ = semaphore.wait(timeout: .now() + delay)

        if isCancelled {
            return
        }

        provider?.getDetails(for: manga, completion: { (manga, error) in
            self.manga = manga
            self.error = error
            self.semaphore.signal()
        })

        // Wait until download is done
        semaphore.wait()
    }

}

class MangaInfoOperation: MangaOperation {

    override func main() {
        guard let manga = self.manga else {
            return
        }

        if isCancelled {
            return
        }

        // Wait a bit before fetching so as not to flood
        _ = semaphore.wait(timeout: .now() + delay)

        if isCancelled {
            return
        }

        provider?.getInfo(for: manga, completion: { (manga, error) in
            self.manga = manga
            self.error = error
            self.semaphore.signal()
        })

        // Wait until download is done
        semaphore.wait()
    }

}

class ChapterInfoOperation: MangaOperation {

    var chapter: MDChapter?

    override func main() {
        guard let chapter = self.chapter else {
            return
        }

        if isCancelled {
            return
        }

        // Wait a bit before fetching so as not to flood
        _ = semaphore.wait(timeout: .now() + delay)

        if isCancelled {
            return
        }

        provider?.getChapterInfo(for: chapter, completion: { (chapter, error) in
            self.chapter = chapter
            self.error = error
            self.semaphore.signal()
        })

        // Wait until download is done
        semaphore.wait()
    }

}

class ChapterPagesOperation: MangaOperation {

    var chapter: ChapterArchive?
    var api: MDApi?

    override func main() {
        guard let chapter = self.chapter else {
            return
        }

        if isCancelled {
            return
        }

        // Wait a bit before fetching so as not to flood
        _ = semaphore.wait(timeout: .now() + delay)

        if isCancelled {
            return
        }

        api?.getChapterInfo(chapterId: chapter.chapterId, completion: { (response) in
            if let mdChapter = response.chapter {
                chapter.updatedPages(with: mdChapter)
                chapter.downloadPages {
                    ArchiveManager.saveChapter(chapter)
                    self.semaphore.signal()
                }
            } else {
                self.semaphore.signal()
            }
        })

        // Wait until download is done
        semaphore.wait()
    }

}
