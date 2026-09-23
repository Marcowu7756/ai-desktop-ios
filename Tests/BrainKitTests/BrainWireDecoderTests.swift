// UNVERIFIED: not executed. No Swift toolchain in this environment.

import XCTest
import ProductCore
import BrainKit

final class BrainWireDecoderTests: XCTestCase {
    func testUnknownActionKindIsRejectedRatherThanDropped() {
        let wire = BrainWireTurn(
            speech: "done",
            action: BrainWireAction(kind: "launch_missile", summary: "no")
        )

        XCTAssertThrowsError(try BrainWireDecoder.decode(wire)) { error in
            XCTAssertEqual(error as? BrainWireDecodingError, .unknownActionKind("launch_missile"))
        }
    }

    func testEmptySpeechIsRejected() {
        let wire = BrainWireTurn(speech: "   ")

        XCTAssertThrowsError(try BrainWireDecoder.decode(wire)) { error in
            XCTAssertEqual(error as? BrainWireDecodingError, .emptySpeech)
        }
    }

    func testUnknownMemoryCategoryIsDroppedNotInvented() throws {
        let wire = BrainWireTurn(
            speech: "ok",
            remember: [
                BrainWireMemory(category: "name", value: "Ming"),
                BrainWireMemory(category: "favourite_colour_of_the_void", value: "octarine")
            ]
        )

        let response = try BrainWireDecoder.decode(wire)

        XCTAssertEqual(response.memoryEvents.count, 1)
        XCTAssertEqual(response.memoryEvents.first?.category, .name)
    }

    func testJSONFormDecodes() throws {
        let json = """
        {"mood":"curious","gaze":"up","gesture":"tilt","speech":"why?"}
        """

        let response = try BrainWireDecoder.decode(json: json)

        XCTAssertEqual(response.characterStateCandidate.mood, "curious")
        XCTAssertEqual(response.presentation, "why?")
    }

    func testBrokenJSONIsReportedAsMalformed() {
        XCTAssertThrowsError(try BrainWireDecoder.decode(json: "not json"))
    }
}
