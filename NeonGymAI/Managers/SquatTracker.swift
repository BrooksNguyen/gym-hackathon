import Foundation
import CoreGraphics

enum SquatState {
    case idle
    case eccentric // Going down
    case bottom    // Max depth
    case concentric // Going up
}

class SquatTracker {
    var state: SquatState = .idle
    var repCount: Int = 0
    
    // Thresholds (degrees)
    let idleThreshold: CGFloat = 160.0    // Knees mostly straight
    let bottomThreshold: CGFloat = 90.0   // Squat depth
    let backLeanThreshold: CGFloat = 35.0 // Max degrees back can lean relative to vertical
    
    // Debounce to prevent double counting
    private var lastRepTime: Date = Date.distantPast
    private let debounceInterval: TimeInterval = 1.0
    
    func processFrame(hip: CGPoint, knee: CGPoint, ankle: CGPoint, shoulder: CGPoint) -> (SquatState, Int, String?) {
        // 1. Calculate joint vectors
        let hipToKnee = MathUtils.createVector(from: hip, to: knee)
        let kneeToAnkle = MathUtils.createVector(from: knee, to: ankle)
        
        // 2. Calculate knee angle
        let kneeAngle = MathUtils.angleBetween(vector1: hipToKnee, vector2: kneeToAnkle)
        
        // 3. FSM Logic for Rep Counting
        switch state {
        case .idle:
            if kneeAngle < idleThreshold {
                state = .eccentric
            }
        case .eccentric:
            if kneeAngle <= bottomThreshold {
                state = .bottom
            } else if kneeAngle >= idleThreshold {
                state = .idle // Aborted rep
            }
        case .bottom:
            if kneeAngle > bottomThreshold {
                state = .concentric
            }
        case .concentric:
            if kneeAngle >= idleThreshold {
                // Completed a rep! Check debounce
                let now = Date()
                if now.timeIntervalSince(lastRepTime) > debounceInterval {
                    repCount += 1
                    lastRepTime = now
                }
                state = .idle
            }
        }
        
        // 4. Form Checking (Task 4)
        var formFeedback: String? = nil
        let shoulderToHip = MathUtils.createVector(from: shoulder, to: hip)
        let torsoAngle = MathUtils.angleWithVertical(vector: shoulderToHip)
        
        if torsoAngle > backLeanThreshold {
            formFeedback = "Lưng chưa thẳng" // Back not straight
        }
        
        return (state, repCount, formFeedback)
    }
}
