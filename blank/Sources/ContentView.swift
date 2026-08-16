import SwiftUI

struct TouchCaptureView: View {
    // Change this to your PC's local IP address (e.g. from ipconfig on Windows)
    private let pcIP = "192.168.0.188"
    private let pcPort: UInt16 = 5005

    @StateObject private var sender = UDPDeltaSender()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Text(sender.connected ? "connected" : "connecting...")
                    .foregroundColor(sender.connected ? .green : .red)
                Spacer()
            }
            .font(.system(size: 16, design: .monospaced))
            .padding(.top, 60)

            PencilCaptureRepresentable { dx, dy in
                sender.sendDelta(dx: dx, dy: dy)
            }
        }
        .onAppear {
            sender.connect(host: pcIP, port: pcPort)
        }
    }
}
