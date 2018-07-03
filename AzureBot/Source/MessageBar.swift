//
//  MessageBar.swift
//  AzureBot
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import UIKit

public class MessageBar: UIView, UITextViewDelegate {
    
    let padding: CGFloat = 7
    let maxHeight: CGFloat = 92
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var placeholder: UITextView!
    @IBOutlet weak var textContainer: UIView!
    
    public var text: String { return textView.text }
    
    var contentHeight: CGFloat { return textView.contentSize.height + safeAreaInsets.bottom + padding }
    
    public override func awakeFromNib() {
        super.awakeFromNib()

        textView.translatesAutoresizingMaskIntoConstraints = false
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        textContainer.translatesAutoresizingMaskIntoConstraints = false

        self.addShadow(opacity: 0.2, radius: 0.0, offset: CGSize(width: 0.0, height: -0.5))
        
        updateDependentState ()
    }
    
    var layout = true
    var safeAreaInsetsCache = UIEdgeInsets.zero
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateBarConstraints()
    }
    
    fileprivate func updateDependentState () {
        placeholder.isHidden = textView.hasText
        sendButton.isEnabled = textView.hasText
    }
    
    public func clear() {
        textView.text = ""
        updateDependentState()
    }
    
    @IBAction func sendButtonTouchUpInside(_ sender: Any) {
//        textView.isScrollEnabled = !textView.isScrollEnabled
        
        //BotClient.shared.send(message: textView.text) { r in
        BotClient.shared.send(message: textView.text) { r in
            if let e = r.error {
                print("Error: " + e.localizedDescription)
            }
        }
        self.clear()
    }

    
    // MARK: - UITextViewDelegate

    // MARK: Responding to Text Changes
    
    // public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {}

    public func textViewDidChange(_ textView: UITextView) {
        updateDependentState()
    }
    
    var errorCounter = 0

    func updateBarConstraints() {

        for constraint in constraints where constraint.firstAttribute == .height {
            constraint.constant = contentHeight
        }
    }
}

// MARK: Responding to Editing Notifications
// public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool { }
// public func textViewDidBeginEditing(_ textView: UITextView) { }
// public func textViewShouldEndEditing(_ textView: UITextView) -> Bool { }
// public func textViewDidEndEditing(_ textView: UITextView) { }

// MARK: Responding to Selection Changes
// public func textViewDidChangeSelection(_ textView: UITextView) { }

// MARK: Interacting with Text Data
// public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool { }
// public func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool { }

