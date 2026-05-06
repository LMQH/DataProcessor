import AppKit
import SwiftUI
import UniformTypeIdentifiers

@main
struct DataProcessApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 680, minHeight: 420)
        }
    }
}

private enum ConversionMode: String, CaseIterable, Identifiable {
    case docxToMd = "docx-to-md"
    case mdToDocx = "md-to-docx"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .docxToMd:
            return "DOCX -> Markdown"
        case .mdToDocx:
            return "Markdown -> DOCX"
        }
    }

    var inputExtension: String {
        switch self {
        case .docxToMd:
            return "docx"
        case .mdToDocx:
            return "md"
        }
    }

    var outputExtension: String {
        switch self {
        case .docxToMd:
            return "md"
        case .mdToDocx:
            return "docx"
        }
    }
}

private enum DocxToMdEngine: String, CaseIterable, Identifiable {
    case mammoth = "mammoth"
    case pythonDocx = "python-docx"
    case pandoc = "pandoc"
    case libreofficeHtml = "libreoffice-html"
    case libreofficePdf = "libreoffice-pdf"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mammoth:
            return "Mammoth"
        case .pythonDocx:
            return "python-docx"
        case .pandoc:
            return "Pandoc"
        case .libreofficeHtml:
            return "LibreOffice→HTML"
        case .libreofficePdf:
            return "LibreOffice→PDF"
        }
    }
}

private enum RunState: Equatable {
    case idle
    case running
    case success(String)
    case failure(String)

    var message: String {
        switch self {
        case .idle:
            return "请选择输入文件和输出位置。"
        case .running:
            return "正在转换..."
        case .success(let path):
            return "转换完成: \(path)"
        case .failure(let message):
            return message
        }
    }
}

private struct ConvertResult: Decodable {
    let ok: Bool
    let output: String
}

private enum LibreOfficeBootstrap {
    @MainActor private static var didCheck = false

    @MainActor
    static func promptIfMissing() {
        guard !didCheck else { return }
        didCheck = true
        guard !isInstalled() else { return }

        let alert = NSAlert()
        alert.messageText = "未检测到 LibreOffice"
        alert.informativeText = "LibreOffice→HTML / LibreOffice→PDF 引擎需要本机安装 LibreOffice；批处理脚本同样依赖。其他引擎可不安装。"
        alert.addButton(withTitle: "打开下载页")
        alert.addButton(withTitle: "稍后")
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "https://www.libreoffice.org/download/download/") {
            NSWorkspace.shared.open(url)
        }
    }

    private static func isInstalled() -> Bool {
        let fm = FileManager.default
        let home = NSHomeDirectory()
        let paths = [
            "/Applications/LibreOffice.app/Contents/MacOS/soffice",
            "\(home)/Applications/LibreOffice.app/Contents/MacOS/soffice"
        ]
        return paths.contains { fm.isExecutableFile(atPath: $0) }
    }
}

struct ContentView: View {
    @State private var mode: ConversionMode = .docxToMd
    @State private var docxEngine: DocxToMdEngine = .mammoth
    @State private var inputURL: URL?
    @State private var outputURL: URL?
    @State private var runState: RunState = .idle

    private var canRun: Bool {
        inputURL != nil && outputURL != nil && runState != .running
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Data Process")
                .font(.title)

            Picker("转换方向", selection: $mode) {
                ForEach(ConversionMode.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: mode) { _ in
                inputURL = nil
                outputURL = nil
                runState = .idle
            }

            if mode == .docxToMd {
                Picker("转换方法", selection: $docxEngine) {
                    ForEach(DocxToMdEngine.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: docxEngine) { _ in
                    if runState != .running {
                        runState = .idle
                    }
                }
            }

            FileRow(
                title: "输入文件",
                path: inputURL?.path ?? "未选择",
                buttonTitle: "选择"
            ) {
                selectInput()
            }

            FileRow(
                title: "输出文件",
                path: outputURL?.path ?? "未选择",
                buttonTitle: "选择"
            ) {
                selectOutput()
            }

            HStack {
                Button("开始转换") {
                    runConversion()
                }
                .disabled(!canRun)

                if case .success(let path) = runState {
                    Button("打开文件") {
                        NSWorkspace.shared.open(URL(fileURLWithPath: path))
                    }

                    Button("在 Finder 中显示") {
                        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
                    }
                }
            }

            Text(runState.message)
                .font(.callout)
                .foregroundStyle(statusColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding(24)
        .task {
            LibreOfficeBootstrap.promptIfMissing()
        }
    }

    private var statusColor: Color {
        switch runState {
        case .failure:
            return .red
        case .success:
            return .green
        default:
            return .secondary
        }
    }

    private func selectInput() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: mode.inputExtension)].compactMap { $0 }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            inputURL = url
            outputURL = defaultOutputURL(for: url)
            runState = .idle
        }
    }

    private func selectOutput() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: mode.outputExtension)].compactMap { $0 }
        panel.nameFieldStringValue = outputURL?.lastPathComponent ?? defaultOutputName()

        if panel.runModal() == .OK, let url = panel.url {
            outputURL = url
            runState = .idle
        }
    }

    private func runConversion() {
        guard let inputURL, let outputURL else {
            return
        }

        runState = .running
        let currentMode = mode
        let currentEngine = docxEngine

        DispatchQueue.global(qos: .userInitiated).async {
            let result = BackendRunner.execute(
                mode: currentMode,
                docxEngine: currentEngine,
                inputURL: inputURL,
                outputURL: outputURL
            )
            DispatchQueue.main.async {
                runState = result
            }
        }
    }
}

private enum BackendRunner {
    static func execute(mode: ConversionMode, docxEngine: DocxToMdEngine, inputURL: URL, outputURL: URL) -> RunState {
        let command: BackendCommand
        do {
            command = try resolveCommand(mode: mode, docxEngine: docxEngine, inputURL: inputURL, outputURL: outputURL)
        } catch {
            return .failure(error.localizedDescription)
        }

        let process = Process()
        process.executableURL = command.executableURL
        process.arguments = command.arguments

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return .failure("启动后端失败: \(error.localizedDescription)")
        }

        let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
        let errorText = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard process.terminationStatus == 0 else {
            return .failure(errorText.isEmpty ? "转换失败，退出码: \(process.terminationStatus)" : errorText)
        }

        do {
            let result = try JSONDecoder().decode(ConvertResult.self, from: outputData)
            return result.ok ? .success(result.output) : .failure("转换失败")
        } catch {
            let raw = String(data: outputData, encoding: .utf8) ?? ""
            return .failure("解析后端结果失败: \(raw)")
        }
    }

    private static func resolveCommand(mode: ConversionMode, docxEngine: DocxToMdEngine, inputURL: URL, outputURL: URL) throws -> BackendCommand {
        if let resourceURL = Bundle.main.resourceURL {
            let bundledBackend = resourceURL.appendingPathComponent("python-backend/convert_cli")
            if FileManager.default.isExecutableFile(atPath: bundledBackend.path) {
                return BackendCommand(
                    executableURL: bundledBackend,
                    arguments: commonArguments(mode: mode, docxEngine: docxEngine, inputURL: inputURL, outputURL: outputURL)
                )
            }
        }

        let root = projectRoot()
        let python = root.appendingPathComponent(".conda/bin/python3.12")
        let cli = root.appendingPathComponent("backend/convert_cli.py")

        guard FileManager.default.isExecutableFile(atPath: python.path) else {
            throw BackendError.missingRuntime(python.path)
        }
        guard FileManager.default.isReadableFile(atPath: cli.path) else {
            throw BackendError.missingEntry(cli.path)
        }

        return BackendCommand(
            executableURL: python,
            arguments: [cli.path] + commonArguments(mode: mode, docxEngine: docxEngine, inputURL: inputURL, outputURL: outputURL)
        )
    }

    private static func commonArguments(mode: ConversionMode, docxEngine: DocxToMdEngine, inputURL: URL, outputURL: URL) -> [String] {
        var parts: [String] = ["--mode", mode.rawValue]
        if mode == .docxToMd {
            parts += ["--engine", docxEngine.rawValue]
        }
        parts += ["--input", inputURL.path, "--output", outputURL.path]
        return parts
    }

    private static func projectRoot() -> URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 {
            url.deleteLastPathComponent()
        }
        return url
    }
}

private struct BackendCommand {
    let executableURL: URL
    let arguments: [String]
}

private enum BackendError: LocalizedError {
    case missingRuntime(String)
    case missingEntry(String)

    var errorDescription: String? {
        switch self {
        case .missingRuntime(let path):
            return "未找到 Python 运行环境: \(path)"
        case .missingEntry(let path):
            return "未找到后端入口: \(path)"
        }
    }
}

private extension ContentView {
    func defaultOutputURL(for input: URL) -> URL {
        input
            .deletingPathExtension()
            .appendingPathExtension(mode.outputExtension)
    }

    func defaultOutputName() -> String {
        let base = inputURL?.deletingPathExtension().lastPathComponent ?? "output"
        return "\(base).\(mode.outputExtension)"
    }
}

private struct FileRow: View {
    let title: String
    let path: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .frame(width: 72, alignment: .leading)

            Text(path)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.secondary)

            Button(buttonTitle, action: action)
        }
    }
}
