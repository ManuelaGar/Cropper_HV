//
//  CropViewController.swift
//  Cropper
//
//  Created by Manuela Garcia on 6/08/18.
//  Copyright © 2018 Manuela Garcia. All rights reserved.
//

import IGRPhotoTweaks
import UIKit
import HorizontalDial

extension IGRPhotoTweakViewController {
    // MARK: - Funciones para calcular los mm por pixel y mm totales
    public func pixels(marker: Float) -> (mmxPixelX: Float, mmxPixelY: Float, pX: Float, pY: Float) {
        var transform = CGAffineTransform.identity
        // translate
        let translation: CGPoint = self.photoView.photoTranslation
        transform = transform.translatedBy(x: translation.x, y: translation.y)
        // scale
        
        let t: CGAffineTransform = self.photoView.photoContentView.transform
        let xScale: CGFloat = sqrt(t.a * t.a + t.c * t.c)
        let yScale: CGFloat = sqrt(t.b * t.b + t.d * t.d)
        transform = transform.scaledBy(x: xScale, y: yScale)
        
        print(xScale)
        print(yScale)
        
        let pixelsXInCroppedImage = Float(image.size.width/xScale)
        let pixelsYInCroppedImage = Float(image.size.height/yScale)
        
        let mmPorPixelX = Float(marker/pixelsXInCroppedImage)
        let mmPorPixelY = Float(marker/pixelsYInCroppedImage)
        
        print("Pixels x: \(pixelsXInCroppedImage), mm por pixel: \(mmPorPixelX)")
        print("Pixels y: \(pixelsYInCroppedImage), mm por pixel: \(mmPorPixelY)")
        
        return (mmPorPixelX, mmPorPixelY, pixelsXInCroppedImage, pixelsYInCroppedImage)
    }
    
    public func mmEnImagenCortada(mmxPixelX: Float, mmxPixelY: Float) -> (mmTotalesX: Float, mmTotalesX: Float, PX: Float, PY: Float) {
        var transform = CGAffineTransform.identity
        // translate
        let translation: CGPoint = self.photoView.photoTranslation
        transform = transform.translatedBy(x: translation.x, y: translation.y)
        let t: CGAffineTransform = self.photoView.photoContentView.transform
        let xScale: CGFloat = sqrt(t.a * t.a + t.c * t.c)
        let yScale: CGFloat = sqrt(t.b * t.b + t.d * t.d)
        
        let pixelsInCroppedImageX = Float(image.size.width/xScale)
        let pixelsInCroppedImageY = Float(image.size.height/yScale)
        
        var mmTotalesX: Float = 0
        var mmTotalesY: Float = 0
        
        let aspect = UserDefaults.standard.float(forKey: "aspect")
        
        if aspect < 1 {
            mmTotalesX = pixelsInCroppedImageX * mmxPixelX
            mmTotalesY = mmTotalesX*aspect
        } else if aspect == 1 {
            mmTotalesX = pixelsInCroppedImageX * mmxPixelX
            mmTotalesY = mmTotalesX
            //pixelsInCroppedImageY * mmxPixelX
        } else {
            mmTotalesY = pixelsInCroppedImageY * mmxPixelX
            mmTotalesX = mmTotalesY/aspect
        }
        
        UserDefaults.standard.set(mmTotalesX, forKey:"mmEnX")
        print(mmTotalesX)
        UserDefaults.standard.set(mmTotalesY, forKey:"mmEnY")
        print(mmTotalesY)
        
        print("xScale \(xScale)")
        print("yScale \(yScale)")
        print("height \(image.size.height)")
        print("width \(image.size.width)")
        print(pixelsInCroppedImageX)
        print(pixelsInCroppedImageY)
        
        return (mmTotalesX, mmTotalesY, pixelsInCroppedImageX, pixelsInCroppedImageY)
    }
    
    public func Calibracion(mmDiametro: Float, pixelesDiametro: Float) -> (Float) {
        let h: Float = 255
        let distanciaFocal = (pixelesDiametro * h)/mmDiametro
        print("pixeles DF \(pixelesDiametro) y mm DF \(mmDiametro)")
        return (distanciaFocal)
    }
    
}

class CropViewController: IGRPhotoTweakViewController {

    @IBOutlet weak var angleSlider: UISlider!
    @IBOutlet weak var angleLabel: UILabel!
    
    @IBOutlet weak fileprivate var horizontalDial: HorizontalDial? {
        didSet {
            self.horizontalDial?.migneticOption = .none
        }
    }

    var tap1 = 0
    var medidaText = ""
    var mmPorPixelX: Float = 0
    var mmPorPixelY: Float = 0
    var mmX: Float = 0
    var mmY: Float = 0
    
    let marcador: Float = 24.5
    let marcador2: Float = 23.5
    var h1: Float = 0
    var h2: Float = 0
    
    // MARK: - Life Cicle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setCropAspectRect(aspect: "1:1")
        self.setupSlider()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //FIXME: Themes Preview
    override open func setupThemes() {
                IGRCropLine.appearance().backgroundColor = UIColor.white
                IGRPhotoContentView.appearance().backgroundColor = UIColor.white
    }
    
    fileprivate func setupSlider() {
        self.angleSlider?.minimumValue = -Float(IGRRadianAngle.toRadians(90))
        self.angleSlider?.maximumValue = Float(IGRRadianAngle.toRadians(90))
        self.angleSlider?.value = 0.0

        setupAngleLabelValue(radians: CGFloat((self.angleSlider?.value)!))
    }
    
    fileprivate func setupAngleLabelValue(radians: CGFloat) {
        let intDegrees: Int = Int(IGRRadianAngle.toDegrees(radians))
        self.angleLabel?.text = "\(intDegrees)°"
    }
    
    // MARK: - Rotation
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            self.view.layoutIfNeeded()
        }) { (context) in
            //
        }
    }
    
    // MARK: - Actions
    
    @IBAction func onChandeAngleSliderValue(_ sender: UISlider) {
        let radians: CGFloat = CGFloat(sender.value)
        setupAngleLabelValue(radians: radians)
        self.changedAngle(value: radians)
    }
    
    @IBAction func onEndTouchAngleControl(_ sender: UISlider) {
        self.stopChangeAngle()
    }
    
    @IBAction func cancelBtn(_ sender: UIBarButtonItem) {
        self.dismissAction()
    }
    
    @IBAction func resetBtn(_ sender: UIBarButtonItem) {
        self.angleSlider?.value = 0.0
        self.horizontalDial?.value = 0.0
        setupAngleLabelValue(radians: 0.0)
        self.resetView()
    }
    
    @IBAction func cropBtn(_ sender: UIBarButtonItem) {
        cropAction()
        print("\(self.tap1)")
        if self.tap1 == 0 {
            let pixelsEnImagenCortada = pixels(marker: marcador)
            self.mmPorPixelX = pixelsEnImagenCortada.0
            self.mmPorPixelY = pixelsEnImagenCortada.1
            let pX = pixelsEnImagenCortada.2
            //let pY = pixelsEnImagenCortada.3
            let distanciaFocal = Calibracion(mmDiametro: marcador, pixelesDiametro: pX)
            self.h1 = (marcador * distanciaFocal)/pX
            
            UserDefaults.standard.set(self.mmPorPixelX, forKey: "mmPPX")
            UserDefaults.standard.set(self.mmPorPixelY, forKey: "mmPPY")
            UserDefaults.standard.set(distanciaFocal, forKey: "DF")
            UserDefaults.standard.set(self.h1, forKey:"h1")
            
            print("La distancia focal es \(distanciaFocal)")
            print("h1 es \(h1)")
        } else {
            let mmPPX = UserDefaults.standard.float(forKey: "mmPPX")
            let mmPPY = UserDefaults.standard.float(forKey: "mmPPY")
            
            let mmEnImagen = mmEnImagenCortada(mmxPixelX: mmPPX, mmxPixelY: mmPPY)
            self.mmX = mmEnImagen.0
            self.mmY = mmEnImagen.1
            let PX = mmEnImagen.2
            
            let distanciaFocal = UserDefaults.standard.float(forKey: "DF")
            let h1 = UserDefaults.standard.float(forKey: "h1")
            
            self.h2 = (marcador2 * distanciaFocal)/PX
            let altura = h1 - self.h2
            
            UserDefaults.standard.set(altura, forKey: "altura")
            print("h2 es \(h2) y la h1-h2 es \(altura)")
            print("Los mm x: \(mmX), y son: \(mmY)")
        
            UserDefaults.standard.set(mmX, forKey:"mmEnX")
            UserDefaults.standard.set(mmY, forKey:"mmEnY")
        }
    }
    
    @IBAction func aspectBtn(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil,
                                            message: nil,
                                            preferredStyle: .actionSheet)
        
        
        actionSheet.addAction(UIAlertAction(title: "Original", style: .default) { (action) in
            self.resetAspectRect()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cuadrado", style: .default) { (action) in
            self.setCropAspectRect(aspect: "1:1")
        })
        
        actionSheet.addAction(UIAlertAction(title: "2:3", style: .default) { (action) in
            self.setCropAspectRect(aspect: "2:3")
        })

        actionSheet.addAction(UIAlertAction(title: "3:5", style: .default) { (action) in
            self.setCropAspectRect(aspect: "3:5")
        })

        actionSheet.addAction(UIAlertAction(title: "3:4", style: .default) { (action) in
            self.setCropAspectRect(aspect: "3:4")
        })

        actionSheet.addAction(UIAlertAction(title: "5:7", style: .default) { (action) in
            self.setCropAspectRect(aspect: "5:7")
        })

        actionSheet.addAction(UIAlertAction(title: "9:16", style: .default) { (action) in
            self.setCropAspectRect(aspect: "9:16")
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        
        present(actionSheet, animated: true, completion: nil)
    }

    override open func customCanvasHeaderHeigth() -> CGFloat {
        var heigth: CGFloat = 0.0
        
        if UIDevice.current.orientation.isLandscape {
            heigth = 40.0
        } else {
            heigth = 100.0
        }
        
        return heigth
    }
}

extension CropViewController: HorizontalDialDelegate {
    func horizontalDialDidValueChanged(_ horizontalDial: HorizontalDial) {
        let degrees = horizontalDial.value
        let radians = IGRRadianAngle.toRadians(CGFloat(degrees))
        
        self.setupAngleLabelValue(radians: radians)
        self.changedAngle(value: radians)
    }
    
    func horizontalDialDidEndScroll(_ horizontalDial: HorizontalDial) {
        self.stopChangeAngle()
    }
}
