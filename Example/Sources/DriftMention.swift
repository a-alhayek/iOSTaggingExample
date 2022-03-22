//
//  DriftMention.swift
//  Example
//
//  Copyright 2022 Twitter, Inc.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import TwitterTextEditor

protocol TaggedUser {
    var url: URL? { get }

    var taggedText: String { get }

    var precedingText: String { get }

    
}

protocol DriftUserMention: TextEditorViewEditingContent {
    var url: URL? { get }
    
    var rangeMax: Int { get }
    
    var attributes: [NSAttributedString.Key: Any] { get }

    func setNewSelectedRange(_ range: NSRange)

    func setNewText(_ text: String)
}

class DriftUserMentionIM: DriftUserMention {
    func setNewText(_ text: String) {
    }
    
    var attributes: [NSAttributedString.Key : Any]
    
    var url: URL?
    
    var text: String
    
    var selectedRange: NSRange

    init(text: String, selectedRange: NSRange, url: URL?, attributes: [NSAttributedString.Key : Any]) {
        self.url = url
        self.text = text
        self.selectedRange = selectedRange
        self.attributes = attributes
        if let url = url {
            self.attributes[.link] = url
        }
    }

    var rangeMax: Int {
        return NSMaxRange(selectedRange)
    }

    func setNewSelectedRange(_ range: NSRange) {
        self.selectedRange = range
    }
}

extension DriftUserMention {
    func adjustNewRange(with range: NSRange, newText: String, oldText: String) {
        if range.location > rangeMax {
            return
        }
        // text been added before this mention
        let location = selectedRange.location + (newText.count - oldText.count)
        let updatedRange = NSRange(location: location, length: text.count)
        setNewSelectedRange(updatedRange)
    }

    func adjustDeletedText(with range: NSRange, newText: String, oldText: String) {
        let currentRangeLocation = range.location
        if currentRangeLocation < selectedRange.location {
            let location = selectedRange.location - (oldText.count - newText.count)
            let updatedRange = NSRange(location: location, length: text.count)
            setNewSelectedRange(updatedRange)
        }
    }

    func isIntersectWithRange(range: NSRange) -> Bool {
        let interact = NSIntersectionRange(range, self.selectedRange)
        if interact.length != 0 { // this means they interact
            return true
        }
        return false
    }
}
