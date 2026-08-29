import SwiftUI

struct SkeletonOverlay: View {
    let points: [PosePoint]
    let mirrored: Bool

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
        CGPoint(x: (mirrored ? 1 - point.x : point.x) * size.width,
                y: (1 - point.y) * size.height)
    }
}
