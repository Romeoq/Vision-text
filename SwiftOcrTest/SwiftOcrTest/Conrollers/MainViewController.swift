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
    
    //Call text recognition request handler
    func recognizeImage(cgImage: CGImage) {
        textRecognitionWorkQueue.async {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try requestHandler.perform([self.textRecognitionRequest!])
            } catch {
                DispatchQueue.main.async {
                    self.removeLoader()
                    print(error)
                }
            }
        }
    }
    
    //Set textRecognitionRequest from ViewDidLoad
    func setTextRequest() {
        textRecognitionRequest = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }
            var detectedText = ""
            self.textBlocks.removeAll()
            
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                detectedText += "\(topCandidate.string)\n"
                
                //Text block specific for this project
                if let recognizedBlock = self.getRecognizedDoubleBlock(topCandidate: topCandidate.string, observationBox: observation.boundingBox) {
                    self.textBlocks.append(recognizedBlock)
                }
            }
            
            DispatchQueue.main.async {
                self.textView.text = detectedText
                self.removeLoader()
                self.drawRecognizedBlocks()
            }
        }
        
        //Individual recognition request settings
        textRecognitionRequest!.minimumTextHeight = 0.011 // Lower = better quality
        textRecognitionRequest!.recognitionLevel = .accurate
    }
    
    func drawRecognizedBlocks() {
        guard let image = invoiceImage?.image else  { return }
        
        //transform from documentation
        let imageTransform = CGAffineTransform.identity.scaledBy(x: 1, y: -1).translatedBy(x: 0, y: -image.size.height).scaledBy(x: image.size.width, y: image.size.height)
        
        //drawing rects on cgimage
        UIGraphicsBeginImageContextWithOptions(image.size, false, 1.0)
        let context = UIGraphicsGetCurrentContext()!
        image.draw(in: CGRect(origin: .zero, size: image.size))
        context.setStrokeColor(CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1))
        context.setLineWidth(4)
        
        for index in 0 ..< textBlocks.count {
            let optimizedRect = textBlocks[index].cgRect.applying(imageTransform)
            context.addRect(optimizedRect)
            textBlocks[index].imageRect = optimizedRect
        }
        context.strokePath()
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        invoiceImage?.image = result
    }
    
    //UIImageView tap listener
    @objc func onImageViewTap(sender: UITapGestureRecognizer) {
        guard let invoiceImage = invoiceImage, let image = invoiceImage.image else {
            return
        }
        
        //get tap coordinates on image
        let tapX = sender.location(in: invoiceImage).x
        let tapY = sender.location(in: invoiceImage).y
        let xRatio = image.size.width / invoiceImage.bounds.width
        let yRatio = image.size.height / invoiceImage.bounds.height
        let imageXPoint = tapX * xRatio
        let imageYPoint = tapY * yRatio

        //detecting if one of text blocks tapped
        for block in textBlocks {
            if block.imageRect.contains(CGPoint(x: imageXPoint, y: imageYPoint)) {
                showTapAlert(doubleValue: block.doubleValue)
                break
            }
        }
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
    
    func showTapAlert(doubleValue: Double) {
        let alert = UIAlertController(title: "Double tapped!", message: "\(doubleValue)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
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
    
    func getRecognizedDoubleBlock(topCandidate: String, observationBox: CGRect) -> RecognizedTextBlock? {
        //Text blocks settings for this project
        var finalString = topCandidate.replacingOccurrences(of: ",", with: ".")
        let restrictedSymbols: Set<Character> = ["=", "-", "_", "+", " "]
        finalString.removeAll(where: { restrictedSymbols.contains($0) })
        for _ in 0 ..< 3 {
            if let lastCharacter = finalString.last, !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: String(lastCharacter))) {
                finalString.removeLast()
            }
        }
        
        //Only Doubles for this project
        if let double = Double(finalString) {
            return RecognizedTextBlock(doubleValue: double, cgRect: observationBox)
        }
        return nil
    }
}
