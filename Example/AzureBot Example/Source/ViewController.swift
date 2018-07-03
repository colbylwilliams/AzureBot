//
//  ViewController.swift
//  AzureBot Example
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import UIKit
import AzureBot

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
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
            //expectation.fulfill()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

