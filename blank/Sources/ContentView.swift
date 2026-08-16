import SwiftUI

struct TouchCaptureView: View {
    @StateObject private var sender = UDPDeltaSender()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Circle()
                        .fill(sender.connected ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                        .padding()
                }
                Spacer()
            }

            PencilCaptureRepresentable(
                onDelta: { dx, dy in
                    sender.sendDelta(dx: dx, dy: dy)
                }
            )
        }
        .onAppear {
            sender.startDiscovery()
        }
    }
}