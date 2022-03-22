//
//  MediumExample.swift
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

final class MediumExample: UIViewController {
    var textEditorView: TextEditorView?
    var customDropInteraction: UIDropInteraction?
    var dropIndicationView: UIView?
    var suggestViewController: SuggestViewController?

    var mentionArray = [MediumUserMention]()
    
    init() {
        super.init(nibName: nil, bundle: nil)

        title = "Medium Example"
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




extension MediumExample: TextEditorViewTextAttributesDelegate {
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







extension MediumExample {
    @objc func pressedRefresh() {
        textEditorView?.isEditable = false
        textEditorView?.text = ""
    }

    func updateCustomDropInteraction() {
        guard isViewLoaded, let textEditorView = textEditorView else {
            return
        }

        if useCustomDropInteraction {
            if customDropInteraction == nil {
                let dropInteraction = UIDropInteraction(delegate: self)
                view.addInteraction(dropInteraction)
                self.customDropInteraction = dropInteraction
            }

            // To disable drop interaction on the text editor view, set `isDropInteractionEnabled` to `false`.
            // Users can still drag and drop texts inside text editor view.
            textEditorView.isDropInteractionEnabled = false
        } else {
            if let dropInteraction = customDropInteraction {
                view.removeInteraction(dropInteraction)
                self.customDropInteraction = nil
            }
            textEditorView.isDropInteractionEnabled = true
        }
    }

    func setTextEditorPasteObserver(_ textEditorView: TextEditorView) {
        textEditorView.pasteObservers = [
            BlockPasteObserver(
                acceptableTypeIdentifiers: [kUTTypeImage as String],
                canPaste: { _ in
                    true
                },
                transform: { [weak self] itemProvider, reply in
                    itemProvider.loadDataRepresentation(forTypeIdentifier: kUTTypeImage as String) { [weak self] data, _ in
                        if let data = data, let image = UIImage(data: data) {
                            // Called on an arbitrary background queue.
                            DispatchQueue.main.async {
                                let imagePreviewViewController = ImagePreviewViewController(image: image) { [weak self] in
                                    self?.dismiss(animated: true, completion: nil)
                                }
                                imagePreviewViewController.title = "Pasted"
                                self?.present(imagePreviewViewController, animated: true)
                            }
                        }
                        reply.transformed()
                    }
                }
            )
        ]
    }

    func setupViews() {
        view.backgroundColor = .white

        var constraints = [NSLayoutConstraint]()
        defer {
            NSLayoutConstraint.activate(constraints)
        }

        let textEditorView = TextEditorView()

        textEditorView.changeObserver = self
        textEditorView.editingContentDelegate = self
        textEditorView.textAttributesDelegate = self
        
        textEditorView.layer.cornerRadius = 5
        textEditorView.layer.borderWidth = 1
        textEditorView.layer.borderColor = UIColor.blue.cgColor

        textEditorView.font = .systemFont(ofSize: 20)
        textEditorView.placeholderText = "Write a comment"
        setTextEditorPasteObserver(textEditorView)

        view.addSubview(textEditorView)

        textEditorView.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(textEditorView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 20.0))
        constraints.append(textEditorView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor))
        constraints.append(textEditorView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor))
        constraints.append(textEditorView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor))
        self.textEditorView = textEditorView

        let dropIndicationView = UIView()
        dropIndicationView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.5)
        dropIndicationView.isHidden = true

        view.addSubview(dropIndicationView)

        dropIndicationView.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(dropIndicationView.topAnchor.constraint(equalTo: view.topAnchor))
        constraints.append(dropIndicationView.leadingAnchor.constraint(equalTo: view.leadingAnchor))
        constraints.append(dropIndicationView.bottomAnchor.constraint(equalTo: view.bottomAnchor))
        constraints.append(dropIndicationView.trailingAnchor.constraint(equalTo: view.trailingAnchor))

        self.dropIndicationView = dropIndicationView

        let dropIndicationLabel = UILabel()
        dropIndicationLabel.text = "Drop here"
        dropIndicationLabel.textColor = .white
        dropIndicationLabel.font = .systemFont(ofSize: 40.0)

        dropIndicationView.addSubview(dropIndicationLabel)

        dropIndicationLabel.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(dropIndicationLabel.centerXAnchor.constraint(equalTo: dropIndicationView.centerXAnchor))
        constraints.append(dropIndicationLabel.centerYAnchor.constraint(equalTo: dropIndicationView.centerYAnchor))

        updateCustomDropInteraction()

        // This view is used to call `layoutSubviews()` when keyboard safe area is changed
        // to manually change scroll view content insets.
        // See `viewDidLayoutSubviews()`.
        let keyboardSafeAreaRelativeLayoutView = UIView()
        view.addSubview(keyboardSafeAreaRelativeLayoutView)
        keyboardSafeAreaRelativeLayoutView.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(keyboardSafeAreaRelativeLayoutView.bottomAnchor.constraint(equalTo: view.keyboardSafeArea.layoutGuide.bottomAnchor))
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // This is an example call for supporting accessibility contrast change to recall
        // `textEditorView(_:updateAttributedString:completion:)`.
        textEditorView?.setNeedsUpdateTextAttributes()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let textEditorView = textEditorView else {
            return
        }

        let bottomInset = view.keyboardSafeArea.insets.bottom - view.layoutMargins.bottom
        textEditorView.scrollView.contentInset.bottom = bottomInset
        if #available(iOS 11.1, *) {
            textEditorView.scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        } else {
            textEditorView.scrollView.scrollIndicatorInsets.bottom = bottomInset
        }
    }
}

// MARK: - UIDropInteractionDelegate

extension MediumExample: UIDropInteractionDelegate {
    public func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        if let textEditorView = textEditorView, let localDragSession = session.localDragSession {
            return !textEditorView.isDraggingText(of: localDragSession)
        }
        return session.items.contains { item in
            item.itemProvider.hasItemConformingToTypeIdentifier(kUTTypeImage as String)
        }
    }

    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        .init(operation: .copy)
    }

    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
        dropIndicationView?.isHidden = false
    }

    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        dropIndicationView?.isHidden = true
    }

    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
        dropIndicationView?.isHidden = true
    }

    public func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        guard let item = session.items.first else {
            return
        }

        let itemProvider = item.itemProvider
        itemProvider.loadDataRepresentation(forTypeIdentifier: kUTTypeImage as String) { [weak self] data, _ in
            if let data = data, let image = UIImage(data: data) {
                // Called on an arbitrary background queue.
                DispatchQueue.main.async {
                    let imagePreviewViewController = ImagePreviewViewController(image: image) { [weak self] in
                        self?.dismiss(animated: true, completion: nil)
                    }
                    imagePreviewViewController.title = "Dropped"
                    self?.present(imagePreviewViewController, animated: true)
                }
            }
        }
    }
}

extension MediumExample: TextEditorViewChangeObserver {
    public func textEditorView(_ textEditorView: TextEditorView,
                        didChangeWithChangeResult changeResult: TextEditorViewChangeResult)
    {
        for index in 0..<mentionArray.count {
            let mention = mentionArray[index]

            if mention.selectedRange.intersection(textEditorView.selectedRange) != nil {
                do {
                    if changeResult.isTextChanged && textEditorView.text.count < mention.text.count {
                        // change the text
                        mentionArray.remove(at: index)
                        print(textEditorView.text)
                        try textEditorView.updateByReplacing(range: mention.selectedRange,
                                                             with: textEditorView.text.substring(with: textEditorView.selectedRange),
                                                             selectedRange: NSRange(location: 0, length: 0))
                        return
                    } else {
                        // change the selected range
                        try textEditorView.updateByReplacing(range: textEditorView.selectedRange, with: textEditorView.text.substring(with: textEditorView.selectedRange), selectedRange: mention.selectedRange)
                        return
                    }
                    
                } catch {
                    do {
                        try textEditorView.updateByReplacing(range: NSRange(location: mention.selectedRange.location, length: mention.selectedRange.length - 1),
                                                             with: textEditorView.text.substring(with: textEditorView.selectedRange),
                                                             selectedRange: nil)
                    } catch {
                        
                    }
                }
            }
        }

        if changeResult.isTextChanged {
        mentionArray.forEach{ $0.adjustNewRange(with: textEditorView.selectedRange, newText: textEditorView.text)}
        }

        if changeResult.isSelectedRangeChanged {
            mentionArray.forEach {
                if $0.isIntersectWithRange(range: textEditorView.selectedRange) {
                    textEditorView.selectedRange = $0.selectedRange
                }
            }
        }
        
        let selectedRange = textEditorView.selectedRange
        if selectedRange.length != 0 {
            dismissSuggests()
            return
        }

        let precedingText = textEditorView.text.substring(with: NSRange(location: 0, length: selectedRange.upperBound))
        if precedingText.firstMatch(pattern: "@[^\\s]*\\z") != nil {
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


extension MediumExample {
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

extension MediumExample: SuggestViewControllerDelegate {
    func suggestViewController(_ viewController: SuggestViewController, didSelectSuggestedString suggestString: String) {
        guard let textEditorView = textEditorView else {
            return
        }

        let text = textEditorView.text
        let selectedRange = textEditorView.selectedRange

        let precedingText = text.substring(with: NSRange(location: 0, length: selectedRange.upperBound))
        print(precedingText)
        if let match = precedingText.firstMatch(pattern: "@[^\\s]*\\z") {
            let location = match.range.location
            let range = NSRange(location: location, length: (text.length - location))
            if let match = text.firstMatch(pattern: "@[^\\s]* ?", range: range) {
                let replacingRange = match.range
                do {
                    let replacingText = "\(suggestString)"
                    let selectedRange = NSRange(location: location + replacingText.length, length: 0)
                    try textEditorView.updateByReplacing(range: replacingRange, with: replacingText, selectedRange: selectedRange)
                    mentionArray.append(MUserMention(text: textEditorView.text,
                                                           selectedRange: NSRange(location: location, length: replacingText.count),
                                                           url: URL(string: "ahmad"),
                                                           attributes: [.foregroundColor : UIColor.blue]))
                } catch {
                }
            }
        }
        dismissSuggests()
    }
}

extension MediumExample: TextEditorViewEditingContentDelegate {
    public func textEditorView(_ textEditorView: TextEditorView,
                        updateEditingContent editingContent: TextEditorViewEditingContent) -> TextEditorViewEditingContent?
    {
        let editedContent = editingContent.charFilter { unicodeScalar in
            // Filtering any BiDi control characters out.
            !unicodeScalar.properties.isBidiControl
        }
        return editedContent
    }
}


protocol MediumUserMention: TextEditorViewEditingContent {
    var url: URL? { get }

    var rangeMax: Int { get }

    var attributes: [NSAttributedString.Key: Any] { get }

    func setNewSelectedRange(_ range: NSRange)

    func setNewText(_ text: String)
}

class MUserMention: MediumUserMention {
    func setNewText(_ text: String) {
        self.text = text
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

extension MediumUserMention {
    func adjustNewRange(with range: NSRange, newText: String) {
        if range.location > rangeMax {
            return
        }
        // text been added before this mention
        let location = selectedRange.location + (newText.count - text.count)
        let updatedRange = NSRange(location: location, length: selectedRange.length)
        setNewSelectedRange(updatedRange)
        setNewText(newText)
    }

    func isIntersectWithRange(range: NSRange) -> Bool {
        let interact = NSIntersectionRange(range, self.selectedRange)
        if interact.length != 0 { // this means they interact
            return true
        }
        return false
    }
}
