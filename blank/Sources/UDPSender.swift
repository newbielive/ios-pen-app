import Foundation
import Network

class UDPDeltaSender: ObservableObject {
    @Published var connected = false
    private var connection: NWConnection?

    func connect(host: String, port: UInt16) {
        let conn = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!,
            using: .udp
        )
        conn.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.connected = true
                case .failed, .cancelled:
                    self?.connected = false
                default:
                    break
                }
            }
        }
        conn.start(queue: .main)
        self.connection = conn
    }

    func sendDelta(dx: CGFloat, dy: CGFloat) {
        let message = "\(dx),\(dy)"
        guard let data = message.data(using: .utf8) else { return }
        connection?.send(content: data, completion: .contentProcessed { _ in })
    }
}
