//
//  BotViewController.swift
//  AzureBot
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import UIKit

public class BotViewController: UITableViewController {
    
    private var observer: AnyObject?
    private var needsUpdateViewOnAppearance = true
    
    private var isVisible: Bool { return isViewLoaded && view.window != nil }
    
    var messages: SortedArray<Activity> { return BotClient.shared.messages }

    //@IBOutlet var messageToolbar: MessageToolbar!
    //public override var inputAccessoryView: UIView? { return messageToolbar }
    
    @IBOutlet var messageBar: MessageBar!
    public override var inputAccessoryView: UIView? { return messageBar }
    
    
    public override var canBecomeFirstResponder: Bool { return true }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        
        setupObservers()
        
        BotClient.shared.start { r in
            if let conversation = r.resource {
                print(conversation.conversationId ?? "")
                print(conversation.streamUrl ?? "")
            } else if let error = r.error {
                print("Error: " + error.localizedDescription)
            }
        }
    }
    
    
    
    fileprivate func setupObservers() {
        
        // Keyboard Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification(notification:)), name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification(notification:)), name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification(notification:)), name: .UIKeyboardDidHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification(notification:)), name: .UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification(notification:)), name: .UIKeyboardDidChangeFrame, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleMessageAdded(notification:)), name: .BotClientDidAddMessageNotification, object: BotClient.shared)
    }
    var shouldKeyboard: Bool = false
    var didKeyboard: Bool = false
    @objc
    func handleKeyboardNotification(notification: Notification) {
        switch notification.name {
        case .UIKeyboardWillShow:
            if false { }
            // print("UIKeyboardWillShow")
        case .UIKeyboardDidShow:
            if false { }
            // print("UIKeyboardDidShow")
            // for m in messages { print("\(messages.anyIndex(of: m) ?? -1) \(m.localTimestamp?.timeIntervalSince1970 ?? 0)") }
        case .UIKeyboardWillHide:
            if false { }
            // print("UIKeyboardWillHide")
        case .UIKeyboardDidHide:
            if false { }
            // print("UIKeyboardDidHide")
        case .UIKeyboardWillChangeFrame:
            if false { }
            //print("UIKeyboardWillChangeFrame")
        case .UIKeyboardDidChangeFrame:
            // print("UIKeyboardDidChangeFrame")
            guard shouldKeyboard, !didKeyboard else { return }
            if let rect = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect {
                DispatchQueue.main.async {
                    guard self.isVisible, self.messages.count > 0, rect.height > 100 else { return }
                    self.didKeyboard = true
                    print(rect)
                    self.tableView.contentInset.top = (self.getContentInset().top + rect.height)
                    self.tableView.scrollToRow(at: IndexPath.init(row: 0, section: 0), at: .top, animated: true)
                }
            }
        default:
            print("default")
        }
    }
    
    @objc
    func handleMessageAdded(notification: Notification) {
        DispatchQueue.main.async {
            if self.isVisible {
                self.tableView.reloadData()
            } else {
                self.needsUpdateViewOnAppearance = true
            }
        }
    }
    
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if needsUpdateViewOnAppearance {
            tableView.reloadData()
            needsUpdateViewOnAppearance = false
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        becomeFirstResponder()
        shouldKeyboard = true
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    
    func getContentInset() -> UIEdgeInsets {
        return UIEdgeInsets(top: max(tableView.safeAreaInsets.top, messageBar.frame.height) - tableView.adjustedContentInset.top, left: 0, bottom: tableView.safeAreaInsets.bottom - tableView.adjustedContentInset.bottom, right: 0)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // print(messageBar.frame)
        
        if tableView.contentInset == UIEdgeInsets.zero {
            tableView.contentInset = getContentInset()
        }
    }
    
    var adjustedContentInsetCache: UIEdgeInsets!
    
    public override func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
//        print("s \(tableView.safeAreaInsets)")
//        print("s \(tableView.safeAreaLayoutGuide)")
        
//        if adjustedContentInsetCache == nil {
//            adjustedContentInsetCache = scrollView.adjustedContentInset
//        }
//
//        if adjustedContentInsetCache == scrollView.adjustedContentInset { return }
//
//        adjustedContentInsetCache = scrollView.adjustedContentInset
//
//        scrollView.contentInset = UIEdgeInsets(top: scrollView.safeAreaInsets.top - scrollView.adjustedContentInset.top, left: 0, bottom: scrollView.safeAreaInsets.bottom - scrollView.adjustedContentInset.bottom, right: 0)
//
//        print("scrollViewDidChangeAdjustedContentInset: \(scrollView.contentInset)")
//        print("scrollViewDidChangeAdjustedContentInset: \(scrollView.adjustedContentInset)")
        
    }
    
    
    // MARK: - UITableViewDataSource
    
    public override func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return messages.count }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // print(tableView.contentOffset)
        
        let message = messages[indexPath.row]
        let sending = message.from?.id != "homebotjs"
        let reuseId = sending ? SendMessageCell.reuseId : ReceiveMessageCell.reuseId
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath)
        
        cell.textLabel?.text = message.text
        
        cell.transform = tableView.transform
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
}
