//
//  ListsViewController.swift
//  Lists
//
//  Created by Bart Jacobs on 21/08/15.
//  Copyright © 2015 Tuts+. All rights reserved.
//

import UIKit
import CloudKit
import SVProgressHUD

let RecordTypeLists = "Lists"

let SegueListDetail = "ListDetail"

class ListsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AddListViewControllerDelegate {
    static let ListCell = "ListCell"
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var lists = [CKRecord]()
    
    var selection: Int?
    
    // MARK: -
    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        fetchLists()
    }
    
    // MARK: -
    // MARK: Segue Life Cycle
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
        case SegueListDetail:
            // Fetch Destination View Controller
            let addListViewController = segue.destinationViewController as! AddListViewController
            
            // Configure View Controller
            addListViewController.delegate = self
            
            if let selection = selection {
                // Fetch List
                let list = lists[selection]
                
                // Configure View Controller
                addListViewController.list = list
            }
        default:
            break
        }
    }
    
    /*
    private func fetchUserRecordID() {
        // Fetch Default Container
        let defaultContainer = CKContainer.defaultContainer()
        
        // Fetch User Record
        defaultContainer.fetchUserRecordIDWithCompletionHandler { (recordID, error) -> Void in
            if let responseError = error {
                print(responseError)
                
            } else if let userRecordID = recordID {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.fetchUserRecord(userRecordID)
                })
            }
        }
    }
    
    private func fetchUserRecord(recordID: CKRecordID) {
        // Fetch Default Container
        let defaultContainer = CKContainer.defaultContainer()
        
        // Fetch Private Database
        let privateDatabase = defaultContainer.privateCloudDatabase
        
        // Fetch User Record
        privateDatabase.fetchRecordWithID(recordID) { (record, error) -> Void in
            if let responseError = error {
                print(responseError)
                
            } else if let userRecord = record {
                print(userRecord)
            }
        }
    }
    */
    
    // MARK: -
    // MARK: Table View Data Source Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lists.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Dequeue Reusable Cell
        let cell = tableView.dequeueReusableCellWithIdentifier(ListsViewController.ListCell, forIndexPath: indexPath)
        
        // Configure Cell
        cell.accessoryType = .DetailDisclosureButton
        
        // Fetch Record
        let list = lists[indexPath.row]
        
        if let listName = list.objectForKey("name") as? String {
            // Configure Cell
            cell.textLabel?.text = listName
            
        } else {
            cell.textLabel?.text = "-"
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        guard editingStyle == .Delete else { return }
        
        // Fetch Record
        let list = lists[indexPath.row]
        
        // Delete Record
        deleteRecord(list)
    }
    
    // MARK: -
    // MARK: Table View Delegate Methods
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        // Save Selection
        selection = indexPath.row
        
        // Perform Segue
        performSegueWithIdentifier(SegueListDetail, sender: self)
    }
    
    // MARK: -
    // MARK: Add List View Controller Delegate Methods
    func controller(controller: AddListViewController, didAddList list: CKRecord) {
        // Add List to Lists
        lists.append(list)
        
        // Sort Lists
        sortLists()
        
        // Update Table View
        tableView.reloadData()
        
        // Update View
        updateView()
    }
    
    func controller(controller: AddListViewController, didUpdateList list: CKRecord) {
        // Sort Lists
        sortLists()
        
        // Update Table View
        tableView.reloadData()
    }
    
    // MARK: -
    // MARK: View Methods
    private func setupView() {
        tableView.hidden = true
        messageLabel.hidden = true
        activityIndicatorView.startAnimating()
    }
    
    private func updateView() {
        let hasRecords = lists.count > 0
        
        tableView.hidden = !hasRecords
        messageLabel.hidden = hasRecords
        activityIndicatorView.stopAnimating()
    }
    
    // MARK: -
    // MARK: Helper Methods
    private func fetchLists() {
        // Fetch Private Database
        let privateDatabase = CKContainer.defaultContainer().privateCloudDatabase
        
        // Initialize Query
        let query = CKQuery(recordType: RecordTypeLists, predicate: NSPredicate(format: "TRUEPREDICATE"))
        
        // Configure Query
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        // Perform Query
        privateDatabase.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                // Process Response on Main Thread
                self.processResponseForQuery(records, error: error)
            })
        }
    }
    
    private func processResponseForQuery(records: [CKRecord]?, error: NSError?) {
        var message = ""
        
        if let error = error {
            print(error)
            message = "Error Fetching Records"
            
        } else if let records = records {
            lists = records
            
            if lists.count == 0 {
                message = "No Records Found"
            }
            
        } else {
            message = "No Records Found"
        }
        
        if message.isEmpty {
            tableView.reloadData()
        } else {
            messageLabel.text = message
        }
        
        updateView()
    }
    
    // MARK: -
    private func deleteRecord(list: CKRecord) {
        // Fetch Private Database
        let privateDatabase = CKContainer.defaultContainer().privateCloudDatabase
        
        // Show Progress HUD
        SVProgressHUD.show()
        
        // Delete List
        privateDatabase.deleteRecordWithID(list.recordID) { (recordID, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                // Dismiss Progress HUD
                SVProgressHUD.dismiss()
                
                // Process Response
                self.processResponseForDeleteRequest(list, recordID: recordID, error: error)
            })
        }
    }
    
    private func processResponseForDeleteRequest(record: CKRecord, recordID: CKRecordID?, error: NSError?) {
        var message = ""
        
        if let error = error {
            print(error)
            message = "We are unable to delete the list."
            
        } else if recordID == nil {
            message = "We are unable to delete the list."
        }
        
        if message.isEmpty {
            // Calculate Row Index
            let index = lists.indexOf(record)
            
            if let index = index {
                // Update Data Source
                lists.removeAtIndex(index)
                
                if lists.count > 0 {
                    // Update Table View
                    tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Right)
                    
                } else {
                    // Update Message Label
                    messageLabel.text = "No Records Found"
                    
                    // Update View
                    updateView()
                }
            }
            
        } else {
            // Initialize Alert Controller
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
            
            // Present Alert Controller
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    private func sortLists() {
        lists.sortInPlace {
            var result = false
            let name0 = $0.objectForKey("name") as? String
            let name1 = $1.objectForKey("name") as? String
            
            if let listName0 = name0, listName1 = name1 {
                result = listName0.localizedCaseInsensitiveCompare(listName1) == .OrderedAscending
            }
            
            return result
        }
    }
    
}

