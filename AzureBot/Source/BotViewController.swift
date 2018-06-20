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
    
    var messages: [Activity] { return BotClient.shared.messages }

    //@IBOutlet var messageToolbar: MessageToolbar!
    //public override var inputAccessoryView: UIView? { return messageToolbar }
    
    @IBOutlet var messageBar: MessageBar!
    public override var inputAccessoryView: UIView? { return messageBar }
    
    
    public override var canBecomeFirstResponder: Bool { return true }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        
        setupObserver()
        
        BotClient.shared.start { r in
            if let conversation = r.resource {
                print(conversation.conversationId ?? "")
                print(conversation.streamUrl ?? "")
            } else if let error = r.error {
                print("Error: " + error.localizedDescription)
            }
        }
        
        self.becomeFirstResponder()
    }
    
    fileprivate func setupObserver() {
        observer = NotificationCenter.default.addObserver( forName: .BotClientDidAddMessageNotification, object: BotClient.shared, queue: OperationQueue.main) { [weak self] notification in
            guard let `self` = self else { return }
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
    
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        print(messageBar.frame)
        
        if tableView.contentInset == UIEdgeInsets.zero {
            print("z 0 : \(tableView.contentInset)")
            tableView.contentInset = UIEdgeInsets(top: max(tableView.safeAreaInsets.top, messageBar.frame.height) - tableView.adjustedContentInset.top, left: 0, bottom: tableView.safeAreaInsets.bottom - tableView.adjustedContentInset.bottom, right: 0)
            print("z 1 : \(tableView.contentInset)")
        }
    }
    
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
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
