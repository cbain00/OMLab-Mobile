/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience extensions for system types.
*/

import ARKit
import SceneKit

extension SCNMatrix4 {
    /**
     Create a 4x4 matrix from CGAffineTransform, which represents a 3x3 matrix
     but stores only the 6 elements needed for 2D affine transformations.
     
     [ a  b  0 ]     [ a  b  0  0 ]
     [ c  d  0 ]  -> [ c  d  0  0 ]
     [ tx ty 1 ]     [ 0  0  1  0 ]
     .               [ tx ty 0  1 ]
     
     Used for transforming texture coordinates in the shader modifier.
     (Needs to be SCNMatrix4, not SIMD float4x4, for passing to shader modifier via KVC.)
     */
    init(_ affineTransform: CGAffineTransform) {
        self.init()
        m11 = Float(affineTransform.a)
        m12 = Float(affineTransform.b)
        m21 = Float(affineTransform.c)
        m22 = Float(affineTransform.d)
        m41 = Float(affineTransform.tx)
        m42 = Float(affineTransform.ty)
        m33 = 1
        m44 = 1
    }
}

extension SCNReferenceNode {
    convenience init(named resourceName: String, loadImmediately: Bool = true) {
        let url = Bundle.main.url(forResource: resourceName, withExtension: "scn", subdirectory: "Models.scnassets")!
        self.init(url: url)!
        if loadImmediately {
            self.load()
        }
    }
}

extension SCNMaterial {
    static func materialWithColor(_ color: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = color
        return material
    }
}

extension UUID {
    /**
    Pseudo-randomly return one of the 14 fixed standard colors, based on this UUID.
    */
    func toRandomColor() -> UIColor {
        let colors: [UIColor] = [.red, .green, .blue, .yellow, .magenta, .cyan, .purple,
                                 .orange, .brown, .lightGray, .gray, .darkGray, .black, .white]
        let randomNumber = abs(self.hashValue % colors.count)
        return colors[randomNumber]
    }
}



// Jorge below

extension simd_float4x4 {
    var eulerAngles: simd_float3 {
        simd_float3(
            x: rad2deg( atan2(self[2][0], self[2][2] )),
            y: rad2deg( -asin(-self[2][1] )),
            z: rad2deg( -atan2(self[0][1], self[1][1] ))
        )
    }
}

func rad2deg(_ number: Float) -> Float {
    return number * 180 / .pi
}

