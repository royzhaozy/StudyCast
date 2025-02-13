//
//  ClassSelectController+handlers.swift
//  StudyCastv2
//
//  Created by Dennis on 2016-11-04.
//  Copyright © 2016 Apollo. All rights reserved.
//

import UIKit
import Firebase


extension ClassSelectController {
    
    func handleDone() {
        if let user = FIRAuth.auth()?.currentUser {
            let uid = user.uid
            let ref = FIRDatabase.database().reference()
            var classRef = ref
            for pickedClass in pickedClassesDataSet {
                classRef = ref.child(pickedClass).child(uid)
                classRef.updateChildValues(["uid" : uid])
            }
            
            self.addUserCourses(uid, values: pickedClassesDataSet.indexedDictionary)
        } else {
            print("User is not currently signed in")
        }
    }
    
    fileprivate func addUserCourses(_ uid: String, values: [String : AnyObject]) {
        
        let ref = FIRDatabase.database().reference()
        let coursesReference = ref.child("users").child(uid).child("courses")
        coursesReference.setValue(nil, withCompletionBlock: {(error, ref) in
            if error != nil {
                print(error!)
            } else {

            }
        })
        coursesReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil{
                print(err!)
                return
            } else {
                self.view.window!.rootViewController?.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    func handleTap(recognizer: UITapGestureRecognizer){

        if recognizer.state == UIGestureRecognizerState.ended {
            let tapLocation = recognizer.location(in: self.facultyTableView)
            if let tapIndexPath = self.facultyTableView.indexPathForRow(at: tapLocation) {
                if let tappedCell = self.facultyTableView.cellForRow(at: tapIndexPath) as? UserCell {
                    
                    var i = numCells - 1
                    var added = false
                    while i >= 0 {
                        if ((tappedCell.textLabel?.text)! == pickedClassesDataSet[i]) {
                            added = true
                            break
                        }
                        i -= 1
                    }
                    if !added {
                        numCells += 1
                        pickedClassesDataSet.append("\(self.currentFaculty.uppercased()) \((tappedCell.textLabel?.text)!)")
                        userClassesTableView.reloadData()
                    }
                }
            }
        }
    }
    
    func handleTapBottom(recognizer: UITapGestureRecognizer){
        
        if recognizer.state == UIGestureRecognizerState.ended {
            let tapLocation = recognizer.location(in: self.userClassesTableView)
            if let tapIndexPath = self.userClassesTableView.indexPathForRow(at: tapLocation) {
                
                pickedClassesDataSet.remove(at: tapIndexPath.row)
                numCells -= 1
                userClassesTableView.reloadData()
            }
        }
    }
}
