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
    private var isVisible: Bool {
        return isViewLoaded && view.window != nil
    }
//    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet var messageToolbar: MessageToolbar!
    
    var messages: [Activity] { return BotClient.shared.messages }
    
    
    public override func loadView() {
        super.loadView()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        //tableView.register(SendMessageCell.self, forCellReuseIdentifier: SendMessageCell.reuseId)
        //tableView.register(ReceiveMessageCell.self, forCellReuseIdentifier: ReceiveMessageCell.reuseId)
        
        tableView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        
        //view.addSubview(messageToolbar)
//        messageTextView.transform = tableView.transform
        
        observer = NotificationCenter.default.addObserver( forName: .BotClientDidAddMessageNotification, object: BotClient.shared, queue: OperationQueue.main) { [weak self] notification in
            print("update")
            guard let `self` = self else { return }
            if self.isVisible {
                self.tableView.reloadData()
            } else {
                self.needsUpdateViewOnAppearance = true
            }
        }
        
        BotClient.shared.start { r in
            if let conversation = r.resource {
                print("...... conversationId : " + (conversation.conversationId ?? "nil"))
                print("................ eTag : " + (conversation.eTag ?? "nil"))
                print(".......... expires_in : \(conversation.expires_in ?? 0)")
                print(".. referenceGrammarId : " + (conversation.referenceGrammarId ?? "nil"))
                print("........... streamUrl : " + (conversation.streamUrl ?? "nil"))
                print("............... token : " + (conversation.token ?? "nil"))
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
    
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    
    // MARK: - UITableViewDataSource
    
    public override func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return messages.count }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let message = messages[indexPath.row]
        let sending = message.from?.id != "homebotjs"
        let reuseId = sending ? SendMessageCell.reuseId : ReceiveMessageCell.reuseId
        
        print(message.text ?? "nope")
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath)
        
        cell.textLabel?.text = message.text
        
        cell.transform = tableView.transform
        
        return cell
    }
    
    
    // MARK: - UITableViewDelegate
    
    // public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { }
    // public override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat { }
    
}
