import Testing
import Foundation
@testable import ClaudeHub

@Suite("Rsync Command Construction Tests")
struct RsyncCommandTests {
    @Test func pushBasic() {
        let appState = AppState()
        let instance = CloudInstance(
            name: "test",
            type: .ssh,
            sshConfig: SSHConfig(host: "myhost.com", user: "ubuntu", port: 22, keyPath: "")
        )
        let project = Project(name: "myproject", path: "/tmp/myproject")

        let args = appState.buildRsyncArgs(project: project, instance: instance, direction: .push)
        #expect(args != nil)
        guard let args = args else { return }

        #expect(args.contains("-avz"))
        #expect(args.contains("--delete"))
        #expect(args.contains("-e"))
        #expect(args.last == "ubuntu@myhost.com:~/projects/myproject/")
        #expect(args[args.count - 2] == "/tmp/myproject/")
    }

    @Test func pullBasic() {
        let appState = AppState()
        let instance = CloudInstance(
            name: "test",
            type: .ssh,
            sshConfig: SSHConfig(host: "myhost.com", user: "ubuntu", port: 22, keyPath: "")
        )
        let project = Project(name: "myproject", path: "/tmp/myproject")

        let args = appState.buildRsyncArgs(project: project, instance: instance, direction: .pull)
        #expect(args != nil)
        guard let args = args else { return }

        // For pull, remote is source, local is destination
        #expect(args.last == "/tmp/myproject/")
        #expect(args[args.count - 2] == "ubuntu@myhost.com:~/projects/myproject/")
    }

    @Test func withCustomPort() {
        let appState = AppState()
        let instance = CloudInstance(
            name: "test",
            type: .ssh,
            sshConfig: SSHConfig(host: "myhost.com", user: "admin", port: 2222, keyPath: "")
        )
        let project = Project(name: "proj", path: "/tmp/proj")

        let args = appState.buildRsyncArgs(project: project, instance: instance, direction: .push)
        #expect(args != nil)
        guard let args = args else { return }

        // The SSH transport command should include -p 2222
        if let eIdx = args.firstIndex(of: "-e"), eIdx + 1 < args.count {
            let sshCmd = args[eIdx + 1]
            #expect(sshCmd.contains("-p 2222"))
        }
    }

    @Test func withKeyPath() {
        let appState = AppState()
        let instance = CloudInstance(
            name: "test",
            type: .ssh,
            sshConfig: SSHConfig(host: "h", user: "u", port: 22, keyPath: "/path/to/key")
        )
        let project = Project(name: "proj", path: "/tmp/proj")

        let args = appState.buildRsyncArgs(project: project, instance: instance, direction: .push)
        #expect(args != nil)
        guard let args = args else { return }

        if let eIdx = args.firstIndex(of: "-e"), eIdx + 1 < args.count {
            let sshCmd = args[eIdx + 1]
            #expect(sshCmd.contains("-i /path/to/key"))
        }
    }

    @Test func withSyncConfigExcludes() {
        let appState = AppState()
        var instance = CloudInstance(
            name: "test",
            type: .ssh,
            sshConfig: SSHConfig(host: "h", user: "u", port: 22, keyPath: "")
        )
        instance.syncConfig = SyncConfig(excludes: ["node_modules", ".git", "dist"], remotePath: "/opt/app")
        let project = Project(name: "proj", path: "/tmp/proj")

        let args = appState.buildRsyncArgs(project: project, instance: instance, direction: .push)
        #expect(args != nil)
        guard let args = args else { return }

        // Check excludes are present
        var excludeCount = 0
        for (i, arg) in args.enumerated() {
            if arg == "--exclude" && i + 1 < args.count {
                excludeCount += 1
            }
        }
        #expect(excludeCount == 3)

        // Check custom remote path
        #expect(args.last == "u@h:/opt/app/proj/")
    }

    @Test func noTargetReturnsNil() {
        let appState = AppState()
        let instance = CloudInstance(name: "test", type: .ssh) // no config
        let project = Project(name: "proj", path: "/tmp/proj")
        #expect(appState.buildRsyncArgs(project: project, instance: instance, direction: .push) == nil)
    }

    @Test func dockerType() {
        let appState = AppState()
        let instance = CloudInstance(
            name: "test",
            type: .docker,
            dockerConfig: DockerConfig(sshPort: 3333, sshUser: "dev", sshKeyPath: "/key")
        )
        let project = Project(name: "proj", path: "/tmp/proj")

        let args = appState.buildRsyncArgs(project: project, instance: instance, direction: .push)
        #expect(args != nil)
        guard let args = args else { return }

        // Docker uses localhost
        #expect(args.last == "dev@localhost:~/projects/proj/")

        // SSH command should include -p 3333
        if let eIdx = args.firstIndex(of: "-e"), eIdx + 1 < args.count {
            #expect(args[eIdx + 1].contains("-p 3333"))
        }
    }
}

@Suite("SSH Configs JSON Generation Tests")
struct SSHConfigsJSONTests {
    @Test func basicGeneration() throws {
        let appState = AppState()
        let instance = CloudInstance(
            name: "my-server",
            type: .ssh,
            sshConfig: SSHConfig(host: "10.0.0.1", user: "ubuntu", port: 22, keyPath: "/home/.ssh/id_rsa")
        )

        let data = appState.generateSSHConfigsJSON(for: instance)
        #expect(data != nil)
        guard let data = data else { return }

        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Check structure
        let configs = json["configs"] as! [[String: Any]]
        #expect(configs.count == 1)

        let config = configs[0]
        #expect(config["name"] as? String == "my-server")
        #expect(config["sshHost"] as? String == "ubuntu@10.0.0.1")
        #expect(config["sshPort"] as? Int == 22)
        #expect(config["sshIdentityFile"] as? String == "/home/.ssh/id_rsa")
        #expect(config["id"] as? String == instance.id.uuidString)

        // Check trustedHosts
        let trusted = json["trustedHosts"] as! [String]
        #expect(trusted.contains("ubuntu@10.0.0.1:22"))
    }

    @Test func noKeyPath() throws {
        let appState = AppState()
        let instance = CloudInstance(
            name: "test",
            type: .ssh,
            sshConfig: SSHConfig(host: "host.com", user: "root", port: 22, keyPath: "")
        )

        let data = appState.generateSSHConfigsJSON(for: instance)
        #expect(data != nil)
        guard let data = data else { return }

        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let configs = json["configs"] as! [[String: Any]]
        #expect(configs[0]["sshIdentityFile"] == nil)
    }

    @Test func noTargetReturnsNil() {
        let appState = AppState()
        let instance = CloudInstance(name: "test", type: .ssh) // no config
        #expect(appState.generateSSHConfigsJSON(for: instance) == nil)
    }

    @Test func customPort() throws {
        let appState = AppState()
        let instance = CloudInstance(
            name: "custom",
            type: .ssh,
            sshConfig: SSHConfig(host: "h", user: "u", port: 2222, keyPath: "")
        )

        let data = appState.generateSSHConfigsJSON(for: instance)
        #expect(data != nil)
        guard let data = data else { return }

        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let configs = json["configs"] as! [[String: Any]]
        #expect(configs[0]["sshPort"] as? Int == 2222)

        let trusted = json["trustedHosts"] as! [String]
        #expect(trusted.contains("u@h:2222"))
    }
}

@Suite("Cloud Settings Dir Tests")
struct CloudSettingsDirTests {
    @Test func basicPath() {
        let appState = AppState()
        let instance = CloudInstance(name: "My Server", type: .ssh)
        let dir = appState.cloudSettingsDir(for: instance)
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        #expect(dir == "\(home)/claude-cloud-my-server")
    }

    @Test func withSpaces() {
        let appState = AppState()
        let instance = CloudInstance(name: "Dev Box 2", type: .docker)
        let dir = appState.cloudSettingsDir(for: instance)
        #expect(dir.hasSuffix("/claude-cloud-dev-box-2"))
    }
}

@Suite("Crontab Generation Tests")
struct CrontabGenerationTests {
    @Test func basicEntry() {
        let appState = AppState()
        let task = AppState.ScheduledTask(
            name: "daily-report",
            description: "Generate daily report",
            filePath: "/Users/test/.claude/scheduled-tasks/daily-report/SKILL.md"
        )

        let entry = appState.buildCrontabEntry(
            task: task,
            cronExpression: "0 9 * * *",
            remotePath: "~/projects",
            projectName: "myapp"
        )

        #expect(entry.hasPrefix("0 9 * * *"))
        #expect(entry.contains("cd ~/projects/myapp"))
        #expect(entry.contains("claude -p"))
        #expect(entry.contains("--permission-mode dontAsk"))
        #expect(entry.contains("--max-turns 50"))
        #expect(entry.contains("daily-report/SKILL.md"))
    }

    @Test func customCron() {
        let appState = AppState()
        let task = AppState.ScheduledTask(
            name: "check",
            description: "",
            filePath: "/home/.claude/scheduled-tasks/check/SKILL.md"
        )

        let entry = appState.buildCrontabEntry(
            task: task,
            cronExpression: "*/5 * * * 1-5",
            remotePath: "/opt/app",
            projectName: "web"
        )

        #expect(entry.hasPrefix("*/5 * * * 1-5"))
        #expect(entry.contains("cd /opt/app/web"))
    }
}

@Suite("Project Picker Logic Tests")
struct ProjectPickerTests {
    @Test func noProjects() {
        let instance = CloudInstance(name: "test", type: .ssh, pairedProjectIds: [])
        #expect(instance.pairedProjectIds.isEmpty)
    }

    @Test func oneProject() {
        let instance = CloudInstance(name: "test", type: .ssh, pairedProjectIds: ["/proj1"])
        #expect(instance.pairedProjectIds.count == 1)
    }

    @Test func multipleProjects() {
        let instance = CloudInstance(name: "test", type: .ssh, pairedProjectIds: ["/proj1", "/proj2", "/proj3"])
        #expect(instance.pairedProjectIds.count == 3)
    }

    @Test func cloudInstancesForProject() {
        let appState = AppState()
        let instance1 = CloudInstance(name: "a", type: .ssh, pairedProjectIds: ["/proj1"])
        let instance2 = CloudInstance(name: "b", type: .ec2, pairedProjectIds: ["/proj1", "/proj2"])
        let instance3 = CloudInstance(name: "c", type: .docker, pairedProjectIds: ["/proj2"])

        appState.cloudInstances = [instance1, instance2, instance3]

        let project1 = Project(name: "proj1", path: "/proj1")
        let project2 = Project(name: "proj2", path: "/proj2")
        let project3 = Project(name: "proj3", path: "/proj3")

        let paired1 = appState.cloudInstancesForProject(project1)
        #expect(paired1.count == 2) // a and b

        let paired2 = appState.cloudInstancesForProject(project2)
        #expect(paired2.count == 2) // b and c

        let paired3 = appState.cloudInstancesForProject(project3)
        #expect(paired3.count == 0)
    }
}

@Suite("Scheduled Task Discovery Tests")
struct ScheduledTaskDiscoveryTests {
    @Test func emptyWhenNoDirectory() {
        let appState = AppState()
        // This should return empty if no tasks exist (or dir doesn't exist)
        // The method handles missing directories gracefully
        let tasks = appState.discoverScheduledTasks()
        // We can't assert exact count since it depends on the user's actual filesystem,
        // but we can verify it returns without crashing
        _ = tasks
    }
}
