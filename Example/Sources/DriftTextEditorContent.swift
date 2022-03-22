//
//  DriftTextEditorContent.swift
//  Example
//
//  Copyright 2022 Twitter, Inc.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import KeyboardGuide
import MobileCoreServices
import TwitterTextEditor
import UIKit

public struct DriftEditingContent: TextEditorViewEditingContent {
    public var text: String

    public var selectedRange: NSRange
}

public extension TextEditorViewEditingContent {
    func charFilter(_ isIncluded: (Unicode.Scalar) -> Bool) -> TextEditorViewEditingContent {
        var filteredUnicodeScalars = String.UnicodeScalarView()


        var index = 0
        var updatedSelectedRange = selectedRange

        for unicodeScalar in text.unicodeScalars {
            if isIncluded(unicodeScalar) {
                filteredUnicodeScalars.append(unicodeScalar)
                index += unicodeScalar.utf16.count
            } else {
                let replacingRange = NSRange(location: index, length: unicodeScalar.utf16.count)
                updatedSelectedRange = updatedSelectedRange.movedByReplacing(range: replacingRange, length: 0)
            }
        }
        return DriftEditingContent(text: String(filteredUnicodeScalars), selectedRange: updatedSelectedRange)
    }
}

extension DriftViewController: TextEditorViewEditingContentDelegate {
    public func textEditorView(_ textEditorView: TextEditorView,
                        updateEditingContent editingContent: TextEditorViewEditingContent) -> TextEditorViewEditingContent?
    {
        let editedContent = editingContent.charFilter { unicodeScalar in
            // Filtering any BiDi control characters out.
            !unicodeScalar.properties.isBidiControl
        }

        let newRange = NSRange(location: 0, length: editingContent.text.count)
        let oldRange = NSRange(location: 0, length: driftEditorText.count)

        if newRange.length < oldRange.length {
            return removeMentionsIfDeletedFrom(editingContent: editingContent)
        } else if newRange.length == oldRange.length {
            return updateSelectedRange(editingContent: editingContent)
        } else {
            for tag in mentionArray {
            tag.adjustNewRange(with: textEditorView.selectedRange, newText: textEditorView.text, oldText: driftEditorText)
            }
        }
        
        return editedContent
    }

    private func removeMentionsIfDeletedFrom(editingContent: TextEditorViewEditingContent) -> TextEditorViewEditingContent {
        var newMentionArray = [DriftUserMention]()

        var updatedSelectedRange = editingContent.selectedRange
        var updatedText = editingContent.text

        for index in 0..<mentionArray.count {
            let tag = mentionArray[index]

            if NSIntersectionRange(tag.selectedRange, prevSelectedRange) != tag.selectedRange {
                tag.adjustDeletedText(with: editingContent.selectedRange, newText: editingContent.text, oldText: driftEditorText)
                newMentionArray.append(tag)
            }
            // testing this
            let intersection = NSIntersectionRange(tag.selectedRange, editingContent.selectedRange)
            let tagRange = NSMakeRange(tag.selectedRange.location, intersection.location - tag.selectedRange.location)
            

            if intersection.location != 0, newMentionArray.last?.selectedRange == tag.selectedRange,
               let range = Range.init(tagRange, in: editingContent.text) {
                newMentionArray.removeLast()
                updatedText.removeSubrange(range)
                updatedSelectedRange = NSMakeRange(updatedText.count, 0)
            }
        }

        mentionArray = newMentionArray.sorted(by: { lhs, rhs in
            return lhs.selectedRange.location <=  rhs.selectedRange.location
        })
        
        return DriftEditingContent.init(text: updatedText, selectedRange: updatedSelectedRange)
    }

    private func updateSelectedRange(editingContent: TextEditorViewEditingContent) -> TextEditorViewEditingContent {
        var updatedRange = editingContent.selectedRange
        for index in 0..<mentionArray.count {
            let tag = mentionArray[index]
            
            if NSIntersectionRange(updatedRange, tag.selectedRange).location != 0 { // two ranges interact with each others
                updatedRange.formUnion(tag.selectedRange)
            }
        }
        return DriftEditingContent(text: editingContent.text, selectedRange: updatedRange)
    }
}
