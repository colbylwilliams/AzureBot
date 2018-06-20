//
//  MessageBar.swift
//  AzureBot
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import UIKit

public class MessageBar: UIView, UITextViewDelegate {
    
    let padding: CGFloat = 16
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var placeholder: UITextView!
    @IBOutlet weak var textContainer: UIView!
    
    public var text: String { return textView.text }
    
    public override func awakeFromNib() {
        super.awakeFromNib()

        textView.translatesAutoresizingMaskIntoConstraints = false
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        textContainer.translatesAutoresizingMaskIntoConstraints = false

//        textContainer.roundCorners(radius: 4)
        
        sendButton.roundCorners(radius: 12)
        
        updateDependentState ()
    }
    
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
        BotClient.shared.send(message: textView.text) { r in
            if r.error == nil {
                DispatchQueue.main.async {
                    self.clear()
                }
            }
        }
    }

    
    // MARK: - UITextViewDelegate

    // MARK: Responding to Text Changes
    
    // public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool { }
    
    public func textViewDidChange(_ textView: UITextView) {
        updateDependentState()
    }
    
    func updateBarConstraints() {
        
        //print(frame)
        
        let height = textView.contentSize.height + padding
        
        guard height != frame.height else { return }
        
        print("updateing height: \(height)")
        
        for constraint in constraints where constraint.firstAttribute == .height {
            constraint.constant = height
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

