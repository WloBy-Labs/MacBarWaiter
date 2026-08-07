import AppKit

#if SWIFT_PACKAGE
import MacBarWaiterCore
#endif

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let controller = AppController()
app.delegate = controller
app.run()
