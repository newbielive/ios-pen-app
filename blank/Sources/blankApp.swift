import SwiftUI

@main
struct blankApp: App {
    init() {
        UIApplication.shared.isIdleTimerDisabled = true
    }
    var body: some Scene {
        WindowGroup {
            TouchCaptureView()
        }
    }
}
