import SwiftUI

// Root: custom tab bar (Levels / Guide / Settings). The active puzzle is shown as a
// full-screen overlay while store.session != nil — avoids nested-NavigationLink dismiss
// pitfalls on iOS 15.
struct GlyphRootView: View {
    @EnvironmentObject var store: GlyphStore
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            GlyphTheme.bgDeep.ignoresSafeArea()

            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case 0:
                        NavigationView { GlyphLevelsView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 1:
                        NavigationView { GlyphHowToView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    default:
                        NavigationView { GlyphSettingsView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                tabBar
            }

            // Active puzzle overlay.
            if store.session != nil {
                GlyphPlayView()
                    .transition(.opacity)
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(0, "Levels", AnyView(GlyphGridIcon(size: 22, color: tabColor(0))))
            tabButton(1, "Guide", AnyView(GlyphBookIcon(size: 22, color: tabColor(1))))
            tabButton(2, "Settings", AnyView(GlyphGearIcon(size: 22, color: tabColor(2))))
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            GlyphTheme.bgPanel
                .overlay(Rectangle().fill(GlyphTheme.stoneEdge.opacity(0.5)).frame(height: 0.5), alignment: .top)
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tabColor(_ i: Int) -> Color {
        selectedTab == i ? GlyphTheme.ember : GlyphTheme.textFaint
    }

    private func tabButton(_ index: Int, _ label: String, _ icon: AnyView) -> some View {
        Button(action: { selectedTab = index }) {
            VStack(spacing: 4) {
                icon.frame(height: 24)
                Text(label)
                    .font(.system(size: 10, weight: selectedTab == index ? .heavy : .semibold, design: .rounded))
                    .foregroundColor(tabColor(index))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
