//
//  ViewController.swift
//  ImageAI
//
//  Created by 幸地知哉 on 2020/12/15.
//

import UIKit
import CoreML
import Vision


class ViewController: UIViewController,UINavigationControllerDelegate,
                      UIImagePickerControllerDelegate {

    @IBOutlet weak var photoDisplay: UIImageView!
    
    @IBOutlet weak var photoInfoDisplay: UITextView!
    
    var imagePicker: UIImagePickerController! //空の可能性もあるのでアンラップする
//    アプリを起動直後に読まれる
    override func viewDidLoad() {
        super.viewDidLoad()
        // 写真を撮るためのImagePickerの処理
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
//        アルバムから持ってくるのか、撮影をするのかを選択
        imagePicker.sourceType = .camera
        
    }

    @IBAction func takePhoto(_ sender: Any) {
//        ボタンが押されたらimagePickerを表示する
        present(imagePicker, animated: true, completion: nil)
    }
    
//    撮影が終了したときの処理
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        UIImageのデータタイプに変換する
        photoDisplay.image =  info[.originalImage] as? UIImage
//        もう使わないため非表示にする completion(非表示後に何か動作させるか)を何もしないのでnil
        imagePicker.dismiss(animated: true, completion: nil)
        imageInference(image: (info[.originalImage] as? UIImage)!)
    }
    
    
//    判定処理をする関数
    func imageInference(image:UIImage){
//        利用するmodelを指定する
//        モデルファイルがあればファイルから取得して変数へ入れる
        guard let model = try? VNCoreMLModel(for: AnimalClassifier().model) else {
//            モデルファイルがない場合にはエラーを出力してアプリを落とす
            fatalError("モデルをロードできません")
        }
//        イメージデータを機械学習のモデルに与えるオブジェクトの生成
        let request = VNCoreMLRequest(model: model){
            [weak self] request, error in
            
//            結果を配列で格納する　　写真を識別、分類させるために下記のオブジェクトを利用する
            guard let results = request.results as? [VNClassificationObservation],
//                   初めの一番確率の高いデータを取得して画面表示する
                  let firstResult = results.first else {
                    fatalError("判定できません")
            }
            
//   上記の処理を待たずに逐次実行させるために非同期処理を行う asyncが非同期関数　\()とすると文字列の中で変数を扱え,\nで改行
            DispatchQueue.main.async {
//                画像詳細文を表示する
                self?.photoInfoDisplay.text = "精度 = \(Int(firstResult.confidence * 100))%\n\n　ラベル \((firstResult.identifier))"
            }
            
        }
//        渡されるイメージを設定してリクエストを実行する
        guard let ciImage = CIImage(image: image) else {
            fatalError("画像を変換できません")
        }
        let imageHandler = VNImageRequestHandler(ciImage: ciImage)
//        こちらも非同期処理を行う
        DispatchQueue.global(qos: .userInteractive).async {
            do{
                try imageHandler.perform([request])
            }catch{
                    print("エラー\(error)")
                }
            }
    
    }

}
