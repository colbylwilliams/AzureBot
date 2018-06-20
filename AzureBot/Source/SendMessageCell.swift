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
    
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        messageView.layer.roundCorners(radius: 5)
        messageView.layer.addShadow(radius: 2, opacity: 0.3)
    }
    
    public override var textLabel: UILabel? {
        return messageLabel
    }
    
    public func set(message: String) {
        messageLabel.text = message
    }

}
