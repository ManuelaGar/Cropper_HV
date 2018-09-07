//
//  Modelo.swift
//  Cropper
//
//  Created by Manuela Garcia on 17/08/18.
//  Copyright © 2018 Manuela Garcia. All rights reserved.
//

import Foundation
import UIKit
import IGRPhotoTweaks

class Modelo {
    var tap = 0
    var medida: Float = 0.0
    var xScale: Float = 0.0
    var yScale: Float = 0.0
    var tamañoMarcador : Float = 30.0
    public var image: UIImage!
    
    init (TamañoMar: Float) {
        tamañoMarcador = TamañoMar
    }
}
