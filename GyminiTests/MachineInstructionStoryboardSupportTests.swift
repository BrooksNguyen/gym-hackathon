import Foundation

@main
enum MachineInstructionStoryboardSupportTests {
    static func main() throws {
        try testRequestKeepsThreeCleanSteps()
        try testInstructionNormalizerKeepsExactlyThreeSteps()
        try testInstructionNormalizerRejectsTooFewSteps()
        try testAPIRequestUsesImageResponseFormat()
        try testAPIRequestRequiresThreeSteps()
        try testParserExtractsImageContent()
        try testParserRejectsInvalidImageBytes()
        try testParserRejectsResponseWithoutImage()
        try testCacheStoresAndLoadsByMachineName()
        try testCacheIgnoresInvalidImageBytes()
        print("MachineInstructionStoryboardSupportTests: 10 passed")
    }

    private static func testAPIRequestUsesImageResponseFormat() throws {
        let request = MachineInstructionStoryboardRequest(
            machineName: "Rowing Machine",
            instructions: ["Sit tall", "Drive with the legs", "Return with control"]
        )
        let payload = try GeminiStoryboardAPIRequest.makePayload(
            model: "gemini-3.1-flash-image",
            request: request
        )
        let json = try JSONSerialization.jsonObject(with: payload) as? [String: Any]
        let responseFormat = json?["response_format"] as? [String: Any]

        try expect(json?["model"] as? String == "gemini-3.1-flash-image", "Payload should use the selected image model")
        try expect(json?["store"] as? Bool == false, "Storyboard request should opt out of interaction storage")
        try expect(responseFormat?["type"] as? String == "image", "Payload should request an image response")
        try expect(responseFormat?["aspect_ratio"] as? String == "16:9", "Storyboard should be generated in 16:9")
        try expect(responseFormat?["image_size"] as? String == "1K", "Storyboard should control image size")
    }

    private static func testAPIRequestRequiresThreeSteps() throws {
        let request = MachineInstructionStoryboardRequest(
            machineName: "Leg Press",
            instructions: ["Set the seat", "Press through the feet"]
        )

        do {
            _ = try GeminiStoryboardAPIRequest.makePayload(
                model: "gemini-3.1-flash-image",
                request: request
            )
            throw TestFailure(message: "A storyboard request with fewer than three steps should fail")
        } catch GeminiStoryboardAPIRequest.RequestError.requiresThreeSteps {
            // Expected.
        }
    }

    private static func testRequestKeepsThreeCleanSteps() throws {
        let request = MachineInstructionStoryboardRequest(
            machineName: "  Seated Row  ",
            instructions: ["Adjust the seat", "  ", "Pull to your ribs", "Return slowly", "Extra step"]
        )

        try expect(request.machineName == "Seated Row", "Machine name should be trimmed")
        try expect(
            request.steps == ["Adjust the seat", "Pull to your ribs", "Return slowly"],
            "Storyboard should use exactly the first three non-empty instructions"
        )
        try expect(request.prompt.contains("Panel 1: Adjust the seat"), "Prompt should describe panel one")
        try expect(request.prompt.contains("Panel 3: Return slowly"), "Prompt should describe panel three")
        try expect(!request.prompt.contains("Extra step"), "Prompt should not include a fourth panel")
    }

    private static func testInstructionNormalizerKeepsExactlyThreeSteps() throws {
        let steps = try MachineInstructionSteps.normalized([
            " Adjust the seat ",
            "Pull with control",
            "Return slowly",
            "Unneeded fourth step"
        ])

        try expect(
            steps == ["Adjust the seat", "Pull with control", "Return slowly"],
            "Machine results and storyboard captions should share exactly three clean steps"
        )
    }

    private static func testInstructionNormalizerRejectsTooFewSteps() throws {
        do {
            _ = try MachineInstructionSteps.normalized(["Set the seat", "Press safely"])
            throw TestFailure(message: "Fewer than three instructions should be rejected")
        } catch MachineInstructionSteps.NormalizationError.requiresThreeSteps {
            // Expected.
        }
    }

    private static func testParserExtractsImageContent() throws {
        let expected = pngHeaderData
        let payload = """
        {
          "steps": [
            {
              "type": "model_output",
              "content": [
                {"type": "text", "text": "Generated"},
                {"type": "image", "data": "\(expected.base64EncodedString())", "mime_type": "image/png"}
              ]
            }
          ]
        }
        """.data(using: .utf8)!

        let image = try GeminiStoryboardResponseParser.parse(payload)
        try expect(image.data == expected, "Parser should decode Gemini's base64 image")
        try expect(image.mimeType == "image/png", "Parser should preserve the MIME type")
    }

    private static func testParserRejectsInvalidImageBytes() throws {
        let invalid = Data("not-an-image".utf8)
        let payload = """
        {"steps":[{"type":"model_output","content":[{"type":"image","data":"\(invalid.base64EncodedString())","mime_type":"image/png"}]}]}
        """.data(using: .utf8)!

        do {
            _ = try GeminiStoryboardResponseParser.parse(payload)
            throw TestFailure(message: "Invalid image bytes should be rejected before caching")
        } catch GeminiStoryboardResponseParser.ParseError.invalidImageData {
            // Expected.
        }
    }

    private static func testParserRejectsResponseWithoutImage() throws {
        let payload = """
        {"steps":[{"type":"model_output","content":[{"type":"text","text":"No image"}]}]}
        """.data(using: .utf8)!

        do {
            _ = try GeminiStoryboardResponseParser.parse(payload)
            throw TestFailure(message: "Parser should reject a response without image content")
        } catch GeminiStoryboardResponseParser.ParseError.imageMissing {
            // Expected.
        }
    }

    private static func testCacheStoresAndLoadsByMachineName() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let cache = MachineInstructionStoryboardCache(rootDirectory: root)
        let expected = pngHeaderData
        try cache.store(expected, mimeType: "image/jpeg", for: "Lat Pulldown")

        try expect(cache.load(for: "Lat Pulldown") == expected, "Cache should load a stored storyboard")
        try expect(cache.load(for: "Leg Press") == nil, "Cache should not mix machine names")
    }

    private static func testCacheIgnoresInvalidImageBytes() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("corrupt".utf8).write(to: root.appendingPathComponent("rowing-machine.png"))

        let cache = MachineInstructionStoryboardCache(rootDirectory: root)
        try expect(cache.load(for: "Rowing Machine") == nil, "Cache should ignore corrupt image data")
    }

    private static var pngHeaderData: Data {
        Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00])
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw TestFailure(message: message) }
    }

    private struct TestFailure: Error, CustomStringConvertible {
        let message: String
        var description: String { message }
    }
}
