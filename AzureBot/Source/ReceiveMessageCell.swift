//
//  ReceiveMessageCell.swift
//  AzureBot
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import UIKit

public class ReceiveMessageCell: UITableViewCell, MessageCell {
    
    static let reuseId = "ReceiveMessageCell"
    
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        messageView.layer.roundCorners(radius: 5)
        messageView.layer.addShadow(radius: 3, opacity: 0.1)
        
        avatarImage.layer.roundCorners(radius: avatarImage.frame.width/2)
    }
    
    public override var textLabel: UILabel? {
        return messageLabel
    }

    public override var imageView: UIImageView? {
        return avatarImage
    }
    
    public func set(message: String) {
        messageLabel.text = message
    }
}
