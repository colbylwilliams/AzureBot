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

    @IBOutlet var messageBar: MessageBar!
    public override var inputAccessoryView: UIView? { return messageBar }
    
    public override var canBecomeFirstResponder: Bool { return true }
    
    
    // MARK: - ViewController lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // flip the tableView upside down so cells are added to the 'bottom'
        tableView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        
        setupObservers()
        
        BotClient.shared.start { r in
            if let _ = r.resource {
                print(r.printResponseData())
            } else if let error = r.error {
                print("Error: " + error.localizedDescription)
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
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if tableView.contentInset == UIEdgeInsets.zero {
            updateContentInset(inset: getContentInset())
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
        // BotClient Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(handleMessageAdded(notification:)), name: .BotClientDidAddMessageNotification, object: BotClient.shared)
    }
    
    
    @objc
    func handleKeyboardNotification(notification: Notification) {
        switch notification.name {
        // case .UIKeyboardWillShow: print("UIKeyboardWillShow")
        // case .UIKeyboardDidShow: print("UIKeyboardDidShow")
        // case .UIKeyboardWillHide: print("UIKeyboardWillHide")
        // case .UIKeyboardDidHide: print("UIKeyboardDidHide")
        // case .UIKeyboardWillChangeFrame: print("UIKeyboardWillChangeFrame")
        case .UIKeyboardDidChangeFrame:
            // print("UIKeyboardDidChangeFrame")
            if let rect = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect {
                DispatchQueue.main.async {
                    //print("r \(rect) i \(self.tableView.safeAreaInsets)")
                    // print(self.tableView.contentInset)
                    let inset = self.tableView.contentInset
                    self.updateContentInset(inset: UIEdgeInsets(top: (rect.height + 10) - self.tableView.safeAreaInsets.top, left: inset.left, bottom: inset.bottom, right: inset.right))
                }
            }
        default: return
        }
    }
    
    func updateContentInset(inset: UIEdgeInsets) {
        //guard self.isVisible else { return }
        // print("update")
        //print("s \(tableView.safeAreaInsets)")
        //print("s \(tableView.safeAreaLayoutGuide.bottomAnchor)")
        
        UIView.animate(withDuration: 0.3, animations: {
            self.tableView.contentInset = inset
        }, completion: { f in
            if self.messages.count > 0 {
                self.tableView.scrollToRow(at: IndexPath.init(row: 0, section: 0), at: .top, animated: true)
            }
        })
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
    

    func getContentInset() -> UIEdgeInsets {
        return UIEdgeInsets(top: max(tableView.safeAreaInsets.top, messageBar.frame.height) - tableView.adjustedContentInset.top, left: 0, bottom: tableView.safeAreaInsets.bottom - tableView.adjustedContentInset.bottom, right: 0)
    }

    
    // MARK: - UITableViewDataSource
    
    public override func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return messages.count }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // print(tableView.contentOffset)
        
        let message = messages[indexPath.row]
        let sending = message.from?.id == BotClient.shared.currentUser.id
        let reuseId = sending ? SendMessageCell.reuseId : ReceiveMessageCell.reuseId
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath)
        
        cell.textLabel?.text = message.text
        
        cell.transform = tableView.transform
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
}

extension BotViewController {
    
    public static func create() -> BotViewController {
        
        let storyboard = UIStoryboard(name: "AzureBot", bundle: Bundle(for: BotViewController.self))
        
        let botController = storyboard.instantiateViewController(withIdentifier: "BotViewController")

        return botController as! BotViewController
    }
}
