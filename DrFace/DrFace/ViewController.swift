//
//  ViewController.swift
//  DrFace
//
//  Created by Csongor Barabasi on 25/02/2017.
//  Copyright © 2017 Csongor Barabasi. All rights reserved.
//

import UIKit
import Firebase
import MBProgressHUD
import SCLAlertView
import ProjectOxfordFace

class ViewController: UIViewController {
	
	@IBOutlet var label : UILabel!
	@IBOutlet var doctorImage: UIImageView!
	@IBOutlet var addButton: UIButton!
	@IBOutlet var recognizeButton: UIButton!
	
	var finalName: String!
	
	var faces1: MPOFace!
	var faces2: MPOFace!
	
	var i = 0
	
	let client = MPOFaceServiceClient(subscriptionKey: "761a4cf80f454f89b51a3ae26f0dbd58")!
	
	var imageURLs: [String] = ["https://firebasestorage.googleapis.com/v0/b/drface-66236.appspot.com/o/users%2FCsongor.jpg?alt=media&token=ba59833e-d78f-4244-957b-3d8de0ceffc2", "https://firebasestorage.googleapis.com/v0/b/drface-66236.appspot.com/o/users%2FGoogle%20Photo%201.jpg?alt=media&token=c368831d-b401-4bf2-a7dd-9abadd21c22b"]
	var imageNames: [String] = ["Csongor", "Google Photo 1"]
	
	var imageData: [Data]!
	
	var imagePicker: UIImagePickerController!
	var chosenImage: UIImage!
	var chosenImageData: Data!

	override func viewDidLoad() {
		super.viewDidLoad()
		
		downloadData()
		
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(true)
		self.navigationController?.setNavigationBarHidden(true, animated: false)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func downloadData() {
		imageData = []
		// Get all images from server
		
		MBProgressHUD.showAdded(to: self.view, animated: true)
		
		let storage = FIRStorage.storage()
		
		for url in imageURLs {
			
			let httpsReference = storage.reference(forURL: url)
			
			httpsReference.data(withMaxSize: 1 * 1024 * 1024) { (data, error) -> Void in
				if (error != nil) {
					print(error!)
					return
				} else {
					
					
					self.imageData.append(data!)
				}
			}
		}
		MBProgressHUD.hide(for: self.view, animated: true)
	}
	
	
	@IBAction func addFace(_ sender: Any) {
		let vc: AddFaceViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddFaceViewController") as! AddFaceViewController
		self.navigationController?.pushViewController(vc, animated: true)
	}

	@IBAction func recognizeFace(_ sender: Any) {
		if UIImagePickerController.isSourceTypeAvailable(.camera) {
			imagePicker =  UIImagePickerController()
			imagePicker.delegate = self
			imagePicker.sourceType = .camera
			
			present(imagePicker, animated: true, completion: nil)
		}
	}
	
	func useImage(img: UIImage) {
		finalName = ""
		i = 0
		
		let resImg = img.scaleImageToSize(newSize: CGSize(width: 300.0, height: 300.0))
		chosenImage = resImg
		chosenImageData = UIImageJPEGRepresentation(chosenImage, 0.8)
		// Check the image taken with all the other images
		
		MBProgressHUD.showAdded(to: self.view, animated: true)
		
		for data in imageData {
			self.verify(storageImgData: data, name: self.imageNames[self.i])
			self.i = self.i + 1
		}
		
	}
	
	func verify(storageImgData: Data, name: String) {
		
		client.detect(with: chosenImageData, returnFaceId: true, returnFaceLandmarks: true, returnFaceAttributes: []) { (faces, error) in
			if error != nil {
				print(error!)
				return
			}
			
			if(faces?.count)! > 1 || faces == nil {
				print("too many or no faces")
				return
			}
			
			self.faces1 = faces![0]
			
			self.client.detect(with: storageImgData, returnFaceId: true, returnFaceLandmarks: true, returnFaceAttributes: [], completionBlock: { (faces, error) in
				if error != nil {
					print(error!)
					return
				}
				
				self.faces2 = faces![0]
				
				self.client.verify(withFirstFaceId: self.faces1.faceId, faceId2: self.faces2.faceId, completionBlock: { (result, error) in
					if error != nil {
						print(error!)
						return
					}
					
					if result!.isIdentical {
						// The person is the same
						print("Same person")
						print(name)
						self.finalName = name
						
						MBProgressHUD.hide(for: self.view, animated: true)
						SCLAlertView().showInfo("Recognized person", subTitle: name)
						return
						
					} else {
						// Person is not the same
						print("Not same person")
						print(name)
					}
					
				})
				
			})
			
			
		}
		
	}

}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		let selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
		useImage(img: selectedImage)
		imagePicker.dismiss(animated: true, completion: nil)
	}
}


