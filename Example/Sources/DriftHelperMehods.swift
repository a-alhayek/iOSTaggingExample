//
//  DriftHelperMehods.swift
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

extension DriftViewController: UIDropInteractionDelegate {
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
