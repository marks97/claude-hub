import SwiftUI

/// macOS Settings window (Cmd+,).
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var newRegistryURL = ""
    @State private var awsAccessKey = ""
    @State private var awsSecretKey = ""
    @State private var keychainStatus: String?

    private var previewName: String {
        appState.settings.isolationDisplayName(for: "MyProject")
    }

    var body: some View {
        Form {
            // MARK: - Isolation Naming
            Section {
                HStack {
                    Text("Prefix")
                        .frame(width: 50, alignment: .leading)
                    TextField("e.g. Claude - ", text: $appState.settings.isolationPrefix)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                        .onChange(of: appState.settings.isolationPrefix) { _, _ in
                            appState.saveSettings()
                        }
                }

                HStack {
                    Text("Suffix")
                        .frame(width: 50, alignment: .leading)
                    TextField("e.g.  (Claude)", text: $appState.settings.isolationSuffix)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                        .onChange(of: appState.settings.isolationSuffix) { _, _ in
                            appState.saveSettings()
                        }
                }

                HStack(spacing: 4) {
                    Text("Dock name:")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(previewName)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.orange)
                }
            } header: {
                Text("Isolated Instance Naming")
            } footer: {
                Text("Isolated Claude instances show as separate apps in the Dock. Configure how their names appear.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            // MARK: - Cloud Defaults
            Section {
                HStack {
                    Text("Default Region")
                        .frame(width: 120, alignment: .leading)
                    TextField("us-east-1", text: $appState.settings.awsDefaultRegion)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                        .onChange(of: appState.settings.awsDefaultRegion) { _, _ in
                            appState.saveSettings()
                        }
                }

                HStack {
                    Text("Default SSH Key")
                        .frame(width: 120, alignment: .leading)
                    TextField("~/.ssh/id_rsa", text: $appState.settings.defaultSSHKeyPath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                        .onChange(of: appState.settings.defaultSSHKeyPath) { _, _ in
                            appState.saveSettings()
                        }
                    Button {
                        let panel = NSOpenPanel()
                        panel.title = "Select SSH Key"
                        panel.canChooseFiles = true
                        panel.canChooseDirectories = false
                        panel.directoryURL = URL(fileURLWithPath: NSHomeDirectory() + "/.ssh")
                        if panel.runModal() == .OK, let url = panel.url {
                            appState.settings.defaultSSHKeyPath = url.path
                            appState.saveSettings()
                        }
                    } label: {
                        Image(systemName: "folder")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                }

                HStack {
                    Text("Dockerfile Path")
                        .frame(width: 120, alignment: .leading)
                    TextField("optional", text: $appState.settings.defaultDockerfilePath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                        .onChange(of: appState.settings.defaultDockerfilePath) { _, _ in
                            appState.saveSettings()
                        }
                }
            } header: {
                Text("Cloud Defaults")
            } footer: {
                Text("Default values used when creating new cloud instances.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            // MARK: - AWS Credentials
            Section {
                HStack {
                    Text("Access Key")
                        .frame(width: 100, alignment: .leading)
                    SecureField("AKIA...", text: $awsAccessKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                }

                HStack {
                    Text("Secret Key")
                        .frame(width: 100, alignment: .leading)
                    SecureField("secret", text: $awsSecretKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                }

                HStack {
                    Button("Store in Keychain") {
                        let ak = awsAccessKey.trimmingCharacters(in: .whitespaces)
                        let sk = awsSecretKey.trimmingCharacters(in: .whitespaces)
                        guard !ak.isEmpty, !sk.isEmpty else {
                            keychainStatus = "Both fields required"
                            return
                        }
                        if appState.saveAWSCredentialsToKeychain(accessKey: ak, secretKey: sk) {
                            keychainStatus = "Saved to Keychain"
                            awsAccessKey = ""
                            awsSecretKey = ""
                        } else {
                            keychainStatus = "Failed to save"
                        }
                    }
                    .disabled(awsAccessKey.trimmingCharacters(in: .whitespaces).isEmpty ||
                              awsSecretKey.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button("Clear from Keychain") {
                        appState.deleteAWSCredentialsFromKeychain()
                        keychainStatus = "Removed from Keychain"
                    }

                    if let status = keychainStatus {
                        Text(status)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary)
                    }

                    Spacer()

                    if appState.loadAWSCredentialsFromKeychain() != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.green)
                            Text("Stored")
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                    }
                }
            } header: {
                Text("AWS Credentials")
            } footer: {
                Text("Stored securely in macOS Keychain. Used as fallback when no project .env has AWS keys.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            // MARK: - Marketplace Sources
            Section {
                ForEach(appState.settings.registryURLs, id: \.self) { url in
                    HStack {
                        Text(url)
                            .font(.system(size: 12, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button {
                            appState.settings.registryURLs.removeAll { $0 == url }
                            appState.saveSettings()
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(Theme.red)
                        }
                        .buttonStyle(.plain)
                        .disabled(appState.settings.registryURLs.count <= 1)
                    }
                }

                HStack {
                    TextField("https://registry.example.com/servers", text: $newRegistryURL)
                        .font(.system(size: 12, design: .monospaced))
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addRegistryURL() }

                    Button("Add") { addRegistryURL() }
                        .disabled(newRegistryURL.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } header: {
                Text("Marketplace Sources")
            } footer: {
                Text("Registry URLs used to browse and install MCP servers.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 540)
    }

    private func addRegistryURL() {
        let url = newRegistryURL.trimmingCharacters(in: .whitespaces)
        guard !url.isEmpty, !appState.settings.registryURLs.contains(url) else { return }
        appState.settings.registryURLs.append(url)
        appState.saveSettings()
        newRegistryURL = ""
    }
}
