//
//  MessageCell.swift
//  AzureBot
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import UIKit

public protocol MessageCell {

    //var messageView: UIView { get }
    //var messageLabel: UILabel { get }
    
    func set(message: String);
}
