//
//  AddGameVC.swift
//  queRule
//
//  Created by Timple Soft on 02/12/16.
//  Copyright © 2016 TimpleSoft. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

protocol AddGameVCDelegate {
    func didAddGame()
}

class AddGameVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var gameImageView : UIImageView!
    @IBOutlet weak var borrowedSwitch : UISwitch!
    @IBOutlet weak var txtTitle : UITextField!
    @IBOutlet weak var txtBorrowedTo : UITextField!
    @IBOutlet weak var txtBorrowedDate : UITextField!
    @IBOutlet weak var btnDelete : UIButton!
    
    var context : NSManagedObjectContext?
    var imagePickerController = UIImagePickerController()
    var cameraPermissions : Bool = false
    var delegate : AddGameVCDelegate?
    var game : Game?
    var datePicker : UIDatePicker!
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        /* Keyboard */
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        view.addGestureRecognizer(tapGesture)
        
        let takePictureGesture = UITapGestureRecognizer(target: self, action: #selector(takePictureTapped))
        gameImageView.addGestureRecognizer(takePictureGesture)
        
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        
        datePicker = UIDatePicker(frame: CGRect(x: 0, y: 210, width: 320, height: 216))
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(datePickerChangedValue), for: .valueChanged)
        txtBorrowedDate.inputView = datePicker
        
        if game == nil {
            
            self.title = "Añadir juego"
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonPressed))
            self.btnDelete.isHidden = true
            self.borrowedSwitch.isOn = false
            
        } else {
        
            self.title = "Detalles"
            self.txtTitle.text = game?.title
            if let borrowed = game?.borrowed {
                self.borrowedSwitch.isOn = borrowed
            }
            self.txtBorrowedTo.text = game?.borrowedTo
            if let borrowedDate = game?.borrowedDate as Date? {
                self.txtBorrowedDate.text = dateFormatter.string(from: borrowedDate)
            }
            
            if let imageData = game?.image as? Data{
                self.gameImageView.image = UIImage(data:imageData)
            }
            
            self.btnDelete.isHidden = false
            
            if !borrowedSwitch.isOn {
                txtBorrowedTo.isEnabled = false
                txtBorrowedDate.isEnabled = false
            }

        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkPermission()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if game != nil {
            saveGame()
        }
    }
    
    
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardTime = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        UIView.animate(withDuration: keyboardTime) {
            self.view.frame.origin.y = -(keyboardFrame.height)
        }
    }
    
    
    func keyboardWillHide(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardTime = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        UIView.animate(withDuration: keyboardTime) {
            self.view.frame.origin.y = 0
        }
    }
    
    
    func viewTapped(){
        for view in self.view.subviews {
            if let txtField = view as? UITextField {
                txtField.resignFirstResponder()
            }
        }
    }
    
    
    func checkPermission () {
        
        let cameraMediaType = AVMediaTypeVideo
        let cameraAuthorisationStatus = AVCaptureDevice.authorizationStatus(forMediaType: cameraMediaType)
        
        switch cameraAuthorisationStatus {
        case .authorized:
            cameraPermissions = true
        case .restricted, .denied:
            cameraPermissions = false
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: cameraMediaType, completionHandler: { (granted) in
                self.cameraPermissions = granted
            })
        }
        
    }
    
    func takePictureTapped() {
    
        guard cameraPermissions else {
            let permissionAlertController = UIAlertController(title: "Permisos", message: "No tiene permiso para acceder a la cámara del dispositivo. Puede cambiarlo en Ajustes", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
            permissionAlertController.addAction(okAction)
            present(permissionAlertController, animated: true, completion: nil)
            
            return
        }
        
        let alertController = UIAlertController(title: "Añadir fotos del videojuego", message:"", preferredStyle: .actionSheet)

        let cameraRollOption = UIAlertAction(title: "Carrete", style: .default) { (alertAction) in
            self.imagePickerController.sourceType = .photoLibrary
            self.present(self.imagePickerController, animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        
        if UIImagePickerController.isCameraDeviceAvailable(.rear) {
            let cameraOption = UIAlertAction(title: "Cámara", style: .default) { (alertAction) in
                self.imagePickerController.sourceType = .camera
                self.present(self.imagePickerController, animated: true, completion: nil)
            }
            alertController.addAction(cameraOption)
        }
        
        alertController.addAction(cameraRollOption)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    
    func datePickerChangedValue() {
        txtBorrowedDate.text = dateFormatter.string(from: datePicker.date)
    }
    
    
    func saveButtonPressed(){
        saveGame()
        dismiss(animated: true, completion: nil)
    }
    
    
    func cancelButtonPressed(){
        dismiss(animated: true, completion: nil)
    }
    
    
    func saveGame() {
        
        if let context = context {
            
            var editedGame : Game? = nil
            if game == nil {
                editedGame = Game(context: context)
            } else{
                editedGame = game
            }
            if let editedGame = editedGame {
                
                editedGame.dateCreated = NSDate()
                editedGame.title = txtTitle.text
                editedGame.borrowed = borrowedSwitch.isOn
                if let image = gameImageView.image {
                    editedGame.image = UIImagePNGRepresentation(image) as NSData?
                } else {
                    editedGame.image = NSData()
                }
                
                if editedGame.borrowed {
                    
                    if let borrowedTo = txtBorrowedTo.text {
                        editedGame.borrowedTo = borrowedTo.uppercased()
                    }
                    if let strDate = txtBorrowedDate.text {
                        editedGame.borrowedDate = dateFormatter.date(from: strDate) as NSDate?
                    }
                    
                } else {
                    editedGame.borrowedTo = nil
                    editedGame.borrowedDate = nil
                }
                
                do {
                    try context.save()
                    self.delegate?.didAddGame()
                } catch {
                    print("Error guardando en Core Data")
                }
                
            }
            
        }
        
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.gameImageView.image = pickedImage
        }
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        if sender.isOn {
            txtBorrowedTo.isEnabled = true
            txtBorrowedDate.isEnabled = true
            txtBorrowedDate.text = dateFormatter.string(from: Date())
        } else {
            txtBorrowedTo.isEnabled = false
            txtBorrowedDate.isEnabled = false
            txtBorrowedDate.text = ""
            txtBorrowedTo.text = ""
        }
    }
    
    
    @IBAction func deletePressed(){
        if let context = context {
            context.delete(game!)
            game = nil
            delegate?.didAddGame()
            let _ = navigationController?.popViewController(animated: true)
        }
    }
    
    
    
}













