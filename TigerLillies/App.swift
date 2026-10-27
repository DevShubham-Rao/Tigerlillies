import SwiftUI

@main
struct TigerLilliesApp: App {
    @StateObject private var store = TigerStore()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(.black)
        }
    }
}
