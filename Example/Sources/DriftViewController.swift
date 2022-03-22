//
//  DriftViewController.swift
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

public final class DriftViewController: UIViewController {
    var textEditorView: TextEditorView?
    var customDropInteraction: UIDropInteraction?
    var dropIndicationView: UIView?
    var suggestViewController: SuggestViewController?
    var driftEditorText = ""
    var prevSelectedRange = NSMakeRange(0, 0)

    var mentionArray = [DriftUserMention]()
    
    init() {
        super.init(nibName: nil, bundle: nil)

        title = "Drift Example"
        let refreshBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(pressedRefresh))
        navigationItem.leftBarButtonItem = refreshBarButtonItem
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var useCustomDropInteraction: Bool = false {
        didSet {
            guard oldValue != useCustomDropInteraction else {
                return
            }
            updateCustomDropInteraction()
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
    }
}

extension DriftViewController: TextEditorViewTextAttributesDelegate {
    public func textEditorView(_ textEditorView: TextEditorView, updateAttributedString attributedString: NSAttributedString, completion: @escaping (NSAttributedString?) -> Void) {
        DispatchQueue.global().async {
            let string = attributedString.string
            let stringRange = NSRange(location: 0, length: string.length)


            DispatchQueue.main.async { [weak self] in
                guard let self = self,
                      let textEditorView = self.textEditorView
                else {
                    completion(nil)
                    return
                }
                let attributedString = NSMutableAttributedString(attributedString: attributedString)
                attributedString.removeAttribute(.suffixedAttachment, range: stringRange)
                attributedString.removeAttribute(.underlineStyle, range: stringRange)
                attributedString.removeAttribute(.link, range: stringRange)
                attributedString.removeAttribute(.foregroundColor, range: stringRange)
                attributedString.addAttribute(.foregroundColor, value: UIColor.defaultText, range: stringRange)

                for match in self.mentionArray {
                    attributedString.addAttributes(match.attributes, range: match.selectedRange)
                }
                completion(attributedString)
            }
        }

    }
}
