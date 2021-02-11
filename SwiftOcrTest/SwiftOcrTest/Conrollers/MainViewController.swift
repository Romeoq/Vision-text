// Created by Roman Voinitchi on 12/10/20
// 


import UIKit
import Vision

//MARK: Vars + Lifecycle
class MainViewController: UIViewController {
    
    @IBOutlet weak var viewForInvoice: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var stackOfInvoices: UIStackView!
    
    //Request for text recognition
    var textRecognitionRequest: VNRecognizeTextRequest?
    //Recognition queue
    let textRecognitionWorkQueue = DispatchQueue(label: "TextRecognitionQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    private var loader: UIView?
    private var textBlocks = [RecognizedTextBlock]()
    private var invoiceImage: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTextRequest()
        setInvoicesTapRecognizer()
    }
}

//MARK: Recognition block
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
            self.textBlocks.removeAll()
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                var finalString = topCandidate.string.replacingOccurrences(of: ",", with: ".")
                finalString = finalString.replacingOccurrences(of: "=", with: "")
                finalString = finalString.replacingOccurrences(of: "-", with: "")
                detectedText += finalString
                detectedText += "\n"
                
                if let double = Double(finalString) {
                    self.textBlocks.append(RecognizedTextBlock(doubleValue: double, cgRect: observation.boundingBox))
                }
            }
            
            DispatchQueue.main.async {
                self.removeLoader()
                self.drawRecognizedBlocks()
                self.textView.text += detectedText
            }
        }
        textRecognitionRequest!.minimumTextHeight = 0.007 // Lower = better quality
        textRecognitionRequest!.recognitionLevel = .accurate
        textRecognitionRequest!.usesLanguageCorrection = false
        textRecognitionRequest!.recognitionLanguages = ["ru", "ro", "en"]
    }
    
    func drawRecognizedBlocks() {
        guard let image = invoiceImage?.image else  { return }
        
        let imageTransform = CGAffineTransform.identity.scaledBy(x: 1, y: -1).translatedBy(x: 0, y: -image.size.height).scaledBy(x: image.size.width, y: image.size.height)
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, 1.0)
        let context = UIGraphicsGetCurrentContext()!
        image.draw(in: CGRect(origin: .zero, size: image.size))
        context.setStrokeColor(CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1))
        context.setLineWidth(2)
        for index in 0 ..< textBlocks.count {
            let optimizedRect = textBlocks[index].cgRect.applying(imageTransform)
            context.addRect(optimizedRect)
            textBlocks[index].imageRect = optimizedRect
        }
        context.strokePath()
        let result=UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        invoiceImage?.image = result
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
    
//    @objc
//    func onNumberTap(sender: UIButton) {
//        print("Index = \(sender.tag)", "Price = \(boxes[sender.tag].double)")
//    }
    
    @objc func onImageViewTap(sender: UITapGestureRecognizer) {
        print("Taped")
//        guard let image = checkImageView.image, let cgImage = image.cgImage else { return }

//        let tapX = sender.location(in: checkImageView).x
//        let tapY = sender.location(in: checkImageView).y
//
//        let xRatio = image.size.width / checkImageView.bounds.width
//        let yRatio = image.size.height / checkImageView.bounds.height
//
//        let imageXPoint = tapX * xRatio
//        let imageYPoint = tapY * yRatio
//
//        for box in boxes {
//            if box.imageBox.contains(CGPoint(x: imageXPoint, y: imageYPoint)) {
//                print(box.double)
//                break
//            }
//        }
//        print(imageXPoint, imageYPoint, image.size, cgImage.width, cgImage.height, checkImageView.bounds.size)
        
    }
}

//MARK: UIKit block
private extension MainViewController {
    func setInvoicesTapRecognizer() {
        for imageView in stackOfInvoices.arrangedSubviews {
            imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onStackInvoiceTap(sender:))))
        }
    }
    
    @objc func onStackInvoiceTap(sender: UITapGestureRecognizer) {
        guard let imageView = sender.view as? UIImageView, let newImage = imageView.image, let cgImage = newImage.cgImage else {
            return
        }
        setLoader()
        self.textView.text = ""
        addNewInvoiceImageView(with: newImage)
        recognizeImage(cgImage: cgImage)
    }
    
    func addNewInvoiceImageView(with image: UIImage) {
        invoiceImage?.removeFromSuperview()
        let xRatio = image.size.width >= image.size.height ? 1 :image.size.width / image.size.height
        let yRatio = image.size.height >= image.size.width ? 1 : image.size.height / image.size.width
        
        let ivWidth = viewForInvoice.bounds.width * xRatio
        let ivHeight = viewForInvoice.bounds.height * yRatio
        let ivXPos = (viewForInvoice.bounds.width - ivWidth) / 2
        let ivYPos = (viewForInvoice.bounds.height - ivHeight) / 2
        invoiceImage = UIImageView(frame: CGRect(
                                    x: ivXPos,
                                    y: ivYPos,
                                    width: ivWidth,
                                    height: ivHeight))
        invoiceImage?.image = image
        invoiceImage?.isUserInteractionEnabled = true
        viewForInvoice.addSubview(invoiceImage!)
        
        invoiceImage?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onImageViewTap(sender:))))
    }
    
    func setLoader() {
        loader = UIView(frame: view.bounds)
        loader?.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        
        let activity = UIActivityIndicatorView(style: .large)
        activity.startAnimating()
        loader?.addSubview(activity)
        
        activity.translatesAutoresizingMaskIntoConstraints = false
        activity.centerXAnchor.constraint(equalTo: loader!.centerXAnchor).isActive = true
        activity.centerYAnchor.constraint(equalTo: loader!.centerYAnchor).isActive = true
        
        view.addSubview(loader!)
    }
    
    func removeLoader() {
        loader?.removeFromSuperview()
        loader = nil
    }
}
