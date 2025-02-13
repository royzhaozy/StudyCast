//
//  AddGroupController+handlers.swift
//  StudyCast
//
//  Created by Dennis Huebert on 2016-11-18.
//  Copyright © 2016 Austin Phillips. All rights reserved.
//

import UIKit
import Firebase


extension AddGroupController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func handleSelectProfileImageView() {
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage{
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage{
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            groupImageView.image = selectedImage
            groupImageView.layer.cornerRadius = groupImageView.frame.size.width/2
            groupImageView.clipsToBounds = true
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func fetchClasses() {
        userCourses.removeAll()
        let uid = FIRAuth.auth()?.currentUser?.uid
        FIRDatabase.database().reference().child("users").child(uid!).child("courses").observe(.childAdded, with: { (snapshot) in
            self.userCourses.append(snapshot.value as! String)
        })
    }
    
    func fetchUserName( closure:((String) -> Void)?) -> Void {
        let uid = FIRAuth.auth()?.currentUser?.uid
        let ref = FIRDatabase.database().reference()
        ref.child("users").child(uid!).child("name").observe(.value, with: { (snapshot) in
            self.userName = snapshot.value as! String
            closure!(self.userName)
        })
    }
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return userCourses.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return userCourses[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 20
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        groupClass = userCourses[row]
    }
    
    func handleCreateGroup() {
    
        guard let groupName = nameTextField.text else {
            print("Form is not valid")
            return
        }
        
        
        //getting all references to the DB
        var userName: String = ""
        let gid = UUID().uuidString
        let user = FIRAuth.auth()?.currentUser
        let uid = user?.uid
        let ref = FIRDatabase.database().reference()
        let groupUsersRef = ref.child("groups").child(gid).child("members")
        let groupRef = ref.child("groups").child(gid)
        let userRef = ref.child("users").child(uid!).child("groups").child(gid)
        FIRDatabase.database().reference().child("users").child(uid!).observeSingleEvent(of: .value, with: { (snapshot) in
            if let userDictionary = snapshot.value as? [String: AnyObject] {
                userName = userDictionary["name"] as! String
            }
            
            
        })
        
        userRef.updateChildValues(["gid" : gid])
        
        
        
        
        if groupName != "" {
            groupRef.updateChildValues(["groupName" : groupName])
            userRef.updateChildValues(["groupName" : groupName])
        } else {
            let alert = UIAlertController(title: "Group Name", message: "Must enter a Group Name.",
                                          preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        fetchUserName( closure: {(name) in
            groupUsersRef.updateChildValues([uid! : name])
        })

        //storage of group image
        let groupImageName = UUID().uuidString
        let storage = FIRStorage.storage().reference().child("groupImages").child("\(groupImageName).jpg")
        if let imageToUpload = UIImageJPEGRepresentation(self.groupImageView.image!, 0.1) {
            storage.put(imageToUpload, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    print(error!)
                    return
                }
                if let groupImage = metadata?.downloadURL()?.absoluteString {
                    self.imgURL = groupImage
                    groupRef.updateChildValues(["groupPictureURL" : groupImage])
                    userRef.updateChildValues(["groupPictureURL" : groupImage])
                    
                    DispatchQueue.main.async {
                        let groupForInvite = Group(id: gid, name: groupName, photoUrl: self.imgURL, users: nil, groupClass: self.groupClass)
                        
                        let inviteController = UserListController()
                        inviteController.setInfoForInvite(cn: self.groupClass, group: groupForInvite, sn: userName)
                        let inviteNavController = UINavigationController(rootViewController: inviteController)
                        self.present(inviteNavController, animated: true, completion: nil)
                    }
                }
            })
        }
        if groupClass == "" {
            groupClass = userCourses[0]
        }
        groupRef.updateChildValues(["groupClass" : groupClass])
        userRef.updateChildValues(["groupClass" : groupClass])
        

        
        

    }
    
    func handleBack() {
        self.dismiss(animated: true, completion: nil)
    }


    func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
}
