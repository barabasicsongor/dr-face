//
//  AddFaceViewController.swift
//  DrFace
//
//  Created by Csongor Barabasi on 25/02/2017.
//  Copyright © 2017 Csongor Barabasi. All rights reserved.
//

import UIKit
import Firebase
import ProjectOxfordFace

class AddFaceViewController: UIViewController {
	
	@IBOutlet var image: UIImageView!
	@IBOutlet var name: UITextField!
	var imagePicker: UIImagePickerController!
	@IBOutlet var button: UIButton!
	var chosenImage: UIImage!
	var stat = 0

	var usersStorageRef: FIRStorageReference!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
		view.addGestureRecognizer(tap)
		
		let storage = FIRStorage.storage()
		let storageRef = storage.reference(forURL: "gs://drface-66236.appspot.com")
		
		usersStorageRef = storageRef.child("users")
		
		
    }
	
	func dismissKeyboard() {
		view.endEditing(true)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	
	@IBAction func capture(_ sender: Any) {
		
		if(stat == 0) {
			if UIImagePickerController.isSourceTypeAvailable(.camera) {
				imagePicker =  UIImagePickerController()
				imagePicker.delegate = self
				imagePicker.sourceType = .camera
				
				present(imagePicker, animated: true, completion: nil)
			}
		} else {
			// Upload stuff to firebase
			let userID = name.text
			let imageRef = usersStorageRef.child("\(userID!).jpg")
			
			let client = MPOFaceServiceClient(subscriptionKey: "761a4cf80f454f89b51a3ae26f0dbd58")!
			let data = UIImageJPEGRepresentation(chosenImage, 0.8)!
			
			client.detect(with: data, returnFaceId: true, returnFaceLandmarks: true, returnFaceAttributes: [], completionBlock: { (faces, error) in
				if error != nil {
					print(error)
					return
				}
				
				if(faces?.count)! > 1 || faces == nil {
					print("too many or no faces")
					return
				}
				
				let uploadTask = imageRef.put(data, metadata: nil, completion: { (metadata, error) in
					if error != nil {
						print(error)
						return
					}
				})
				uploadTask.resume()
				
			})
			
			self.navigationController?.popViewController(animated: true)
		}
	}
	
	func useImage(img: UIImage) {
		let resImg = img.scaleImageToSize(newSize: CGSize(width: 300.0, height: 300.0))
		image.image = resImg
		chosenImage = resImg
		button.setImage(UIImage(named: "done"), for: .normal)
		stat = 1
	}

}

extension AddFaceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		let selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
		useImage(img: selectedImage)
		imagePicker.dismiss(animated: true, completion: nil)
	}
}

extension UIImage {
	
	func scaleImageToSize(newSize: CGSize) -> UIImage {
		var scaledImageRect = CGRect.zero
		
		let aspectWidth = newSize.width/size.width
		let aspectheight = newSize.height/size.height
		
		let aspectRatio = max(aspectWidth, aspectheight)
		
		scaledImageRect.size.width = size.width * aspectRatio;
		scaledImageRect.size.height = size.height * aspectRatio;
		scaledImageRect.origin.x = (newSize.width - scaledImageRect.size.width) / 2.0;
		scaledImageRect.origin.y = (newSize.height - scaledImageRect.size.height) / 2.0;
		
		UIGraphicsBeginImageContext(newSize)
		draw(in: scaledImageRect)
		let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return scaledImage!
	}
}

