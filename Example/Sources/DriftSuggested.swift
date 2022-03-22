//
//  DriftSuggested.swift
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


extension DriftViewController {
    func presentSuggests(_ suggests: [String]) {
        guard suggestViewController == nil else {
            return
        }

        let suggestViewController = SuggestViewController()
        suggestViewController.delegate = self
        suggestViewController.suggests = suggests

        addChild(suggestViewController)

        var constraints = [NSLayoutConstraint]()

        suggestViewController.view.layer.borderColor = UIColor.defaultBorder.cgColor
        suggestViewController.view.layer.borderWidth = 1.0

        view.addSubview(suggestViewController.view)

        suggestViewController.view.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(suggestViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor))
        constraints.append(suggestViewController.view.bottomAnchor.constraint(equalTo: view.keyboardSafeArea.layoutGuide.bottomAnchor))
        constraints.append(suggestViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor))
        constraints.append(suggestViewController.view.heightAnchor.constraint(equalTo: view.keyboardSafeArea.layoutGuide.heightAnchor, multiplier: 0.5))

        NSLayoutConstraint.activate(constraints)

        suggestViewController.didMove(toParent: self)

        self.suggestViewController = suggestViewController
    }

    func dismissSuggests() {
        guard let suggestViewController = suggestViewController else {
            return
        }

        suggestViewController.willMove(toParent: nil)
        suggestViewController.view.removeFromSuperview()
        suggestViewController.removeFromParent()

        self.suggestViewController = nil
    }
}

// MARK: - SuggestViewControllerDelegate

extension DriftViewController: SuggestViewControllerDelegate {
    func suggestViewController(_ viewController: SuggestViewController, didSelectSuggestedString suggestString: String) {
        guard let textEditorView = textEditorView else {
            return
        }

        let text = textEditorView.text
        let selectedRange = textEditorView.selectedRange

        let precedingText = text.substring(with: NSRange(location: 0, length: selectedRange.upperBound))
        
        if let match = precedingText.firstMatch(pattern: "@[^\\s]*\\z") {
            let location = match.range.location
            let range = NSRange(location: location, length: (text.length - location))
            if let match = text.firstMatch(pattern: "@[^\\s]* ?", range: range) {
                let replacingRange = match.range
                do {
                    let replacingText = "\(suggestString) "
                    let selectedRange = NSRange(location: location + replacingText.length, length: 0)
                    try textEditorView.updateByReplacing(range: replacingRange, with: replacingText, selectedRange: selectedRange)
                    mentionArray.append(DriftUserMentionIM(text: suggestString,
                                                           selectedRange: NSRange(location: location, length: suggestString.count),
                                                           url: URL(string: "ahmad"),
                                                           attributes: [.foregroundColor : UIColor.blue]))
                    driftEditorText.append(suggestString)
                    prevSelectedRange = selectedRange

                } catch {
                }
            }
        }
        dismissSuggests()
    }
}


