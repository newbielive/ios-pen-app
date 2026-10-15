import Foundation
import Network

class TCPDeltaSender: ObservableObject {
    @Published var connected = false
    private var listener: NWListener?
    private var activeConnection: NWConnection?
    private let port: UInt16 = 6000

    func startListening() {
        do {
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true
            listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
        } catch {
            print("Failed to start listener: \(error)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.startListening()
            }
            return
        }

        listener?.newConnectionHandler = { [weak self] newConn in
            guard let self = self else { return }
            self.activeConnection?.cancel()
            self.activeConnection = newConn

            newConn.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self?.connected = true
                    case .failed, .cancelled:
                        self?.connected = false
                        if self?.activeConnection === newConn {
                            self?.activeConnection = nil
                        }
                    default:
                        break
                    }
                }
            }
            newConn.start(queue: .main)
        }

        listener?.stateUpdateHandler = { [weak self] state in
            if case .failed = state {
                print("Listener failed, restarting...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self?.startListening()
                }
            }
        }

        listener?.start(queue: .main)
    }

    func sendDelta(dx: CGFloat, dy: CGFloat) {
        guard let conn = activeConnection else { return }
        let message = "\(dx),\(dy)\n"
        guard let data = message.data(using: .utf8) else { return }
        conn.send(content: data, completion: .contentProcessed { _ in })
    }
}
