import AVFoundation
import SwiftUI

struct SkeletonOverlay: View {
    let points: [PosePoint]
    let mirrored: Bool
    var videoGravity: AVLayerVideoGravity = .resizeAspect

    var body: some View {
        Canvas { context, size in
            let pointMap = Dictionary(uniqueKeysWithValues: points.map { ($0.id, $0) })

            for (fromID, toID) in VisionTrackingManager.skeletalConnections {
                guard let from = pointMap[fromID], let to = pointMap[toID] else { continue }
                var path = Path()
                path.move(to: screenPoint(from.location, in: size))
                path.addLine(to: screenPoint(to.location, in: size))
                context.stroke(path,
                               with: .color(Theme.neonCyan.opacity(0.9)),
                               style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }

            for point in points {
                let position = screenPoint(point.location, in: size)
                let radius: CGFloat = point.confidence > 0.65 ? 5 : 3
                let dot = Path(ellipseIn: CGRect(x: position.x - radius,
                                                 y: position.y - radius,
                                                 width: radius * 2,
                                                 height: radius * 2))
                context.fill(dot, with: .color(Theme.neonGreen))
            }
        }
        .allowsHitTesting(false)
    }

    private func screenPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        // The camera preview uses the same aspect mode as this overlay. A
        // plain normalized-to-screen conversion is incorrect when the source
        // frame is letterboxed or cropped, which is most visible for a
        // horizontal push-up. iPhone camera output is displayed portrait here
        // at approximately 9:16.
        let sourceAspectRatio: CGFloat = 9.0 / 16.0
        let viewRect = CGRect(origin: .zero, size: size)
        let sourceSize = CGSize(width: sourceAspectRatio, height: 1)
        let contentRect: CGRect

        if videoGravity == .resizeAspectFill {
            let scale = max(size.width / sourceSize.width,
                            size.height / sourceSize.height)
            let contentSize = CGSize(width: sourceSize.width * scale,
                                     height: sourceSize.height * scale)
            contentRect = CGRect(x: (size.width - contentSize.width) / 2,
                                 y: (size.height - contentSize.height) / 2,
                                 width: contentSize.width,
                                 height: contentSize.height)
        } else {
            contentRect = AVMakeRect(aspectRatio: sourceSize, insideRect: viewRect)
        }

        return CGPoint(x: contentRect.minX + (mirrored ? 1 - point.x : point.x) * contentRect.width,
                       y: contentRect.minY + (1 - point.y) * contentRect.height)
    }
}
