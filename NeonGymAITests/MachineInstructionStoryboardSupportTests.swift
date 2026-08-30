import Foundation

@main
enum MachineInstructionStoryboardSupportTests {
    static func main() throws {
        try testRequestKeepsTwoCleanStepsAndMuscles()
        try testInstructionNormalizerKeepsExactlyTwoSteps()
        try testInstructionNormalizerRejectsTooFewSteps()
        try testMachineScanImageSizingLimitsLandscapeLongEdge()
        try testMachineScanImageSizingLimitsPortraitLongEdge()
        try testMachineScanImageSizingDoesNotUpscaleSmallFrames()
        try testMachineScanPayloadUsesLowThinking()
        try testMachineScanFallbackAdvancesWithoutRepeatingModel()
        try testMachineScanFallbackStopsAfterLastModel()
        try testAPIRequestUsesImageResponseFormat()
        try testLiteImageStoryboardUses1KOutput()
        try testStoryboardFallbackAdvancesToLiteImageModel()
        try testStoryboardFallbackStopsAfterLiteImageModel()
        try testAPIRequestRequiresTwoSteps()
        try testParserExtractsImageContent()
        try testParserRejectsInvalidImageBytes()
        try testParserRejectsResponseWithoutImage()
        try testStoryboardCacheIdentifierIncludesMotionAndMuscles()
        try testCacheStoresAndLoadsByMachineName()
        try testCacheRemovalForcesStoryboardRefresh()
        try testCacheIgnoresInvalidImageBytes()
        print("MachineInstructionStoryboardSupportTests: 21 passed")
    }

    private static func testMachineScanImageSizingLimitsLandscapeLongEdge() throws {
        let dimensions = MachineScanImageSizing.targetDimensions(width: 4032, height: 3024)

        try expect(
            dimensions == MachineScanImageDimensions(width: 1280, height: 960),
            "Landscape camera frames should be reduced to a 1280-pixel long edge"
        )
    }

    private static func testMachineScanImageSizingLimitsPortraitLongEdge() throws {
        let dimensions = MachineScanImageSizing.targetDimensions(width: 3024, height: 4032)

        try expect(
            dimensions == MachineScanImageDimensions(width: 960, height: 1280),
            "Portrait camera frames should be reduced to a 1280-pixel long edge"
        )
    }

    private static func testMachineScanImageSizingDoesNotUpscaleSmallFrames() throws {
        let dimensions = MachineScanImageSizing.targetDimensions(width: 800, height: 600)

        try expect(
            dimensions == MachineScanImageDimensions(width: 800, height: 600),
            "Small camera frames should not be enlarged before upload"
        )
    }

    private static func testMachineScanPayloadUsesLowThinking() throws {
        let payload = try GeminiMachineScanAPIRequest.makePayload(
            model: "gemini-3.7-flash",
            prompt: "Identify this machine",
            imageData: Data([0x01, 0x02]),
            schema: ["type": "object"]
        )
        let json = try JSONSerialization.jsonObject(with: payload) as? [String: Any]
        let generationConfig = json?["generation_config"] as? [String: Any]
        let input = json?["input"] as? [[String: Any]]

        try expect(
            generationConfig?["thinking_level"] as? String == "low",
            "Machine recognition should request low thinking for a faster response"
        )
        try expect(
            input?.last?["data"] as? String == Data([0x01, 0x02]).base64EncodedString(),
            "Machine recognition should include the captured JPEG"
        )
    }

    private static func testMachineScanFallbackAdvancesWithoutRepeatingModel() throws {
        let nextModelIndex = MachineScanFallbackPolicy.nextModelIndex(
            afterFailureAt: 0,
            modelCount: 2
        )

        try expect(
            nextModelIndex == 1,
            "A transient primary-model failure should immediately use the fallback model"
        )
    }

    private static func testMachineScanFallbackStopsAfterLastModel() throws {
        let nextModelIndex = MachineScanFallbackPolicy.nextModelIndex(
            afterFailureAt: 1,
            modelCount: 2
        )

        try expect(
            nextModelIndex == nil,
            "A fallback-model failure should stop instead of starting another slow retry"
        )
    }

    private static func testAPIRequestUsesImageResponseFormat() throws {
        let request = MachineInstructionStoryboardRequest(
            machineName: "Rowing Machine",
            instructions: ["Drive through your legs", "Finish by pulling to your lower ribs"],
            targetMuscles: ["Quadriceps", "Lats"]
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
        try expect(responseFormat?["image_size"] as? String == "512", "Storyboard should request the faster 512-pixel output")
    }

    private static func testLiteImageStoryboardUses1KOutput() throws {
        let request = MachineInstructionStoryboardRequest(
            machineName: "Rowing Machine",
            instructions: ["Drive through your legs", "Finish by pulling to your lower ribs"],
            targetMuscles: ["Quadriceps", "Lats"]
        )
        let payload = try GeminiStoryboardAPIRequest.makePayload(
            model: "gemini-3.1-flash-lite-image",
            request: request
        )
        let json = try JSONSerialization.jsonObject(with: payload) as? [String: Any]
        let responseFormat = json?["response_format"] as? [String: Any]

        try expect(
            responseFormat?["image_size"] as? String == "1K",
            "Flash Lite Image requests must use its supported 1K output size"
        )
    }

    private static func testStoryboardFallbackAdvancesToLiteImageModel() throws {
        let nextModelIndex = StoryboardImageFallbackPolicy.nextModelIndex(
            afterFailureAt: 0,
            modelCount: 2
        )

        try expect(
            nextModelIndex == 1,
            "A transient primary image-model failure should advance to Flash Lite Image"
        )
    }

    private static func testStoryboardFallbackStopsAfterLiteImageModel() throws {
        let nextModelIndex = StoryboardImageFallbackPolicy.nextModelIndex(
            afterFailureAt: 1,
            modelCount: 2
        )

        try expect(
            nextModelIndex == nil,
            "A Flash Lite Image failure should finish instead of looping through image models"
        )
    }

    private static func testAPIRequestRequiresTwoSteps() throws {
        let request = MachineInstructionStoryboardRequest(
            machineName: "Leg Press",
            instructions: ["Press through the feet"],
            targetMuscles: ["Quadriceps"]
        )

        do {
            _ = try GeminiStoryboardAPIRequest.makePayload(
                model: "gemini-3.1-flash-image",
                request: request
            )
            throw TestFailure(message: "A storyboard request with fewer than two movement phases should fail")
        } catch GeminiStoryboardAPIRequest.RequestError.requiresTwoSteps {
            // Expected.
        }
    }

    private static func testRequestKeepsTwoCleanStepsAndMuscles() throws {
        let request = MachineInstructionStoryboardRequest(
            machineName: "  Seated Row  ",
            instructions: ["Pull to your ribs", "  ", "Return slowly", "Extra step"],
            targetMuscles: ["Lats", "Rhomboids"]
        )

        try expect(request.machineName == "Seated Row", "Machine name should be trimmed")
        try expect(
            request.steps == ["Pull to your ribs", "Return slowly"],
            "Storyboard should use exactly the first two non-empty movement phases"
        )
        try expect(request.prompt.contains("exactly two equal panels"), "Prompt should request two visual panels")
        try expect(request.prompt.contains("Panel 1: Pull to your ribs"), "Prompt should describe the first motion")
        try expect(request.prompt.contains("Panel 2: Return slowly"), "Prompt should describe the second motion")
        try expect(request.prompt.contains("Lats, Rhomboids"), "Prompt should name the target muscles for highlighting")
        try expect(request.prompt.lowercased().contains("highlight the target muscles in red"), "Prompt should request red muscle highlights")
        try expect(request.prompt.contains("left panel must show the starting position"), "Prompt should bind the left panel to the start position")
        try expect(request.prompt.contains("right panel must show the finishing position"), "Prompt should bind the right panel to the finish position")
        try expect(request.prompt.contains("clear vertical divider"), "Prompt should require a divider between the two positions")
        try expect(!request.prompt.contains("Extra step"), "Prompt should not include a third panel")
    }

    private static func testInstructionNormalizerKeepsExactlyTwoSteps() throws {
        let steps = try MachineInstructionSteps.normalized([
            "Pull with control",
            "Return slowly",
            "Unneeded third step"
        ])

        try expect(
            steps == ["Pull with control", "Return slowly"],
            "Machine results and storyboard captions should share exactly two clean movement phases"
        )
    }

    private static func testInstructionNormalizerRejectsTooFewSteps() throws {
        do {
            _ = try MachineInstructionSteps.normalized(["Press safely"])
            throw TestFailure(message: "Fewer than two movement phases should be rejected")
        } catch MachineInstructionSteps.NormalizationError.requiresTwoSteps {
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

    private static func testStoryboardCacheIdentifierIncludesMotionAndMuscles() throws {
        let chestFly = MachineInstructionStoryboardCache.identifier(
            machineName: "Pec Fly Machine",
            instructions: ["Start with arms open", "Bring handles together"],
            targetMuscles: ["Chest"]
        )
        let rearDeltFly = MachineInstructionStoryboardCache.identifier(
            machineName: "Pec Fly Machine",
            instructions: ["Start with arms open", "Bring handles together"],
            targetMuscles: ["Rear Deltoids"]
        )
        let slowTempoChestFly = MachineInstructionStoryboardCache.identifier(
            machineName: "Pec Fly Machine",
            instructions: ["Open with a three-second return", "Squeeze handles together"],
            targetMuscles: ["Chest"]
        )

        try expect(
            chestFly != rearDeltFly,
            "Guides with different target muscles must not share the same cached image"
        )
        try expect(
            chestFly != slowTempoChestFly,
            "Guides with different movement phases must not share the same cached image"
        )
    }

    private static func testCacheRemovalForcesStoryboardRefresh() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let cache = MachineInstructionStoryboardCache(rootDirectory: root)
        try cache.store(pngHeaderData, mimeType: "image/png", for: "Rowing Machine")
        try cache.remove(for: "Rowing Machine")

        try expect(cache.load(for: "Rowing Machine") == nil, "Removing a cached guide should allow a fresh generation")
    }

    private static func testCacheIgnoresInvalidImageBytes() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("corrupt".utf8).write(to: root.appendingPathComponent("two-panel-rowing-machine.png"))

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
