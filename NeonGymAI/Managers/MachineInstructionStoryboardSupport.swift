import Foundation

struct MachineScanImageDimensions: Equatable {
    let width: Int
    let height: Int
}

enum MachineScanImageSizing {
    static func targetDimensions(
        width: Int,
        height: Int,
        maxLongEdge: Int = 1280
    ) -> MachineScanImageDimensions {
        guard width > 0, height > 0, maxLongEdge > 0 else {
            return MachineScanImageDimensions(width: 0, height: 0)
        }

        let scale = min(1, Double(maxLongEdge) / Double(max(width, height)))
        return MachineScanImageDimensions(
            width: Int((Double(width) * scale).rounded()),
            height: Int((Double(height) * scale).rounded())
        )
    }
}

enum GeminiMachineScanAPIRequest {
    static func makePayload(
        model: String,
        prompt: String,
        imageData: Data,
        schema: [String: Any]
    ) throws -> Data {
        let body: [String: Any] = [
            "model": model,
            "store": false,
            "input": [
                ["type": "text", "text": prompt],
                [
                    "type": "image",
                    "data": imageData.base64EncodedString(),
                    "mime_type": "image/jpeg"
                ]
            ],
            "generation_config": [
                "thinking_level": "low"
            ],
            "response_format": [
                "type": "text",
                "mime_type": "application/json",
                "schema": schema
            ]
        ]

        return try JSONSerialization.data(withJSONObject: body)
    }
}

enum MachineScanFallbackPolicy {
    static func nextModelIndex(afterFailureAt modelIndex: Int, modelCount: Int) -> Int? {
        let nextIndex = modelIndex + 1
        return nextIndex < modelCount ? nextIndex : nil
    }
}

enum StoryboardImageFallbackPolicy {
    static func nextModelIndex(afterFailureAt modelIndex: Int, modelCount: Int) -> Int? {
        let nextIndex = modelIndex + 1
        return nextIndex < modelCount ? nextIndex : nil
    }
}

enum MachineInstructionSteps {
    enum NormalizationError: Error {
        case requiresTwoSteps
    }

    static func normalized(_ instructions: [String]) throws -> [String] {
        let cleaned = instructions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard cleaned.count >= 2 else {
            throw NormalizationError.requiresTwoSteps
        }

        return Array(cleaned.prefix(2))
    }
}

struct MachineInstructionStoryboardRequest {
    let machineName: String
    let steps: [String]
    let targetMuscles: [String]

    init(machineName: String, instructions: [String], targetMuscles: [String]) {
        self.machineName = machineName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.steps = Array(
            instructions
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .prefix(2)
        )
        self.targetMuscles = targetMuscles
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var prompt: String {
        let panels = steps.enumerated()
            .map { "Panel \($0.offset + 1): \($0.element)" }
            .joined(separator: "\n")

        return """
        Create one clean 16:9 fitness instruction storyboard containing exactly two equal panels.

        MACHINE: \(machineName)
        \(panels)
        TARGET MUSCLES: \(targetMuscles.joined(separator: ", "))

        VISUAL REQUIREMENTS:
        - Show the same adult athlete and the same \(machineName) in both panels.
        - Show the full machine, the athlete's full body, and clearly readable joint positions.
        - Use a consistent side or three-quarter camera angle that clearly shows the start and finish positions.
        - The left panel must show the starting position described in Panel 1. The right panel must show the finishing position described in Panel 2.
        - Separate the two panels with a clear vertical divider.
        - Use a monochrome, high-contrast fitness-manual illustration style on a simple neutral background.
        - Highlight the target muscles in red. Keep every other muscle neutral gray.
        - Make the movement progression anatomically plausible and mechanically safe.
        - Do not include text, letters, numbers, captions, logos, watermarks, arrows, or extra panels.
        """
    }
}

struct GeneratedStoryboardImage {
    let data: Data
    let mimeType: String
}

enum StoryboardImageData {
    static func isSupportedImage(_ data: Data) -> Bool {
        let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        if data.starts(with: pngSignature) {
            return true
        }

        let jpegSignature: [UInt8] = [0xFF, 0xD8, 0xFF]
        if data.starts(with: jpegSignature) {
            return true
        }

        guard data.count >= 12 else { return false }
        let riff = Data("RIFF".utf8)
        let webp = Data("WEBP".utf8)
        return data.prefix(4) == riff && data.dropFirst(8).prefix(4) == webp
    }
}

enum GeminiStoryboardAPIRequest {
    enum RequestError: Error {
        case requiresTwoSteps
    }

    static func makePayload(
        model: String,
        request: MachineInstructionStoryboardRequest
    ) throws -> Data {
        guard request.steps.count == 2 else {
            throw RequestError.requiresTwoSteps
        }

        let body: [String: Any] = [
            "model": model,
            "store": false,
            "input": [
                ["type": "text", "text": request.prompt]
            ],
            "response_format": [
                "type": "image",
                "aspect_ratio": "16:9",
                "image_size": imageSize(for: model)
            ]
        ]

        return try JSONSerialization.data(withJSONObject: body)
    }

    private static func imageSize(for model: String) -> String {
        model == "gemini-3.1-flash-lite-image" ? "1K" : "512"
    }
}

enum GeminiStoryboardResponseParser {
    enum ParseError: Error {
        case malformedResponse
        case imageMissing
        case invalidImageData
    }

    static func parse(_ data: Data) throws -> GeneratedStoryboardImage {
        let response: Response
        do {
            response = try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw ParseError.malformedResponse
        }

        guard let imageContent = response.steps
            .first(where: { $0.type == "model_output" })?
            .content?
            .first(where: { $0.type == "image" }) else {
            throw ParseError.imageMissing
        }

        guard let encodedData = imageContent.data,
              let imageData = Data(base64Encoded: encodedData),
              StoryboardImageData.isSupportedImage(imageData) else {
            throw ParseError.invalidImageData
        }

        return GeneratedStoryboardImage(
            data: imageData,
            mimeType: imageContent.mimeType ?? "image/png"
        )
    }

    private struct Response: Decodable {
        let steps: [Step]
    }

    private struct Step: Decodable {
        let type: String
        let content: [Content]?
    }

    private struct Content: Decodable {
        let type: String
        let data: String?
        let mimeType: String?

        enum CodingKeys: String, CodingKey {
            case type
            case data
            case mimeType = "mime_type"
        }
    }
}

struct MachineInstructionStoryboardCache {
    private let rootDirectory: URL
    private let fileManager: FileManager

    init(rootDirectory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager

        if let rootDirectory {
            self.rootDirectory = rootDirectory
        } else {
            let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            self.rootDirectory = cachesDirectory
                .appendingPathComponent("MachineInstructionStoryboards", isDirectory: true)
        }
    }

    func load(for machineName: String) -> Data? {
        for fileExtension in ["png", "jpg", "webp", "image"] {
            let url = fileURL(for: machineName, fileExtension: fileExtension)
            if let data = try? Data(contentsOf: url),
               StoryboardImageData.isSupportedImage(data) {
                return data
            }
        }
        return nil
    }

    func store(_ data: Data, mimeType: String, for machineName: String) throws {
        try fileManager.createDirectory(
            at: rootDirectory,
            withIntermediateDirectories: true
        )

        try data.write(
            to: fileURL(for: machineName, fileExtension: fileExtension(for: mimeType)),
            options: .atomic
        )
    }

    func remove(for machineName: String) throws {
        for fileExtension in ["png", "jpg", "webp", "image"] {
            let url = fileURL(for: machineName, fileExtension: fileExtension)
            guard fileManager.fileExists(atPath: url.path) else { continue }
            try fileManager.removeItem(at: url)
        }
    }

    static func identifier(
        machineName: String,
        instructions: [String],
        targetMuscles: [String]
    ) -> String {
        ([machineName] + instructions + targetMuscles)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " | ")
    }

    private func fileURL(for machineName: String, fileExtension: String) -> URL {
        rootDirectory
            .appendingPathComponent(cacheKey(for: machineName))
            .appendingPathExtension(fileExtension)
    }

    private func cacheKey(for machineName: String) -> String {
        let components = machineName
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        let machineKey = components.isEmpty ? "unknown-machine" : components.joined(separator: "-")
        return "two-panel-\(machineKey)"
    }

    private func fileExtension(for mimeType: String) -> String {
        switch mimeType.lowercased() {
        case "image/jpeg", "image/jpg":
            return "jpg"
        case "image/webp":
            return "webp"
        case "image/png":
            return "png"
        default:
            return "image"
        }
    }
}
