//
//  ViewController.swift
//  FruitSalad
//
//  Created by Caleb Stultz on 8/19/18.
//  Copyright © 2018 Caleb Stultz. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var classificationLabel: UILabel!
    
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: FruitClassifier().model)
            
            let request = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
                self.processClassifications(for: request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Core ML Model: \(error)")
        }
    }()
    
    func processClassifications(for request: VNRequest, error: Error?) {
        guard let classifications = request.results as? [VNClassificationObservation] else {
            self.classificationLabel.text = "Unable to classify image.\n\(error?.localizedDescription ?? "Error")"
            return
        }
        
        if classifications.isEmpty {
            self.classificationLabel.text = "Nothing recognized.\nPlease try again."
        } else {
            let topClassifications = classifications.prefix(2)
            let descriptions = topClassifications.map { classification in
                return String(format: "%.2f", classification.confidence * 100) + "% – " + classification.identifier
            }
            
            self.classificationLabel.text = "Classifications:\n" + descriptions.joined(separator: "\n")
        }
    }
    
    func updateClassifications(for image: UIImage) {
        classificationLabel.text = "Classifying..."
        
        guard let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue)),
            let ciImage = CIImage(image: image) else {
            print("Something went wrong...\nPlease try again.")
            return
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
        do {
            try handler.perform([classificationRequest])
        } catch {
            print("Failed to perform classification: \(error.localizedDescription)")
        }
    }

    @IBAction func cameraBtnWasPressed(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .default) { _ in
            self.presentPhotoPicker(sourceType: .camera)
        }
        
        let choosePhotoAction = UIAlertAction(title: "Choose Photo", style: .default) { _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)
        }
        
        photoSourcePicker.addAction(takePhotoAction)
        photoSourcePicker.addAction(choosePhotoAction)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(photoSourcePicker, animated: true, completion: nil)
    }
    
    func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        imageView.image = image
        
        //updateClassifications(for: image)
        classificationLabel.text = "Classifying..."
        //将图片转化为base64字符串
        let jpegImage = image.jpegData(compressionQuality: 0.5)
        let base64: String = jpegImage!.base64EncodedString()
        //上传
        let urlString = "http://99.79.112.164//upload_dog_b64"
        let dic: Dictionary = ["img" : base64]
        let json = getJSONStringFromDictionary(dictionary: dic)
        let url = URL(string: urlString)!
        let jsonData = json.data(using: .utf8, allowLossyConversion: false)!

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        Alamofire.request(request).responseJSON {
            (response) in
            if response.result.isSuccess {
                print("成功")
                if let jsonResult = response.result.value as? Dictionary<String, AnyObject> {
                    let category = jsonResult["category"] as! String
                    let desc = jsonResult["desc"] as! String
                    self.classificationLabel.text = String.init(format: "%@\n%@", category, desc)
                }
            } else {
                print("失败")
            }
        }
    }
    /**
     字典转换为JSONString
     - parameter dictionary: 字典参数
     - returns: JSONString
     */
    func getJSONStringFromDictionary(dictionary: Dictionary<String, Any>) -> String {
        if (!JSONSerialization.isValidJSONObject(dictionary)) {
            print("无法解析出JSONString")
            return ""
        }
        let data : NSData? = try? JSONSerialization.data(withJSONObject: dictionary, options: []) as NSData
        if let d = data {
            let JSONString = NSString(data:d as Data,encoding: String.Encoding.utf8.rawValue)
            return JSONString! as String
        }else{
            print("无法解析出JSONString")
            return ""
        }
    }
}

