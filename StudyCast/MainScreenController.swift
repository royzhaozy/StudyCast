//
//  ViewController.swift
//  StudyCastv2
//
//  Created by Dennis on 2016-11-03.
//  Copyright © 2016 Apollo. All rights reserved.
//

import UIKit
import Firebase

class MainScreenController: UITableViewController {

    var userCourses = [String]()
    var userNotifications = [[String]]()
    var notificationSectionHeaders = [String]()

    var notificationDataSet: [[NotificationSender]] = [[]]
    
    var notificationSenders = [NotificationSender]()
    
    var userName = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let image = UIImage(named: "SettingsIcon")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(handleSettings))
        tableView.register(GroupCell.self, forCellReuseIdentifier: "userCell")
        tableView.register(Header.self, forHeaderFooterViewReuseIdentifier: "headerId")
        tableView.sectionHeaderHeight = 50
        self.navigationController?.navigationBar.barTintColor = UIColor(r: 61, g: 91, b: 151)
        self.tabBarController?.tabBar.barTintColor = UIColor(r: 61, g: 91, b: 151)
        
        //code to render the original icon (remove applied gray mask which is default)
        let aTabArray: [UITabBarItem] = (self.tabBarController?.tabBar.items)!
        for item in aTabArray {
            item.image = item.image?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
            item.imageInsets = UIEdgeInsetsMake(0, 0, 0, 0)
        }
        
        if FIRAuth.auth()?.currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        }
        userCourses.removeAll()
        notificationDataSet.removeAll()
        notificationSectionHeaders.removeAll()
        fetchNotifications()
        fetchCurrentName()
        tableView.tableFooterView = UIView()
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if FIRAuth.auth()?.currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        } else {
            //notificationDataSet.removeAll()
            //notificationSectionHeaders.removeAll()
            fetchNameSetupNavBar()
            fetchClasses()
            fetchNotifications()
            fetchCurrentName()
        }
    }
    
    func fetchNameSetupNavBar() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        FIRDatabase.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let userDictionary = snapshot.value as? [String: AnyObject] {
                self.navigationItem.rightBarButtonItem?.tintColor = UIColor.white
                self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
                
                let screenSize: CGRect = UIScreen.main.bounds
                
                
                let titleView = UIView()
                titleView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: 40)
                
                let containerView = UIView()
                containerView.translatesAutoresizingMaskIntoConstraints = false
                titleView.addSubview(containerView)
                containerView.leftAnchor.constraint(equalTo: titleView.leftAnchor).isActive = true
                
                let profileImageView = UIImageView()
                profileImageView.translatesAutoresizingMaskIntoConstraints = false
                profileImageView.contentMode = .scaleAspectFill
                profileImageView.layer.cornerRadius = 20
                profileImageView.clipsToBounds = true
                
                if let profileImageUrl = userDictionary["profileImage"] as? String{
                    profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
                }
                containerView.addSubview(profileImageView)
                
                profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
                profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
                profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
                profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
                
                let nameLabel = UILabel()
                containerView.addSubview(nameLabel)
                nameLabel.text = userDictionary["name"] as? String
                nameLabel.translatesAutoresizingMaskIntoConstraints = false
                nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
                nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
                nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
                nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
                
                nameLabel.textColor = UIColor.white
        
                containerView.rightAnchor.constraint(equalTo: titleView.rightAnchor).isActive = true
                containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
                
                self.navigationItem.titleView = titleView
            }
        }, withCancel: nil)
    }
    
    
    func fetchNotifications() {
        
        notificationDataSet.removeAll()
        notificationSectionHeaders.removeAll()
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        FIRDatabase.database().reference().child("users").child(uid).child("notifications").observe(.childAdded, with: { (snapshot) in
            let numClassSections = self.notificationSectionHeaders.count
            let notificationSender = NotificationSender()
            var duplicate = false
            
            if let notificationsDictionary = snapshot.value as? [String: AnyObject] {
                notificationSender.senderName = notificationsDictionary["senderName"] as? String
                notificationSender.groupName = notificationsDictionary["groupName"] as? String
                notificationSender.gid = notificationsDictionary["gid"] as? String
                notificationSender.senderName = notificationsDictionary["senderName"] as? String
                notificationSender.className = notificationsDictionary["class"] as? String
                notificationSender.groupPictureURL = notificationsDictionary["groupPictureURL"] as? String
                notificationSender.nid = notificationsDictionary["nid"] as? String
            }
            
            for i in self.notificationDataSet {
                for g in i {
                    if g.gid == notificationSender.gid {
                        duplicate = true
                    }
                }
            }

            if notificationSender.className == nil {
            }
            else if !duplicate {
                if numClassSections == 0 {
                    self.notificationSectionHeaders.append(notificationSender.className!)
                    self.notificationDataSet.append([notificationSender])
                } else {
                    var i = 0
                    var added = false
                    for g in self.notificationSectionHeaders {
                        if(notificationSender.className)! == g {
                            self.notificationDataSet[i].append(notificationSender)
                            added = true
                        }
                        i += 1
                    }
                    if !added {
                        self.notificationSectionHeaders.append(notificationSender.className!)
                        self.notificationDataSet.append([notificationSender])
                    }
                }
                self.tableView.reloadData()
            } else if duplicate {
//                let noteRef = FIRDatabase.database().reference().child("users").child(uid).child("notifications").child(notificationSender.nid!)
//                noteRef.removeValue()
//                duplicate = false
//                print("removed?")
//                self.notificationDataSet.removeAll()
//                self.notificationSectionHeaders.removeAll()
            }
        })
    }
    

    func fetchClasses() {
        userCourses.removeAll()
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        FIRDatabase.database().reference().child("users").child(uid).child("courses").observe(.childAdded, with: { (snapshot) in
            
            self.userCourses.append(snapshot.value as! String)
            self.tableView.reloadData()
        })
    }
    
    
    func fetchCurrentName() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        FIRDatabase.database().reference().child("users").child(uid).child("name").observe(.value, with: { (snapshot) in
            if let userN = snapshot.value as? String {
                self.userName = userN
            }
            else {
                self.handleLogout()
            }
        })
    }
    
    func handleLogout() {
        
        do {
            try FIRAuth.auth()?.signOut()
        } catch let logoutError {
            print(logoutError)
        }
        let loginController = LoginController()
        //let loginController = ClassSelectController()
        present(loginController, animated: false, completion: nil)
    }
    
    func handleSettings(){
        let settingsController = SettingsController()
        //let settingsController = UserListController()
        let settingsNavController = UINavigationController(rootViewController: settingsController)
        present(settingsNavController, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection
        section: Int) -> Int {
        return notificationDataSet[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! GroupCell
        
        if notificationDataSet.count != 0 {
            cell.textLabel?.numberOfLines = 2;
            cell.textLabel?.text = notificationDataSet[indexPath.section][indexPath.row].senderName! +
                " has invited you to group \n" + notificationDataSet[indexPath.section][indexPath.row].groupName!
        
            if let groupImageURL = notificationDataSet[indexPath.section][indexPath.row].groupPictureURL {
                let url = NSURL(string: groupImageURL)
                URLSession.shared.dataTask(with: url! as URL, completionHandler: { (data, response, error) in
                    if error != nil {
                        print(error!)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        cell.profileImageView.image = UIImage(data: data!)
                        self.tableView.reloadData()
                    }
                }).resume()
            }
        }
        

        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "headerId") as! Header
        if notificationDataSet.count != 0 {
            header.nameLabel.text = notificationSectionHeaders[section]
        }
        return header
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if notificationSectionHeaders.count > 0 {
            tableView.separatorStyle = .singleLine
            tableView.backgroundView = nil
        } else {
            let noDataLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.text = "You have no notifications"
            noDataLabel.textColor = UIColor(r: 61, g: 91, b: 151)
            noDataLabel.textAlignment = .center
            tableView.backgroundView = noDataLabel
            tableView.separatorStyle = .none
        }
        return notificationSectionHeaders.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        if notificationDataSet.count > 0 {
            let alertController = UIAlertController(title: "Group Invite", message: self.notificationDataSet[indexPath.section][indexPath.row].senderName! + " would like to invite you to group " + self.self.notificationDataSet[indexPath.section][indexPath.row].groupName!, preferredStyle: .alert)
            
            let noteRef = FIRDatabase.database().reference().child("users").child(uid).child("notifications").child(self.notificationDataSet[indexPath.section][indexPath.row].nid!)
            
            let okAction = UIAlertAction(title: "Accept", style: UIAlertActionStyle.default) {
                UIAlertAction in
                
                let groupRef = FIRDatabase.database().reference().child("groups").child(self.notificationDataSet[indexPath.section][indexPath.row].gid!).child("members")
                let userRef = FIRDatabase.database().reference().child("users").child(uid).child("groups").child(self.notificationDataSet[indexPath.section][indexPath.row].gid!)
                
                groupRef.updateChildValues([uid : self.userName])
                userRef.updateChildValues(["gid" : self.notificationDataSet[indexPath.section][indexPath.row].gid!])
                userRef.updateChildValues(["groupClass" : self.notificationDataSet[indexPath.section][indexPath.row].className!])
                userRef.updateChildValues(["groupName" : self.notificationDataSet[indexPath.section][indexPath.row].groupName!])
                userRef.updateChildValues(["groupPictureURL" : self.self.notificationDataSet[indexPath.section][indexPath.row].groupPictureURL!])
                
                noteRef.removeValue()
                self.fetchNotifications()
                tableView.reloadData()
                NSLog("OK Pressed")
            }
            
            let cancelAction = UIAlertAction(title: "Decline", style: UIAlertActionStyle.cancel) {
                UIAlertAction in
                
                noteRef.removeValue()
                self.fetchNotifications()
                tableView.reloadData()
                NSLog("OK Pressed")
            }
            
            
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}


