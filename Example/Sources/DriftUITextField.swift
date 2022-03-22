//
//  DriftUITextField.swift
//  Example
//
//  Copyright 2022 Twitter, Inc.
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

// we need text
// we need to make it blue
extension DriftViewController {
    func makeUITextView(_ text: String) -> UITextView {
        let instance = UITextView()
        instance.translatesAutoresizingMaskIntoConstraints = false
        instance.isUserInteractionEnabled = true
        instance.isEditable = false
        instance.isScrollEnabled = false
        instance.linkTextAttributes = [
            .foregroundColor: UIColor.blue
        ]
        let attributedString = NSMutableAttributedString(string: text, attributes: nil)
        attributedString.setAttributes([.link: "apple.com"],
                                       range: NSRange(location: 0, length: text.length))
        instance.attributedText = attributedString
        return instance
    }
}
