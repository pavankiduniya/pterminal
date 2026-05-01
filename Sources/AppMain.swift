import AppKit
import Foundation

@main
enum PTerminalApp {
    static func main() {
        let args = CommandLine.arguments

        // Headless mode: PTerminal --headless "command"
        if args.contains("--headless") || args.contains("-e") {
            runHeadless(args: args)
            return
        }

        // Normal GUI mode
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }

    static func runHeadless(args: [String]) {
        let headless = HeadlessTerminal()

        if args.contains("--help") || args.count < 3 {
            print("""
            PTerminal - Headless Mode

            Usage:
              PTerminal --headless "command"     Run a command and print output
              PTerminal --headless --script file  Run a script file
              PTerminal -e "command"              Short form

            Options:
              --timeout N    Set timeout in seconds (default: 30)
              --raw          Don't strip ANSI escape codes from output

            Examples:
              PTerminal --headless "ls -la"
              PTerminal --headless "df -h && echo done"
              PTerminal --headless --script deploy.sh
              PTerminal -e "uptime" --timeout 5
            """)
            exit(0)
        }

        // Parse timeout
        var timeout: TimeInterval = 30
        if let idx = args.firstIndex(of: "--timeout"), idx + 1 < args.count {
            timeout = TimeInterval(args[idx + 1]) ?? 30
        }

        // Script mode
        if args.contains("--script") {
            if let idx = args.firstIndex(of: "--script"), idx + 1 < args.count {
                let scriptPath = args[idx + 1]
                let result = headless.runScript(path: scriptPath, timeout: timeout)
                print(result.output, terminator: "")
                exit(result.exitCode)
            }
        }

        // Command mode — find the command after --headless or -e
        var command: String?
        if let idx = args.firstIndex(of: "--headless"), idx + 1 < args.count {
            command = args[idx + 1]
        } else if let idx = args.firstIndex(of: "-e"), idx + 1 < args.count {
            command = args[idx + 1]
        }

        if let cmd = command {
            let result = headless.run(command: cmd, timeout: timeout)
            print(result.output, terminator: "")
            exit(result.exitCode)
        }

        print("Error: No command specified. Use --help for usage.")
        exit(1)
    }
}
