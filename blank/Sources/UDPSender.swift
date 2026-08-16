import Foundation
import Network

class UDPDeltaSender: ObservableObject {
    @Published var connected = false
    private var connection: NWConnection?
    private var broadcastConnection: NWConnection?
    private let discoveryPort: UInt16 = 5006
    private let dataPort: UInt16 = 5005

    // Broadcasts "DISCOVER_PC" on the local subnet, listens for a reply
    // carrying the PC's IP, then locks onto that IP for all future
    // movement data — no hardcoded IP needed.
    func startDiscovery() {
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true

        let listener = try? NWListener(using: params, on: NWEndpoint.Port(rawValue: discoveryPort + 1)!)
        listener?.newConnectionHandler = { [weak self] conn in
            conn.start(queue: .main)
            conn.receiveMessage { data, _, _, _ in
                guard let data = data,
                      let message = String(data: data, encoding: .utf8),
                      message.hasPrefix("PC_HERE") else { return }
                // Extract sender IP from the connection's remote endpoint
                if case let .hostPort(host, _) = conn.currentPath?.remoteEndpoint {
                    self?.connectToPC(host: "\(host)")
                }
            }
        }
        listener?.start(queue: .main)

        let broadcastEndpoint = NWEndpoint.hostPort(host: "255.255.255.255", port: NWEndpoint.Port(rawValue: discoveryPort)!)
        let conn = NWConnection(to: broadcastEndpoint, using: params)
        conn.start(queue: .main)
        broadcastConnection = conn

        sendDiscoveryBroadcast()
        // Retry broadcast every 2s until connected
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            if self.connected {
                timer.invalidate()
                return
            }
            self.sendDiscoveryBroadcast()
        }
    }

    private func sendDiscoveryBroadcast() {
        let message = "DISCOVER_PC"
        guard let data = message.data(using: .utf8) else { return }
        broadcastConnection?.send(content: data, completion: .contentProcessed { _ in })
    }

    private func connectToPC(host: String) {
        let conn = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: dataPort)!,
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