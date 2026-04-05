import Testing
import Foundation
@testable import ClaudeHub

@Suite("CloudInstanceType Tests")
struct CloudInstanceTypeTests {
    @Test func rawValues() {
        #expect(CloudInstanceType.ssh.rawValue == "ssh")
        #expect(CloudInstanceType.ec2.rawValue == "ec2")
        #expect(CloudInstanceType.fargate.rawValue == "fargate")
        #expect(CloudInstanceType.docker.rawValue == "docker")
    }

    @Test func displayNames() {
        #expect(CloudInstanceType.ssh.displayName == "SSH")
        #expect(CloudInstanceType.ec2.displayName == "EC2")
        #expect(CloudInstanceType.fargate.displayName == "Fargate")
        #expect(CloudInstanceType.docker.displayName == "Docker")
    }

    @Test func allCases() {
        #expect(CloudInstanceType.allCases.count == 4)
    }
}

@Suite("CloudInstanceStatus Tests")
struct CloudInstanceStatusTests {
    @Test func rawValues() {
        #expect(CloudInstanceStatus.stopped.rawValue == "stopped")
        #expect(CloudInstanceStatus.starting.rawValue == "starting")
        #expect(CloudInstanceStatus.running.rawValue == "running")
        #expect(CloudInstanceStatus.stopping.rawValue == "stopping")
        #expect(CloudInstanceStatus.terminated.rawValue == "terminated")
        #expect(CloudInstanceStatus.unknown.rawValue == "unknown")
    }

    @Test func allCases() {
        #expect(CloudInstanceStatus.allCases.count == 6)
    }
}

@Suite("SSHConfig Tests")
struct SSHConfigTests {
    @Test func defaults() {
        let config = SSHConfig()
        #expect(config.host == "")
        #expect(config.user == "")
        #expect(config.port == 22)
        #expect(config.keyPath == "")
    }

    @Test func codable() throws {
        let config = SSHConfig(host: "example.com", user: "ubuntu", port: 2222, keyPath: "~/.ssh/id_ed25519")
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(SSHConfig.self, from: data)
        #expect(decoded == config)
    }
}

@Suite("EC2Config Tests")
struct EC2ConfigTests {
    @Test func defaults() {
        let config = EC2Config()
        #expect(config.region == "us-east-1")
        #expect(config.instanceType == "t3.micro")
        #expect(config.sshUser == "ec2-user")
    }

    @Test func codable() throws {
        let config = EC2Config(
            instanceId: "i-abc123",
            region: "eu-west-1",
            instanceType: "t3.large",
            ami: "ami-abc123",
            keyPair: "my-key",
            securityGroup: "sg-123",
            sshUser: "admin",
            sshKeyPath: "~/.ssh/key.pem"
        )
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(EC2Config.self, from: data)
        #expect(decoded == config)
    }
}

@Suite("FargateConfig Tests")
struct FargateConfigTests {
    @Test func defaults() {
        let config = FargateConfig()
        #expect(config.region == "us-east-1")
        #expect(config.subnets.isEmpty)
        #expect(config.securityGroups.isEmpty)
    }

    @Test func codable() throws {
        let config = FargateConfig(
            cluster: "prod-cluster",
            taskDefinition: "my-task:3",
            region: "us-west-2",
            subnets: ["subnet-abc", "subnet-def"],
            securityGroups: ["sg-123"],
            taskArn: "arn:aws:ecs:us-west-2:123456:task/abc",
            containerName: "app",
            sshUser: "ubuntu",
            sshKeyPath: "~/.ssh/key"
        )
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(FargateConfig.self, from: data)
        #expect(decoded == config)
    }
}

@Suite("DockerConfig Tests")
struct DockerConfigTests {
    @Test func defaults() {
        let config = DockerConfig()
        #expect(config.sshPort == 2222)
        #expect(config.sshUser == "root")
        #expect(config.volumes.isEmpty)
    }

    @Test func codable() throws {
        let config = DockerConfig(
            imageName: "ubuntu:22.04",
            containerName: "dev-box",
            containerId: "abc123",
            sshPort: 3333,
            sshUser: "dev",
            sshKeyPath: "~/.ssh/id_rsa",
            volumes: ["/host:/container"]
        )
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(DockerConfig.self, from: data)
        #expect(decoded == config)
    }
}

@Suite("SyncConfig Tests")
struct SyncConfigTests {
    @Test func defaults() {
        let config = SyncConfig()
        #expect(config.remotePath == "~/projects")
        #expect(!config.excludes.isEmpty)
        #expect(config.excludes.contains("node_modules"))
        #expect(config.excludes.contains(".git"))
        #expect(config.excludes.contains(".DS_Store"))
    }

    @Test func defaultExcludes() {
        let defaults = SyncConfig.defaultExcludes
        #expect(defaults.contains("node_modules"))
        #expect(defaults.contains(".git"))
        #expect(defaults.contains("build"))
        #expect(defaults.contains("dist"))
        #expect(defaults.contains("__pycache__"))
        #expect(defaults.contains(".venv"))
        #expect(defaults.contains(".next"))
        #expect(defaults.contains(".DS_Store"))
        #expect(defaults.contains("*.log"))
        #expect(defaults.contains(".env.local"))
    }

    @Test func codable() throws {
        let config = SyncConfig(excludes: ["node_modules", ".git"], remotePath: "/opt/app")
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(SyncConfig.self, from: data)
        #expect(decoded == config)
    }
}

@Suite("CloudInstance Tests")
struct CloudInstanceTests {
    @Test func creation() {
        let instance = CloudInstance(name: "test-server", type: .ssh)
        #expect(instance.name == "test-server")
        #expect(instance.type == .ssh)
        #expect(instance.sshConfig == nil)
        #expect(instance.ec2Config == nil)
        #expect(instance.fargateConfig == nil)
        #expect(instance.dockerConfig == nil)
        #expect(instance.pairedProjectIds.isEmpty)
        #expect(instance.syncConfig.remotePath == "~/projects")
    }

    @Test func withSSHConfig() throws {
        let ssh = SSHConfig(host: "10.0.0.1", user: "admin", port: 22, keyPath: "~/.ssh/id_rsa")
        let instance = CloudInstance(name: "my-ssh", type: .ssh, sshConfig: ssh)

        let data = try JSONEncoder().encode(instance)
        let decoded = try JSONDecoder().decode(CloudInstance.self, from: data)

        #expect(decoded.id == instance.id)
        #expect(decoded.name == "my-ssh")
        #expect(decoded.type == .ssh)
        #expect(decoded.sshConfig == ssh)
        #expect(decoded.ec2Config == nil)
    }

    @Test func withEC2Config() throws {
        let ec2 = EC2Config(instanceId: "i-123", region: "us-east-1")
        let instance = CloudInstance(name: "my-ec2", type: .ec2, ec2Config: ec2)

        let data = try JSONEncoder().encode(instance)
        let decoded = try JSONDecoder().decode(CloudInstance.self, from: data)

        #expect(decoded.name == "my-ec2")
        #expect(decoded.type == .ec2)
        #expect(decoded.ec2Config == ec2)
    }

    @Test func withDockerConfig() throws {
        let docker = DockerConfig(imageName: "ubuntu:22.04", containerName: "dev")
        let instance = CloudInstance(name: "my-docker", type: .docker, dockerConfig: docker)

        let data = try JSONEncoder().encode(instance)
        let decoded = try JSONDecoder().decode(CloudInstance.self, from: data)

        #expect(decoded.name == "my-docker")
        #expect(decoded.type == .docker)
        #expect(decoded.dockerConfig?.imageName == "ubuntu:22.04")
    }

    @Test func withFargateConfig() throws {
        let fargate = FargateConfig(cluster: "prod", taskDefinition: "web:1", region: "us-west-2")
        let instance = CloudInstance(name: "my-fargate", type: .fargate, fargateConfig: fargate)

        let data = try JSONEncoder().encode(instance)
        let decoded = try JSONDecoder().decode(CloudInstance.self, from: data)

        #expect(decoded.name == "my-fargate")
        #expect(decoded.type == .fargate)
        #expect(decoded.fargateConfig?.cluster == "prod")
    }

    @Test func fullRoundtrip() throws {
        let instance = CloudInstance(
            name: "full-test",
            type: .ssh,
            sshConfig: SSHConfig(host: "host.com", user: "me", port: 22, keyPath: "/key"),
            syncConfig: SyncConfig(excludes: ["a", "b"], remotePath: "/app"),
            pairedProjectIds: ["/path/to/project1", "/path/to/project2"]
        )

        let data = try JSONEncoder().encode(instance)
        let decoded = try JSONDecoder().decode(CloudInstance.self, from: data)

        #expect(decoded.id == instance.id)
        #expect(decoded.name == instance.name)
        #expect(decoded.type == instance.type)
        #expect(decoded.sshConfig == instance.sshConfig)
        #expect(decoded.syncConfig == instance.syncConfig)
        #expect(decoded.pairedProjectIds == instance.pairedProjectIds)
    }

    @Test func hashable() {
        let a = CloudInstance(name: "a", type: .ssh)
        let b = CloudInstance(name: "b", type: .ec2)
        var set = Set<CloudInstance>()
        set.insert(a)
        set.insert(b)
        #expect(set.count == 2)
        set.insert(a)
        #expect(set.count == 2)
    }
}

@Suite("Pairing Tests")
struct PairingTests {
    @Test func addProjectId() {
        var instance = CloudInstance(name: "test", type: .ssh)
        #expect(instance.pairedProjectIds.isEmpty)

        instance.pairedProjectIds.append("/path/to/project")
        #expect(instance.pairedProjectIds.count == 1)
        #expect(instance.pairedProjectIds.first == "/path/to/project")
    }

    @Test func removeProjectId() {
        var instance = CloudInstance(
            name: "test",
            type: .ssh,
            pairedProjectIds: ["/proj1", "/proj2", "/proj3"]
        )
        #expect(instance.pairedProjectIds.count == 3)

        instance.pairedProjectIds.removeAll { $0 == "/proj2" }
        #expect(instance.pairedProjectIds.count == 2)
        #expect(!instance.pairedProjectIds.contains("/proj2"))
        #expect(instance.pairedProjectIds.contains("/proj1"))
        #expect(instance.pairedProjectIds.contains("/proj3"))
    }

    @Test func noDuplicates() {
        var instance = CloudInstance(name: "test", type: .ssh, pairedProjectIds: ["/proj1"])
        let projectId = "/proj1"
        if !instance.pairedProjectIds.contains(projectId) {
            instance.pairedProjectIds.append(projectId)
        }
        #expect(instance.pairedProjectIds.count == 1)
    }
}

@Suite("CloudInstanceRuntimeInfo Tests")
struct CloudInstanceRuntimeInfoTests {
    @Test func defaults() {
        let info = CloudInstanceRuntimeInfo()
        #expect(info.status == .unknown)
        #expect(info.publicIP == nil)
        #expect(info.isSyncing == false)
        #expect(info.lastSyncDate == nil)
        #expect(info.lastSyncError == nil)
        #expect(info.tunnelPID == nil)
    }
}
