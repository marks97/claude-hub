import SwiftUI

/// Root view: NavigationSplitView with sidebar and detail pane, plus toolbar actions.
struct MainWindowView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView()
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                claudeStatusIndicator

                Button {
                    appState.discoverTools()
                } label: {
                    if appState.isDiscovering {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Scan Tools", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                .disabled(appState.isDiscovering || appState.selectedProject == nil)
                .help("Discover available tools from MCP servers")

                Button {
                    if appState.isClaudeRunning {
                        appState.applyAndRestart()
                    } else {
                        appState.startClaude()
                    }
                } label: {
                    if appState.isRestarting {
                        ProgressView()
                            .controlSize(.small)
                    } else if appState.isClaudeRunning {
                        Label("Apply & Restart", systemImage: "arrow.clockwise")
                    } else {
                        Label("Start Claude", systemImage: "play.fill")
                    }
                }
                .disabled(appState.isRestarting)
                .help(appState.isClaudeRunning ? "Save config and restart Claude Desktop" : "Start Claude Desktop")
            }
        }
        .frame(
            minWidth: Theme.windowMinWidth,
            minHeight: Theme.windowMinHeight
        )
    }

    private var claudeStatusIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(appState.isClaudeRunning ? Theme.green : Theme.red)
                .frame(width: 8, height: 8)
            Text(appState.isClaudeRunning ? "Claude Running" : "Claude Stopped")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.trailing, 8)
    }
}
