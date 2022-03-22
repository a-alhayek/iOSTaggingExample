//
//  BlockPasteObserver.swift
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

protocol SwiftViewControllerDelegate: AnyObject {
    func swiftViewControllerDidTapDone(_ swiftViewController: SwiftViewController)
}

public final class BlockPasteObserver: TextEditorViewPasteObserver {
    public var acceptableTypeIdentifiers: [String]

    private var canPaste: (NSItemProvider) -> Bool

    public func canPasteItemProvider(_ itemProvider: NSItemProvider) -> Bool {
        canPaste(itemProvider)
    }

    private var transform: (NSItemProvider, TextEditorViewPasteObserverTransformCompletion) -> Void

    public func transformItemProvider(_ itemProvider: NSItemProvider, completion: TextEditorViewPasteObserverTransformCompletion) {
        transform(itemProvider, completion)
    }

    init(acceptableTypeIdentifiers: [String],
         canPaste: @escaping (NSItemProvider) -> Bool,
         transform: @escaping (NSItemProvider, TextEditorViewPasteObserverTransformCompletion) -> Void
    ) {
        self.acceptableTypeIdentifiers = acceptableTypeIdentifiers
        self.canPaste = canPaste
        self.transform = transform
    }
}
