import Vision

class VisionTrackingManager: ObservableObject {
    
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        // TODO: Scaffold VNDetectHumanBodyPose3DRequest or 2D fallback
        // let request = VNDetectHumanBodyPoseRequest(completionHandler: handlePoseDetection)
        // do {
        //     let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        //     try handler.perform([request])
        // } catch {
        //     print(error)
        // }
    }
    
    // private func handlePoseDetection(request: VNRequest, error: Error?) { ... }
}
