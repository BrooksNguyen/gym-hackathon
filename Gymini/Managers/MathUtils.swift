import Foundation
import CoreGraphics

struct MathUtils {
    
    /// Creates a 2D vector from two CGPoints
    static func createVector(from point1: CGPoint, to point2: CGPoint) -> CGPoint {
        return CGPoint(x: point2.x - point1.x, y: point2.y - point1.y)
    }
    
    /// Calculates the angle (in degrees) between two vectors using the dot product formula
    static func angleBetween(vector1: CGPoint, vector2: CGPoint) -> CGFloat {
        let dotProduct = (vector1.x * vector2.x) + (vector1.y * vector2.y)
        
        let magnitude1 = sqrt((vector1.x * vector1.x) + (vector1.y * vector1.y))
        let magnitude2 = sqrt((vector2.x * vector2.x) + (vector2.y * vector2.y))
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0 }
        
        let cosTheta = dotProduct / (magnitude1 * magnitude2)
        // Clamp to avoid NaN due to floating point inaccuracies
        let clampedCosTheta = max(-1.0, min(1.0, cosTheta))
        
        let angleInRadians = acos(clampedCosTheta)
        return angleInRadians * (180.0 / .pi)
    }
    
    /// Calculates the angle of a vector relative to the vertical Y-axis (for form checking)
    static func angleWithVertical(vector: CGPoint) -> CGFloat {
        let verticalVector = CGPoint(x: 0, y: 1) // Pointing downwards (iOS coordinate system)
        return angleBetween(vector1: vector, vector2: verticalVector)
    }
}
