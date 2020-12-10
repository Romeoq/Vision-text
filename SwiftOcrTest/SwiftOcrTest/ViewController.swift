// Created by Roman Voinitchi on 12/10/20
// 


import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var stackOfImages: UIStackView!
    
    private var imagesToScan = [UIImage]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupImages()
//        setRandomImage()
        
    }
    
}

private extension ViewController {
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
