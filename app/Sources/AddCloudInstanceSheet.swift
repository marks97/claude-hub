import SwiftUI

/// Sheet for adding a new cloud instance.
struct AddCloudInstanceSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var instanceType: CloudInstanceType = .ssh

    // SSH
    @State private var sshHost = ""
    @State private var sshUser = ""
    @State private var sshPort = "22"
    @State private var sshKeyPath = ""
    @State private var sshTestResult: String?
    @State private var sshTesting = false

    // EC2
    @State private var ec2InstanceId = ""
    @State private var ec2Region = "us-east-1"
    @State private var ec2InstanceType = "t3.micro"
    @State private var ec2Ami = ""
    @State private var ec2KeyPair = ""
    @State private var ec2SecurityGroup = ""
    @State private var ec2SshUser = "ec2-user"
    @State private var ec2SshKeyPath = ""

    // Fargate
    @State private var fargateCluster = ""
    @State private var fargateTaskDef = ""
    @State private var fargateRegion = "us-east-1"
    @State private var fargateSubnets = ""
    @State private var fargateSecurityGroups = ""
    @State private var fargateContainerName = ""
    @State private var fargateSshUser = ""
    @State private var fargateSshKeyPath = ""

    // Docker
    @State private var dockerImage = ""
    @State private var dockerContainerName = ""
    @State private var dockerSshPort = "2222"
    @State private var dockerSshUser = "root"
    @State private var dockerSshKeyPath = ""
    @State private var dockerVolumes = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Cloud Instance")
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
            .padding(20)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    fieldGroup(label: "Instance Name") {
                        TextField("e.g. dev-server", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    fieldGroup(label: "Type") {
                        Picker("", selection: $instanceType) {
                            ForEach(CloudInstanceType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    switch instanceType {
                    case .ssh: sshFields
                    case .ec2: ec2Fields
                    case .fargate: fargateFields
                    case .docker: dockerFields
                    }
                }
                .padding(20)
            }

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("Add Instance") { addInstance() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || !isTypeConfigValid)
            }
            .padding(16)
        }
        .frame(width: 500, height: 560)
    }

    // MARK: - Type-Specific Fields

    private var sshFields: some View {
        Group {
            fieldGroup(label: "Host") {
                TextField("e.g. 192.168.1.100 or myhost.example.com", text: $sshHost)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 12) {
                fieldGroup(label: "User") {
                    TextField("e.g. ubuntu", text: $sshUser)
                        .textFieldStyle(.roundedBorder)
                }
                fieldGroup(label: "Port") {
                    TextField("22", text: $sshPort)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
            }

            fieldGroup(label: "SSH Key Path") {
                TextField("e.g. ~/.ssh/id_rsa", text: $sshKeyPath)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button {
                    testSSHConnection()
                } label: {
                    HStack(spacing: 4) {
                        if sshTesting {
                            ProgressView()
                                .controlSize(.mini)
                        }
                        Text("Test Connection")
                    }
                    .font(.system(size: 12, weight: .medium))
                }
                .disabled(sshHost.isEmpty || sshTesting)

                if let result = sshTestResult {
                    Text(result)
                        .font(.system(size: 11))
                        .foregroundStyle(result.contains("Success") ? Theme.green : Theme.red)
                }
            }
        }
    }

    private var ec2Fields: some View {
        Group {
            fieldGroup(label: "Instance ID") {
                TextField("e.g. i-0abcdef1234567890", text: $ec2InstanceId)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 12) {
                fieldGroup(label: "Region") {
                    TextField("us-east-1", text: $ec2Region)
                        .textFieldStyle(.roundedBorder)
                }
                fieldGroup(label: "Instance Type") {
                    TextField("t3.micro", text: $ec2InstanceType)
                        .textFieldStyle(.roundedBorder)
                }
            }

            fieldGroup(label: "AMI") {
                TextField("e.g. ami-0abcdef1234567890", text: $ec2Ami)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 12) {
                fieldGroup(label: "Key Pair") {
                    TextField("e.g. my-key-pair", text: $ec2KeyPair)
                        .textFieldStyle(.roundedBorder)
                }
                fieldGroup(label: "Security Group") {
                    TextField("e.g. sg-0123456789", text: $ec2SecurityGroup)
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack(spacing: 12) {
                fieldGroup(label: "SSH User") {
                    TextField("ec2-user", text: $ec2SshUser)
                        .textFieldStyle(.roundedBorder)
                }
                fieldGroup(label: "SSH Key Path") {
                    TextField("~/.ssh/my-key.pem", text: $ec2SshKeyPath)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    private var fargateFields: some View {
        Group {
            HStack(spacing: 12) {
                fieldGroup(label: "Cluster") {
                    TextField("e.g. my-cluster", text: $fargateCluster)
                        .textFieldStyle(.roundedBorder)
                }
                fieldGroup(label: "Region") {
                    TextField("us-east-1", text: $fargateRegion)
                        .textFieldStyle(.roundedBorder)
                }
            }

            fieldGroup(label: "Task Definition") {
                TextField("e.g. my-task:1", text: $fargateTaskDef)
                    .textFieldStyle(.roundedBorder)
            }

            fieldGroup(label: "Subnets") {
                TextField("comma-separated subnet IDs", text: $fargateSubnets)
                    .textFieldStyle(.roundedBorder)
                Text("e.g. subnet-abc123,subnet-def456")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
            }

            fieldGroup(label: "Security Groups") {
                TextField("comma-separated security group IDs", text: $fargateSecurityGroups)
                    .textFieldStyle(.roundedBorder)
            }

            fieldGroup(label: "Container Name") {
                TextField("e.g. app", text: $fargateContainerName)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 12) {
                fieldGroup(label: "SSH User") {
                    TextField("optional", text: $fargateSshUser)
                        .textFieldStyle(.roundedBorder)
                }
                fieldGroup(label: "SSH Key Path") {
                    TextField("optional", text: $fargateSshKeyPath)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    private var dockerFields: some View {
        Group {
            fieldGroup(label: "Image Name") {
                TextField("e.g. ubuntu:22.04", text: $dockerImage)
                    .textFieldStyle(.roundedBorder)
            }

            fieldGroup(label: "Container Name") {
                TextField("e.g. my-dev-container", text: $dockerContainerName)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 12) {
                fieldGroup(label: "SSH Port") {
                    TextField("2222", text: $dockerSshPort)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                fieldGroup(label: "SSH User") {
                    TextField("root", text: $dockerSshUser)
                        .textFieldStyle(.roundedBorder)
                }
            }

            fieldGroup(label: "SSH Key Path") {
                TextField("e.g. ~/.ssh/id_rsa", text: $dockerSshKeyPath)
                    .textFieldStyle(.roundedBorder)
            }

            fieldGroup(label: "Volumes") {
                TextField("comma-separated volume mounts", text: $dockerVolumes)
                    .textFieldStyle(.roundedBorder)
                Text("e.g. /host/path:/container/path,/data:/data")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }

    // MARK: - Helpers

    private func fieldGroup<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            content()
        }
    }

    private var isTypeConfigValid: Bool {
        switch instanceType {
        case .ssh:
            return !sshHost.trimmingCharacters(in: .whitespaces).isEmpty
        case .ec2:
            return !ec2Region.trimmingCharacters(in: .whitespaces).isEmpty
        case .fargate:
            return !fargateCluster.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !fargateTaskDef.trimmingCharacters(in: .whitespaces).isEmpty
        case .docker:
            return !dockerImage.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    private func addInstance() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        var instance = CloudInstance(name: trimmedName, type: instanceType)

        switch instanceType {
        case .ssh:
            instance.sshConfig = SSHConfig(
                host: sshHost.trimmingCharacters(in: .whitespaces),
                user: sshUser.trimmingCharacters(in: .whitespaces),
                port: Int(sshPort) ?? 22,
                keyPath: sshKeyPath.trimmingCharacters(in: .whitespaces)
            )
        case .ec2:
            instance.ec2Config = EC2Config(
                instanceId: ec2InstanceId.trimmingCharacters(in: .whitespaces),
                region: ec2Region.trimmingCharacters(in: .whitespaces),
                instanceType: ec2InstanceType.trimmingCharacters(in: .whitespaces),
                ami: ec2Ami.trimmingCharacters(in: .whitespaces),
                keyPair: ec2KeyPair.trimmingCharacters(in: .whitespaces),
                securityGroup: ec2SecurityGroup.trimmingCharacters(in: .whitespaces),
                sshUser: ec2SshUser.trimmingCharacters(in: .whitespaces),
                sshKeyPath: ec2SshKeyPath.trimmingCharacters(in: .whitespaces)
            )
        case .fargate:
            let subnets = fargateSubnets.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            let secGroups = fargateSecurityGroups.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            instance.fargateConfig = FargateConfig(
                cluster: fargateCluster.trimmingCharacters(in: .whitespaces),
                taskDefinition: fargateTaskDef.trimmingCharacters(in: .whitespaces),
                region: fargateRegion.trimmingCharacters(in: .whitespaces),
                subnets: subnets,
                securityGroups: secGroups,
                containerName: fargateContainerName.trimmingCharacters(in: .whitespaces),
                sshUser: fargateSshUser.trimmingCharacters(in: .whitespaces),
                sshKeyPath: fargateSshKeyPath.trimmingCharacters(in: .whitespaces)
            )
        case .docker:
            let vols = dockerVolumes.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            instance.dockerConfig = DockerConfig(
                imageName: dockerImage.trimmingCharacters(in: .whitespaces),
                containerName: dockerContainerName.trimmingCharacters(in: .whitespaces),
                sshPort: Int(dockerSshPort) ?? 2222,
                sshUser: dockerSshUser.trimmingCharacters(in: .whitespaces),
                sshKeyPath: dockerSshKeyPath.trimmingCharacters(in: .whitespaces),
                volumes: vols
            )
        }

        appState.addCloudInstance(instance)
        dismiss()
    }

    private func testSSHConnection() {
        sshTesting = true
        sshTestResult = nil

        let host = sshHost.trimmingCharacters(in: .whitespaces)
        let user = sshUser.trimmingCharacters(in: .whitespaces)
        let port = sshPort.trimmingCharacters(in: .whitespaces)
        let keyPath = sshKeyPath.trimmingCharacters(in: .whitespaces)

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
            var args = ["-o", "BatchMode=yes", "-o", "ConnectTimeout=5", "-o", "StrictHostKeyChecking=no"]
            if !port.isEmpty, port != "22" {
                args += ["-p", port]
            }
            if !keyPath.isEmpty {
                let expanded = (keyPath as NSString).expandingTildeInPath
                args += ["-i", expanded]
            }
            let target = user.isEmpty ? host : "\(user)@\(host)"
            args += [target, "echo", "ok"]
            process.arguments = args

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()
                let success = process.terminationStatus == 0
                DispatchQueue.main.async {
                    sshTestResult = success ? "Success — connected!" : "Failed — check credentials"
                    sshTesting = false
                }
            } catch {
                DispatchQueue.main.async {
                    sshTestResult = "Error — \(error.localizedDescription)"
                    sshTesting = false
                }
            }
        }
    }
}
