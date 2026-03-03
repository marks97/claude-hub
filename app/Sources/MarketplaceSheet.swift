import SwiftUI

/// Sheet for browsing and installing servers from the MCP registry.
struct MarketplaceSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var searchQuery = ""
    @State private var results: [RegistryServer] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var showAddSheet = false
    @State private var prefillName = ""
    @State private var prefillCommand = ""
    @State private var prefillArgs = ""
    @State private var activeCategory: String?

    private let categories = [
        ("GitHub", "github"),
        ("Database", "database"),
        ("Search", "search"),
        ("Files", "file"),
        ("AI", "ai"),
        ("Cloud", "cloud"),
        ("Slack", "slack"),
        ("Google", "google"),
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("MCP Marketplace")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.textTertiary)
                TextField("Search MCP servers...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        activeCategory = nil
                        search(query: searchQuery)
                    }

                if isSearching {
                    ProgressView()
                        .controlSize(.small)
                }

                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        activeCategory = nil
                        search(query: "")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Theme.pampas)
            .clipShape(RoundedRectangle(cornerRadius: Theme.smallCornerRadius))
            .padding(.horizontal, 20)

            // Category chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.1) { label, query in
                        categoryChip(label: label, query: query)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }

            Divider()

            // Results
            if let error = errorMessage {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.red)
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        search(query: searchQuery)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.orange)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if results.isEmpty && !isSearching {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.textTertiary)
                    Text("Browse the MCP registry")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Search or pick a category above")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(results) { server in
                            serverCard(server)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(width: 620, height: 560)
        .sheet(isPresented: $showAddSheet) {
            AddServerSheet(
                serverName: prefillName,
                command: prefillCommand,
                args: prefillArgs
            )
            .environmentObject(appState)
        }
        .onAppear { search(query: "") }
    }

    private func categoryChip(label: String, query: String) -> some View {
        let isActive = activeCategory == query
        return Button {
            if isActive {
                activeCategory = nil
                searchQuery = ""
                search(query: "")
            } else {
                activeCategory = query
                searchQuery = query
                search(query: query)
            }
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isActive ? .white : Theme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isActive ? Theme.orange : Theme.pampas)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func serverCard(_ server: RegistryServer) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Icon + name header
            HStack(spacing: 10) {
                serverIcon(server)

                VStack(alignment: .leading, spacing: 2) {
                    Text(server.server.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    if let packages = server.server.packages, let first = packages.first {
                        Text(first.registryType)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Theme.orange)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Theme.orange.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                Spacer()
            }
            .padding(12)

            // Description
            if let desc = server.server.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
            }

            Spacer(minLength: 0)

            // Footer: package identifier + add button
            Divider()
                .foregroundStyle(Theme.cardBorder)

            HStack {
                if let packages = server.server.packages, let first = packages.first {
                    Text(first.identifier)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                Button {
                    addFromRegistry(server)
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                            .font(.system(size: 9))
                        Text("Add")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(minHeight: 140)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.cardBorder, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
    }

    @ViewBuilder
    private func serverIcon(_ server: RegistryServer) -> some View {
        if let iconURL = server.server.iconURL {
            AsyncImage(url: iconURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                case .failure:
                    serverIconPlaceholder
                default:
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 32, height: 32)
                }
            }
        } else {
            serverIconPlaceholder
        }
    }

    private var serverIconPlaceholder: some View {
        Image(systemName: "server.rack")
            .font(.system(size: 16))
            .foregroundStyle(Theme.textTertiary)
            .frame(width: 32, height: 32)
            .background(Theme.pampas)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func search(query: String) {
        isSearching = true
        errorMessage = nil

        appState.searchRegistry(query: query) { result in
            isSearching = false
            switch result {
            case .success(let servers):
                results = servers
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func addFromRegistry(_ server: RegistryServer) {
        guard let pkg = server.server.packages?.first else {
            prefillName = server.server.displayName
            prefillCommand = ""
            prefillArgs = ""
            showAddSheet = true
            return
        }

        prefillName = server.server.displayName

        switch pkg.registryType {
        case "npm":
            prefillCommand = "npx"
            prefillArgs = "-y \(pkg.identifier)"
        case "pypi":
            prefillCommand = "uvx"
            prefillArgs = pkg.identifier
        case "docker", "oci":
            prefillCommand = "docker"
            prefillArgs = "run --rm -i \(pkg.identifier)"
        default:
            prefillCommand = pkg.identifier
            prefillArgs = ""
        }

        showAddSheet = true
    }
}
