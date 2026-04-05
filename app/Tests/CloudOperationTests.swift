import Testing
import Foundation
@testable import ClaudeHub

@Suite("runCommand Tests")
struct RunCommandTests {
    @Test func echoCommand() {
        let appState = AppState()
        let result = appState.runCommand(executable: "/bin/echo", arguments: ["hello", "world"])
        #expect(result.success)
        #expect(result.exitCode == 0)
        #expect(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "hello world")
        #expect(result.stderr.isEmpty)
    }

    @Test func failingCommand() {
        let appState = AppState()
        let result = appState.runCommand(executable: "/bin/ls", arguments: ["/nonexistent_path_12345"])
        #expect(!result.success)
        #expect(result.exitCode != 0)
        #expect(!result.stderr.isEmpty)
    }

    @Test func commandWithEnvironment() {
        let appState = AppState()
        let result = appState.runCommand(
            executable: "/usr/bin/env",
            arguments: [],
            environment: ["CLAUDE_HUB_TEST_VAR": "test_value_42"]
        )
        #expect(result.success)
        #expect(result.stdout.contains("CLAUDE_HUB_TEST_VAR=test_value_42"))
    }

    @Test func invalidExecutable() {
        let appState = AppState()
        let result = appState.runCommand(executable: "/nonexistent/binary", arguments: [])
        #expect(!result.success)
        #expect(result.exitCode == -1)
    }
}

@Suite("SSH Target Resolution Tests")
struct SSHTargetResolutionTests {
    @Test func sshType() {
        let appState = AppState()
        let instance = CloudInstance(
            name: "test-ssh",
            type: .ssh,
            sshConfig: SSHConfig(host: "10.0.0.1", user: "ubuntu", port: 2222, keyPath: "~/.ssh/id_rsa")
        )
        let target = appState.resolveSSHTarget(for: instance)
        #expect(target != nil)
        #expect(target?.host == "10.0.0.1")
        #expect(target?.user == "ubuntu")
        #expect(target?.port == 2222)
        #expect(target?.keyPath == "~/.ssh/id_rsa")
    }

    @Test func sshTypeNoConfig() {
        let appState = AppState()
        let instance = CloudInstance(name: "test", type: .ssh)
        #expect(appState.resolveSSHTarget(for: instance) == nil)
    }

    @Test func sshTypeEmptyHost() {
        let appState = AppState()
        let instance = CloudInstance(name: "test", type: .ssh, sshConfig: SSHConfig())
        #expect(appState.resolveSSHTarget(for: instance) == nil)
    }

    @Test func dockerType() {
        let appState = AppState()
        let instance = CloudInstance(
            name: "test-docker",
            type: .docker,
            dockerConfig: DockerConfig(sshPort: 3333, sshUser: "dev", sshKeyPath: "/key")
        )
        let target = appState.resolveSSHTarget(for: instance)
        #expect(target != nil)
        #expect(target?.host == "localhost")
        #expect(target?.port == 3333)
        #expect(target?.user == "dev")
        #expect(target?.keyPath == "/key")
    }

    @Test func ec2TypeNoIP() {
        let appState = AppState()
        let instance = CloudInstance(
            name: "test-ec2",
            type: .ec2,
            ec2Config: EC2Config(instanceId: "i-123", sshUser: "ec2-user")
        )
        // No public IP in runtime info, should return nil
        #expect(appState.resolveSSHTarget(for: instance) == nil)
    }

    @Test func ec2TypeWithIP() {
        let appState = AppState()
        let instance = CloudInstance(
            name: "test-ec2",
            type: .ec2,
            ec2Config: EC2Config(instanceId: "i-123", sshUser: "ec2-user", sshKeyPath: "/key.pem")
        )
        appState.cloudInstanceRuntimeInfo[instance.id] = CloudInstanceRuntimeInfo(
            status: .running,
            publicIP: "54.1.2.3"
        )
        let target = appState.resolveSSHTarget(for: instance)
        #expect(target != nil)
        #expect(target?.host == "54.1.2.3")
        #expect(target?.user == "ec2-user")
        #expect(target?.port == 22)
        #expect(target?.keyPath == "/key.pem")
    }

    @Test func fargateTypeWithIP() {
        let appState = AppState()
        let instance = CloudInstance(
            name: "test-fargate",
            type: .fargate,
            fargateConfig: FargateConfig(sshUser: "ubuntu", sshKeyPath: "/key")
        )
        appState.cloudInstanceRuntimeInfo[instance.id] = CloudInstanceRuntimeInfo(
            status: .running,
            publicIP: "10.0.0.5"
        )
        let target = appState.resolveSSHTarget(for: instance)
        #expect(target != nil)
        #expect(target?.host == "10.0.0.5")
        #expect(target?.user == "ubuntu")
    }
}

@Suite("SSH Command String Tests")
struct SSHCommandStringTests {
    @Test func basicSSH() {
        let appState = AppState()
        let instance = CloudInstance(
            name: "test",
            type: .ssh,
            sshConfig: SSHConfig(host: "myhost.com", user: "admin", port: 22, keyPath: "")
        )
        let cmd = appState.sshCommandString(for: instance)
        #expect(cmd == "ssh admin@myhost.com")
    }

    @Test func sshWithPortAndKey() {
        let appState = AppState()
        let instance = CloudInstance(
            name: "test",
            type: .ssh,
            sshConfig: SSHConfig(host: "myhost.com", user: "root", port: 2222, keyPath: "~/.ssh/key")
        )
        let cmd = appState.sshCommandString(for: instance)
        #expect(cmd == "ssh -p 2222 -i ~/.ssh/key root@myhost.com")
    }

    @Test func sshNoUser() {
        let appState = AppState()
        let instance = CloudInstance(
            name: "test",
            type: .ssh,
            sshConfig: SSHConfig(host: "myhost.com", user: "", port: 22, keyPath: "")
        )
        let cmd = appState.sshCommandString(for: instance)
        #expect(cmd == "ssh myhost.com")
    }

    @Test func noTarget() {
        let appState = AppState()
        let instance = CloudInstance(name: "test", type: .ssh)
        #expect(appState.sshCommandString(for: instance) == nil)
    }
}

@Suite("AWS Environment Resolution Tests")
struct AWSEnvironmentTests {
    @Test func defaultRegion() {
        let appState = AppState()
        let instance = CloudInstance(
            name: "test",
            type: .ec2,
            ec2Config: EC2Config(region: "eu-west-1")
        )
        let env = appState.resolveAWSEnvironment(for: instance)
        #expect(env["AWS_DEFAULT_REGION"] == "eu-west-1")
    }

    @Test func fallbackRegion() {
        let appState = AppState()
        appState.settings.awsDefaultRegion = "ap-southeast-1"
        let instance = CloudInstance(name: "test", type: .ssh)
        let env = appState.resolveAWSEnvironment(for: instance)
        #expect(env["AWS_DEFAULT_REGION"] == "ap-southeast-1")
    }

    @Test func fargateRegion() {
        let appState = AppState()
        let instance = CloudInstance(
            name: "test",
            type: .fargate,
            fargateConfig: FargateConfig(region: "us-west-2")
        )
        let env = appState.resolveAWSEnvironment(for: instance)
        #expect(env["AWS_DEFAULT_REGION"] == "us-west-2")
    }
}

@Suite("Tunnel PID Tracking Tests")
struct TunnelPIDTests {
    @Test func initiallyNil() {
        let info = CloudInstanceRuntimeInfo()
        #expect(info.tunnelPID == nil)
    }

    @Test func setAndClear() {
        var info = CloudInstanceRuntimeInfo()
        info.tunnelPID = 12345
        #expect(info.tunnelPID == 12345)
        info.tunnelPID = nil
        #expect(info.tunnelPID == nil)
    }

    @Test func closeTunnelClearsPID() {
        let appState = AppState()
        let instance = CloudInstance(name: "test", type: .ssh)
        appState.cloudInstanceRuntimeInfo[instance.id] = CloudInstanceRuntimeInfo(tunnelPID: 99999)
        #expect(appState.cloudInstanceRuntimeInfo[instance.id]?.tunnelPID == 99999)
        appState.closeTunnel(for: instance)
        #expect(appState.cloudInstanceRuntimeInfo[instance.id]?.tunnelPID == nil)
    }

    @Test func isTunnelOpenWhenNoInstance() {
        let appState = AppState()
        #expect(!appState.isTunnelOpen)
    }
}

@Suite("AWS Keychain Tests")
struct AWSKeychainTests {
    @Test func saveAndLoad() {
        let appState = AppState()
        // Clean up first
        appState.deleteAWSCredentialsFromKeychain()

        let saved = appState.saveAWSCredentialsToKeychain(accessKey: "AKIATEST123", secretKey: "secrettest456")
        #expect(saved)

        let creds = appState.loadAWSCredentialsFromKeychain()
        #expect(creds != nil)
        #expect(creds?.accessKey == "AKIATEST123")
        #expect(creds?.secretKey == "secrettest456")

        // Clean up
        appState.deleteAWSCredentialsFromKeychain()
        #expect(appState.loadAWSCredentialsFromKeychain() == nil)
    }

    @Test func loadWhenEmpty() {
        let appState = AppState()
        appState.deleteAWSCredentialsFromKeychain()
        #expect(appState.loadAWSCredentialsFromKeychain() == nil)
    }
}

@Suite("AppSettings Cloud Defaults Tests")
struct AppSettingsCloudTests {
    @Test func defaults() {
        let settings = AppSettings()
        #expect(settings.awsDefaultRegion == "us-east-1")
        #expect(settings.defaultSSHKeyPath == "")
        #expect(settings.defaultDockerfilePath == "")
    }

    @Test func codable() throws {
        var settings = AppSettings()
        settings.awsDefaultRegion = "eu-west-1"
        settings.defaultSSHKeyPath = "~/.ssh/custom_key"
        settings.defaultDockerfilePath = "/path/to/Dockerfile"

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
        #expect(decoded.awsDefaultRegion == "eu-west-1")
        #expect(decoded.defaultSSHKeyPath == "~/.ssh/custom_key")
        #expect(decoded.defaultDockerfilePath == "/path/to/Dockerfile")
    }
}
