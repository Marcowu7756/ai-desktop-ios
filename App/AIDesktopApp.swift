// App — entry point

#if canImport(SwiftUI)
import SwiftUI

@main
struct AIDesktopApp: App {
    @StateObject private var model = CompositionRoot.makeAppModel()

    var body: some Scene {
        WindowGroup {
            MainSceneView(model: model)
        }
    }
}
#endif
