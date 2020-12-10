// Created by Roman Voinitchi on 12/10/20
// 


import UIKit
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var stackOfImages: UIStackView!
    
    private var imagesToScan = [UIImage]()
    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    let textRecognitionWorkQueue = DispatchQueue(label: "TextRecognitionQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTextRequest()
        setupImages()
//        setRandomImage()
        recognizeFirstImage()
    }
    
}

private extension ViewController {
    func recognizeFirstImage() {
        if imagesToScan.count > 0, let first = imagesToScan.first, let cgImage = first.cgImage {
            imagesToScan.removeFirst()
            recognizeImage(cgImage: cgImage)
        }
    }
    
    func recognizeImage(cgImage: CGImage) {
        textRecognitionWorkQueue.async {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try requestHandler.perform([self.textRecognitionRequest])
            } catch {
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
                self.textView.text += "======= SCANNED INVOICE =======\n"
                self.textView.text += detectedText
                self.textView.text += "\n\n\n"
                self.recognizeFirstImage()
            }
        }
        textRecognitionRequest.minimumTextHeight = 0.013
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = false
        textRecognitionRequest.recognitionLanguages = ["ru", "en", "de"]
    }
    
    func setupImages() {
        for iView in stackOfImages.arrangedSubviews {
            if let imageView = iView as? UIImageView, let image = imageView.image {
                imagesToScan.append(image)
            }
        }
    }
    
    func setRandomImage() {
        let iView = UIImageView(frame: UIScreen.main.bounds)
        iView.image = imagesToScan.randomElement()
        self.view.addSubview(iView)
    }
}
