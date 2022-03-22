//
//  ViewController.swift
//  TwitterTextEditorTagExample
//
//  Created by ahmad alhayek on 3/21/22.
//

import UIKit
import TwitterTextEditor

class TagViewController: UIViewController {
    var textEditorView: TextEditorView?
    var customDropInteraction: UIDropInteraction?
    var dropIndicationView: UIView?
    var suggestViewController: SuggestViewController?
    var currentText = ""
    var prevSelectedRange = NSMakeRange(0, 0)

    var taggedUsersArray = [TaggedUser]()
    
    init() {
        super.init(nibName: nil, bundle: nil)

        title = "Tagging Example"
        let refreshBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(pressedRefresh))
        navigationItem.leftBarButtonItem = refreshBarButtonItem
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
    }
}

extension TagViewController: TextEditorViewTextAttributesDelegate {
    public func textEditorView(_ textEditorView: TextEditorView, updateAttributedString attributedString: NSAttributedString, completion: @escaping (NSAttributedString?) -> Void) {
        DispatchQueue.global().async {
            let string = attributedString.string
            let stringLength = (string as NSString).length
            let stringRange = NSRange(location: 0, length: stringLength)


            DispatchQueue.main.async { [weak self] in
                guard let self = self,
                    self.textEditorView != nil
                else {
                    completion(nil)
                    return
                }
                let attributedString = NSMutableAttributedString(attributedString: attributedString)
                attributedString.removeAttribute(.suffixedAttachment, range: stringRange)
                attributedString.removeAttribute(.underlineStyle, range: stringRange)
                attributedString.removeAttribute(.link, range: stringRange)
                attributedString.removeAttribute(.foregroundColor, range: stringRange)
                attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: stringRange)

                for match in self.taggedUsersArray {
                    attributedString.addAttributes(match.attributes, range: match.selectedRange)
                }
                completion(attributedString)
            }
        }

    }
}


extension TagViewController {
    @objc func pressedRefresh() {
        textEditorView?.isEditable = false
        textEditorView?.text = ""
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



extension TagViewController {
    func presentSuggests(_ suggests: [String]) {
        guard suggestViewController == nil else {
            return
        }

        let suggestViewController = SuggestViewController()
        suggestViewController.delegate = self
        suggestViewController.suggests = suggests

        addChild(suggestViewController)

        var constraints = [NSLayoutConstraint]()

        suggestViewController.view.layer.borderColor = UIColor.black.cgColor
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

extension TagViewController: SuggestViewControllerDelegate {
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
                    taggedUsersArray.append(TaggedUserIM(text: suggestString,
                                                           selectedRange: NSRange(location: location, length: suggestString.count),
                                                           url: URL(string: "www.apple.com"),
                                                           attributes: [.foregroundColor : UIColor.blue]))
                    currentText.append(suggestString)
                    prevSelectedRange = selectedRange

                } catch {
                }
            }
        }
        dismissSuggests()
    }
}



public struct TagEditingContent: TextEditorViewEditingContent {
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
        return TagEditingContent(text: String(filteredUnicodeScalars), selectedRange: updatedSelectedRange)
    }
}

extension TagViewController: TextEditorViewEditingContentDelegate {
    public func textEditorView(_ textEditorView: TextEditorView,
                        updateEditingContent editingContent: TextEditorViewEditingContent) -> TextEditorViewEditingContent?
    {
        let editedContent = editingContent.charFilter { unicodeScalar in
            // Filtering any BiDi control characters out.
            !unicodeScalar.properties.isBidiControl
        }

        let newRange = NSRange(location: 0, length: editingContent.text.count)
        let oldRange = NSRange(location: 0, length: currentText.count)

        if newRange.length < oldRange.length {
            return removeMentionsIfDeletedFrom(editingContent: editingContent)
        } else if newRange.length == oldRange.length {
            return updateSelectedRange(editingContent: editingContent)
        } else {
            for tag in taggedUsersArray {
            tag.adjustNewRange(with: textEditorView.selectedRange, newText: textEditorView.text, oldText: currentText)
            }
        }
        
        return editedContent
    }

    private func removeMentionsIfDeletedFrom(editingContent: TextEditorViewEditingContent) -> TextEditorViewEditingContent {
        var newMentionArray = [TaggedUser]()

        var updatedSelectedRange = editingContent.selectedRange
        var updatedText = editingContent.text

        for index in 0..<taggedUsersArray.count {
            let tag = taggedUsersArray[index]

            if NSIntersectionRange(tag.selectedRange, prevSelectedRange) != tag.selectedRange {
                tag.adjustDeletedText(with: editingContent.selectedRange, newText: editingContent.text, oldText: currentText)
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

        taggedUsersArray = newMentionArray.sorted(by: { lhs, rhs in
            return lhs.selectedRange.location <=  rhs.selectedRange.location
        })
        
        return TagEditingContent.init(text: updatedText, selectedRange: updatedSelectedRange)
    }

    private func updateSelectedRange(editingContent: TextEditorViewEditingContent) -> TextEditorViewEditingContent {
        var updatedRange = editingContent.selectedRange
        for index in 0..<taggedUsersArray.count {
            let tag = taggedUsersArray[index]
            
            if NSIntersectionRange(updatedRange, tag.selectedRange).location != 0 { // two ranges interact with each others
                updatedRange.formUnion(tag.selectedRange)
            }
        }
        return TagEditingContent(text: editingContent.text, selectedRange: updatedRange)
    }
}

extension TagViewController: TextEditorViewChangeObserver {

    public func textEditorView(_ textEditorView: TextEditorView,
                        didChangeWithChangeResult changeResult: TextEditorViewChangeResult)
    {
        currentText = textEditorView.text
        prevSelectedRange = textEditorView.selectedRange

        let selectedRange = textEditorView.selectedRange
        if selectedRange.length != 0 {
            dismissSuggests()
            return
        }

        let precedingText = textEditorView.text.substring(with: NSRange(location: 0, length: selectedRange.upperBound))
        if precedingText.firstMatch(pattern: "@[^\\s]*\\z") != nil {
            if changeResult.isTextChanged {
                presentSuggests([
                    "S'well",
                    "Describe",
                    "Original",
                    "Easiy"
                ])
            }
        } else {
            dismissSuggests()
        }
    }
}
protocol TaggedUser: TextEditorViewEditingContent {
    var url: URL? { get }
    
    var rangeMax: Int { get }
    
    var attributes: [NSAttributedString.Key: Any] { get }

    func setNewSelectedRange(_ range: NSRange)
}

class TaggedUserIM: TaggedUser {
    
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

extension TaggedUser {
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
}
