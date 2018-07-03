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
    
    @IBOutlet public weak var messageView: UIView!
    @IBOutlet public weak var messageLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!

    public override var textLabel: UILabel? { return messageLabel }
    
    public override var imageView: UIImageView? { return avatarImage }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        configureForReceive()
        
        avatarImage.roundCorners(radius: avatarImage.frame.width/2)
    }
}
