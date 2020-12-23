// Created by Roman Voinitchi on 12/10/20
// 


import UIKit
import Vision

class ViewController: UIViewController {
    
    private let MinimumTextHeight: Float = 0.007 //Lower -> better recognition
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var stackOfImages: UIStackView!
    @IBOutlet weak var checkImageView: UIImageView!
    
    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    let textRecognitionWorkQueue = DispatchQueue(label: "TextRecognitionQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    private var loaderView: UIView?
    private var boxes = [CheckSelectionBox]()

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
            self.boxes.removeAll()
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                var finalString = topCandidate.string.replacingOccurrences(of: ",", with: ".")
                finalString = finalString.replacingOccurrences(of: "=", with: "")
                finalString = finalString.replacingOccurrences(of: "-", with: "")
                detectedText += finalString
                detectedText += "\n"
                
                if let double = Double(finalString) {
                    self.boxes.append(CheckSelectionBox(double: double, boundingBox: observation.boundingBox))
                }
            }
            
            DispatchQueue.main.async {
                self.removeLoader()
                self.drawBoxes()
                self.textView.text += detectedText
            }
        }
        textRecognitionRequest.minimumTextHeight = MinimumTextHeight
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
    
    func drawBoxes() {
        guard let image = checkImageView.image else  { return }
        
        let imageTransform = CGAffineTransform.identity.scaledBy(x: 1, y: -1).translatedBy(x: 0, y: -image.size.height).scaledBy(x: image.size.width, y: image.size.height)
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, 1.0)
        let context = UIGraphicsGetCurrentContext()!
        image.draw(in: CGRect(origin: .zero, size: image.size))
        context.setStrokeColor(CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1))
        context.setLineWidth(2)
        for box in boxes {
            context.addRect(box.boundingBox.applying(imageTransform))
        }
        context.strokePath()
        let result=UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        checkImageView.image = result
    }
}
