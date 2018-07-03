//
//  MessageCell.swift
//  AzureBot
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import UIKit

public protocol MessageCell {

    var messageView: UIView! { get }
    var messageLabel: UILabel! { get }
}


extension MessageCell {
    
    func configureForSend() {
        messageView.roundCorners(radius: 5, skipping: .layerMaxXMinYCorner)
        messageView.addShadow(opacity: 0.2, radius: 3.0, offset: CGSize(width: 0.0, height: 2.0))
    }
    
    func configureForReceive() {
        messageView.roundCorners(radius: 5, skipping: .layerMinXMinYCorner)
        messageView.addShadow(opacity: 0.1, radius: 3.0, offset: CGSize(width: 0.0, height: 2.0))
    }
}
