// Created by Roman Voinitchi on 12/10/20
// 


import UIKit
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var stackOfImages: UIStackView!
    @IBOutlet weak var checkImageView: UIImageView!
    
    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    let textRecognitionWorkQueue = DispatchQueue(label: "TextRecognitionQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    private var loaderView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTextRequest()
    }
    
    @IBAction func onCheckTap(_ sender: UIButton) {
        if let image = sender.image(for: .normal), let cgImage = image.cgImage {
            setLoader()
            self.textView.text = ""
            checkImageView.image = image
            recognizeImage(cgImage: cgImage)
        }
    }
    
}

private extension ViewController {
    
    func recognizeImage(cgImage: CGImage) {
        textRecognitionWorkQueue.async {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try requestHandler.perform([self.textRecognitionRequest])
            } catch {
                self.removeLoader()
                print(error)
            }
        }
    }
    
    func setTextRequest() {
        textRecognitionRequest = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

            var detectedText = ""
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                detectedText += topCandidate.string
                detectedText += "\n"
            }
            
            DispatchQueue.main.async {
                self.removeLoader()
                self.textView.text += detectedText
            }
        }
        textRecognitionRequest.minimumTextHeight = 0.013
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = false
        textRecognitionRequest.recognitionLanguages = ["ru", "en", "de"]
    }
    
    func setLoader() {
        loaderView = UIView(frame: UIScreen.main.bounds)
        loaderView!.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.view.addSubview(loaderView!)
    }
    
    func removeLoader() {
        self.loaderView?.removeFromSuperview()
        self.loaderView = nil
    }
}
