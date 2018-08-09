//
//  ViewController.swift
//  ImageCollectionSample
//
//  Created by Masuhara on 2018/08/09.
//  Copyright © 2018年 Ylab, Inc. All rights reserved.
//

import UIKit
import NCMB
import SVProgressHUD
import Kingfisher

class ViewController: UIViewController, UICollectionViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var images = [NCMBObject]()
    
    @IBOutlet var imageCollectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageCollectionView.dataSource = self
        
        loadImages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // CollectionViewのコード
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        let imageView = cell.viewWithTag(1) as! UIImageView
        
        // Kingfisherを使ってクラウドから画像を表示するところを簡単に
        let urlString = images[indexPath.row].object(forKey: "url") as! String
        imageView.kf.setImage(with: URL(string: urlString))
        
        return cell
    }
    
    // 画像追加のボタン
    @IBAction func selectImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    // UIImagePickerControllerで画像が選択されたときに呼ばれるdelegateメソッド
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let editedImage = info[UIImagePickerControllerEditedImage] as! UIImage
        uploadImage(image: editedImage)
        picker.dismiss(animated: true, completion: nil)
    }
    
    // NCMBにアップロードするメソッド。メソッドを呼ぶ際にimagePickerで取得したimageを渡す
    func uploadImage(image: UIImage) {
        SVProgressHUD.show()
        let data = UIImagePNGRepresentation(image)!
        let file = NCMBFile.file(with: data) as! NCMBFile
        file.saveInBackground { (error) in
            if error != nil {
                SVProgressHUD.showError(withStatus: error?.localizedDescription)
            } else {
                self.saveImageInfo(file: file)
            }
        }
    }
    
    // アップロードした画像ファイルを読み込み
    func loadImages() {
        let query = NCMBQuery(className: "Image")
        query?.findObjectsInBackground({ (result, error) in
            if error != nil {
                SVProgressHUD.showError(withStatus: error?.localizedDescription)
            } else {
                if result != nil {
                    self.images = result as! [NCMBObject]
                    self.images.reverse()
                    self.imageCollectionView.reloadData()
                }
            }
        })
    }
    
    // 画像アップロードが終わったら、画像に関する情報をデータベースに保存
    func saveImageInfo(file: NCMBFile) {
        let object = NCMBObject(className: "Image")
        // Kingfisherが参照できるURLの形にしておく
        let imageUrl = "https://mbaas.api.nifcloud.com/2013-09-01/applications/D2vf4CPZU4cSnrQU/publicFiles/\(file.name!)"
        object?.setObject(imageUrl, forKey: "url")
        // 他にも情報を保存したければこのように追加
        // object?.setObject("山田太郎", forKey: "username")
        object?.saveInBackground({ (error) in
            if error != nil {
                SVProgressHUD.showError(withStatus: error?.localizedDescription)
            } else {
                SVProgressHUD.dismiss()
                self.loadImages()
            }
        })
    }
    
}

