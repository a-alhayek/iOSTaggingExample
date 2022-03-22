//
//  DriftTextChangeExtention.swift
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


extension DriftViewController: TextEditorViewChangeObserver {
    private func update(_ textEditor: TextEditorView, byReplacingRange range: NSRange, with text: String, selectedRange: NSRange? = nil) {
        do {
            try textEditor.updateByReplacing(range: range,
                                                 with: text,
                                                 selectedRange: selectedRange)
        } catch {
            
        }
    }

    public func textEditorView(_ textEditorView: TextEditorView,
                        didChangeWithChangeResult changeResult: TextEditorViewChangeResult)
    {
        driftEditorText = textEditorView.text
        prevSelectedRange = textEditorView.selectedRange

        let selectedRange = textEditorView.selectedRange
        if selectedRange.length != 0 {
            dismissSuggests()
            return
        }

        let precedingText = textEditorView.text.substring(with: NSRange(location: 0, length: selectedRange.upperBound))
        if let match = precedingText.firstMatch(pattern: "@[^\\s]*\\z") {
            let ramge = match.range
            if changeResult.isTextChanged {
                presentSuggests([
                    "meow",
                    "cat",
                    "wowcat",
                    "かわいい🐱"
                ])
            }
        } else {
            dismissSuggests()
        }
    }
}
