// Created by Roman Voinitchi on 12/10/20
// 


import UIKit
import Vision

class MainViewController: UIViewController {
    
    private let MinimumTextHeight: Float = 0.007 //Lower = better recognition
    
    @IBOutlet weak var viewForImage: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var stackOfImages: UIStackView!
    @IBOutlet weak var checkImageView: UIImageView!
    
    var textRecognitionRequest: VNRecognizeTextRequest?
    let textRecognitionWorkQueue = DispatchQueue(label: "TextRecognitionQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    private var loaderView: UIView?
    private var boxes = [CheckSelectionBox]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTextRequest()
//        checkImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onImageViewTap(sender:))))
        
    }
    
    @IBAction func onCheckTap(_ sender: UIButton) {
        if let image = sender.image(for: .normal), let cgImage = image.cgImage {
            setLoader()
//            for subView in viewForImage.subviews {
//                if subView is UIButton {
//                    subView.removeFromSuperview()
//                }
//            }
//            tempView?.removeFromSuperview()
//            tempView = nil
            self.textView.text = ""
            checkImageView.image = image
            recognizeImage(cgImage: cgImage)
        }
    }
    
}

private extension MainViewController {
    
    func recognizeImage(cgImage: CGImage) {
        textRecognitionWorkQueue.async {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try requestHandler.perform([self.textRecognitionRequest!])
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
        textRecognitionRequest!.minimumTextHeight = MinimumTextHeight
        textRecognitionRequest!.recognitionLevel = .accurate
        textRecognitionRequest!.usesLanguageCorrection = false
        textRecognitionRequest!.recognitionLanguages = ["ru", "ro", "en"]
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
//        let viewTransform = getViewTransform(image: image)
        
//        tempView = UIView()
//        viewForImage.addSubview(tempView!)
        UIGraphicsBeginImageContextWithOptions(image.size, false, 1.0)
        let context = UIGraphicsGetCurrentContext()!
        image.draw(in: CGRect(origin: .zero, size: image.size))
        context.setStrokeColor(CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1))
        context.setLineWidth(2)
        
        for index in 0 ..< boxes.count {
            let optimizedRect = boxes[index].boundingBox.applying(imageTransform)
            context.addRect(optimizedRect)
            boxes[index].imageBox = optimizedRect
//            drawButton(optimizedRect: boxes[index].boundingBox.applying(viewTransform), index: index, sourceImage: image)
        }
//        moveTempView()
        context.strokePath()
        let result=UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        checkImageView.image = result
    }
    
    func getViewTransform(image: UIImage) -> CGAffineTransform {
        let ratio = image.size.width / image.size.height
        let yBoundsScale = image.size.height < image.size.width ? viewForImage.bounds.height / ratio : viewForImage.bounds.height
        
        let baseTransform =  CGAffineTransform.identity.scaledBy(x: viewForImage.bounds.width, y: -yBoundsScale)
        return baseTransform
    }
    
//    func drawButton(optimizedRect: CGRect, index: Int, sourceImage: UIImage) {
//        let btn = UIButton(frame: optimizedRect)
//        btn.tag = index
//        btn.backgroundColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.5)
//        btn.addTarget(self, action: #selector(onNumberTap), for: .touchUpInside)
//        tempView!.addSubview(btn)
////        btn.transform = CGAffineTransform(scaleX: viewForImage.bounds.width / sourceImage.size.width, y: 1)
//    }
    
//    func moveTempView() {
//        tempView!.frame.origin.y += viewForImage.frame.height - 100
//    }
    
    @objc
    func onNumberTap(sender: UIButton) {
        print("Index = \(sender.tag)", "Price = \(boxes[sender.tag].double)")
    }
    
    @objc
    func onImageViewTap(sender: UITapGestureRecognizer) {
        guard let image = checkImageView.image, let cgImage = image.cgImage else { return }
        
        let tapX = sender.location(in: checkImageView).x
        let tapY = sender.location(in: checkImageView).y
        
        let xRatio = image.size.width / checkImageView.bounds.width
        let yRatio = image.size.height / checkImageView.bounds.height
        
        let imageXPoint = tapX * xRatio
        let imageYPoint = tapY * yRatio
        
        for box in boxes {
            if box.imageBox.contains(CGPoint(x: imageXPoint, y: imageYPoint)) {
                print(box.double)
                break
            }
        }
//        print(imageXPoint, imageYPoint, image.size, cgImage.width, cgImage.height, checkImageView.bounds.size)
        
    }
}
