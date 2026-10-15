import SwiftUI

struct PencilCaptureRepresentable: UIViewRepresentable {
    var onDelta: (CGFloat, CGFloat) -> Void

    func makeUIView(context: Context) -> PencilCaptureUIView {
        let view = PencilCaptureUIView()
        view.onDelta = onDelta
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: PencilCaptureUIView, context: Context) {}
}

class PencilCaptureUIView: UIView {
    var onDelta: ((CGFloat, CGFloat) -> Void)?
    private var lastPoint: CGPoint?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = pencilTouch(in: touches) else { return }
        lastPoint = touch.location(in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = pencilTouch(in: touches) else { return }

        if let coalesced = event?.coalescedTouches(for: touch) {
            for t in coalesced {
                processTouch(t)
            }
        } else {
            processTouch(touch)
        }

        if let predicted = event?.predictedTouches(for: touch)?.last {
            processTouch(predicted, isPrediction: true)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastPoint = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastPoint = nil
    }

    private func processTouch(_ touch: UITouch, isPrediction: Bool = false) {
        let point = touch.location(in: self)
        guard let last = lastPoint else {
            lastPoint = point
            return
        }
        let dx = point.x - last.x
        let dy = point.y - last.y
        onDelta?(dx, dy)
        if !isPrediction {
            lastPoint = point
        }
    }

    private func pencilTouch(in touches: Set<UITouch>) -> UITouch? {
        touches.first { $0.type == .pencil }
    }
}
