//
//  AddListViewController.swift
//  Lists
//
//  Created by Bart Jacobs on 29/08/15.
//  Copyright © 2015 Tuts+. All rights reserved.
//

import UIKit
import CloudKit
import SVProgressHUD

protocol AddListViewControllerDelegate {
    func controller(controller: AddListViewController, didAddList list: CKRecord)
    func controller(controller: AddListViewController, didUpdateList list: CKRecord)
}

class AddListViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var delegate: AddListViewControllerDelegate?
    var newList: Bool = true
    
    var list: CKRecord?
    
    // MARK: -
    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        // Update Helper
        newList = list == nil
        
        // Add Observer
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "textFieldTextDidChange:", name: UITextFieldTextDidChangeNotification, object: nameTextField)
    }
    
    override func viewDidAppear(animated: Bool) {
        nameTextField.becomeFirstResponder()
    }
    
    // MARK: -
    // MARK: View Methods
    private func setupView() {
        updateNameTextField()
        updateSaveButton()
    }
    
    // MARK: -
    private func updateNameTextField() {
        if let name = list?.objectForKey("name") as? String {
            nameTextField.text = name
        }
    }
    
    // MARK: -
    private func updateSaveButton() {
        let text = nameTextField.text
        
        if let name = text {
            saveButton.enabled = !name.isEmpty
        } else {
            saveButton.enabled = false
        }
    }
    
    // MARK: -
    // MARK: Actions
    @IBAction func cancel(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func save(sender: AnyObject) {
        // Helpers
        let name = nameTextField.text
        
        // Fetch Private Database
        let privateDatabase = CKContainer.defaultContainer().privateCloudDatabase
        
        if list == nil {
            list = CKRecord(recordType: RecordTypeLists)
        }
        
        // Configure Record
        list?.setObject(name, forKey: "name")
        
        // Show Progress HUD
        SVProgressHUD.show()
        
        // Save Record
        privateDatabase.saveRecord(list!) { (record, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                // Dismiss Progress HUD
                SVProgressHUD.dismiss()
                
                // Process Response
                self.processResponse(record, error: error)
            })
        }
    }
    
    // MARK: -
    // MARK: Notification Handling
    func textFieldTextDidChange(notification: NSNotification) {
        updateSaveButton()
    }
    
    // MARK: -
    // MARK: Helper Methods
    private func processResponse(record: CKRecord?, error: NSError?) {
        var message = ""
        
        if let error = error {
            print(error)
            message = "We were not able to save your list."
            
        } else if record == nil {
            message = "We were not able to save your list."
        }
        
        if !message.isEmpty {
            // Initialize Alert Controller
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
            
            // Present Alert Controller
            presentViewController(alertController, animated: true, completion: nil)
            
        } else {
            // Notify Delegate
            if newList {
                delegate?.controller(self, didAddList: list!)
            } else {
                delegate?.controller(self, didUpdateList: list!)
            }
            
            // Pop View Controller
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
}
