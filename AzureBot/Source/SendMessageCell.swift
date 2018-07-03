//
//  SendMessageCell.swift
//  AzureBot
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import UIKit

public class SendMessageCell: UITableViewCell, MessageCell {
    
    static let reuseId = "SendMessageCell"
    
    @IBOutlet public weak var messageView: UIView!
    @IBOutlet public weak var messageLabel: UILabel!
    
    public override var textLabel: UILabel? { return messageLabel }
    
    public func set(message: String) { messageLabel.text = message }

    override public func layoutSubviews() {
        super.layoutSubviews()
        
        configureForSend()
    }
}
