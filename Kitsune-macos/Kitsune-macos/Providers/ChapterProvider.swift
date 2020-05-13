//
//  ChapterProvider.swift
//  Kitsune
//
//  Created by Jean-Romain on 13/05/2020.
//  Copyright © 2020 JustKodding. All rights reserved.
//

import Foundation
import MangaDexLib

class ChapterProvider: NSObject {

    var chapter: MDChapter?
    var manga: MDManga?
    var mangaProvider: MangaProvider?

    lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "Chapter info download queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    func getChapters() -> [MDChapter]? {
        guard var chapters = manga?.chapters, let currentChapter = chapter else {
            return nil
        }
        chapters = chapters.filter({ (chapter) -> Bool in
            return chapter.getOriginalLang() == currentChapter.getOriginalLang()
        })
        return chapters.sorted { (first, second) -> Bool in
            return first.comesBefore(chapter: second)
        }
    }

    func getPreviousChapter() -> MDChapter? {
        guard let currentChapter = chapter, let chapters = getChapters() else {
            return nil
        }

        // Find the chapters that come before this one
        let previousChapters = chapters.filter { (chapter) -> Bool in
            return chapter.comesBefore(chapter: currentChapter)
        }
        let lastChapter = previousChapters.last

        // Try to get the chapter with the same group
        let lastGroupChapter = previousChapters.last(where: { (chapter) -> Bool in
            return chapter.groupId == currentChapter.groupId
        })

        // If the group did release the chapter that is asked for, return that one
        if lastGroupChapter != nil
            && lastGroupChapter?.volume == lastChapter?.volume
            && lastGroupChapter?.chapter == lastChapter?.chapter {
            return lastGroupChapter
        }

        // Otherwise, return the one we found
        return lastChapter
    }

    func getNextChapter() -> MDChapter? {
        guard let currentChapter = chapter, let chapters = getChapters() else {
            return nil
        }

        // Find the chapters that come after this one
        let nextChapters = chapters.filter { (chapter) -> Bool in
            return currentChapter.comesBefore(chapter: chapter)
        }
        let nextChapter = nextChapters.first

        // Try to get the chapter with the same group
        let nextGroupChapter = nextChapters.first(where: { (chapter) -> Bool in
            return chapter.groupId == currentChapter.groupId
        })

        // If the group did release the chapter that is asked for, return that one
        if nextGroupChapter != nil
            && nextGroupChapter?.volume == nextChapter?.volume
            && nextGroupChapter?.chapter == nextChapter?.chapter {
            return nextGroupChapter
        }

        // Otherwise, return the one we found
        return nextChapter
    }

    func getChapterInfo(completion: @escaping (MDChapter?) -> Void) {
        let operation = ChapterInfoOperation()
        operation.manga = manga
        operation.provider = mangaProvider
        operation.chapter = chapter
        operation.completionBlock = {
            guard !operation.isCancelled,
                let chapter = operation.chapter else {
                    completion(nil)
                    return
            }
            completion(chapter)
        }
        operationQueue.addOperation(operation)
    }

}
