import Foundation
import Testing
@testable import StrickeyCore

struct StrickeyCoreTests {
    @Test func testAllRecordedSamplesLoadWithoutClipping() throws {
        for profile in SwitchProfile.allCases {
            for key in KeyKind.allCases {
                for variant in 0..<SoundLibrary.variantCount {
                    let samples = try SoundLibrary.load(profile: profile, key: key, variant: variant)
                    #expect(samples.count > 4_000 && samples.count < 22_050)
                    #expect(samples.allSatisfy { $0.isFinite && abs($0) <= 0.901 })
                    #expect(samples.first == 0 && samples.last == 0)
                    let peak = samples.map { abs($0) }.max() ?? 0
                    #expect(peak > 0.7)
                    #expect(samples.contains { abs($0) > 0.05 })
                }
            }
        }
    }

    @Test func testRecordingsAndVariantsAreDistinct() throws {
        let red = try SoundLibrary.load(profile: .linear, key: .regular, variant: 0)
        let brown = try SoundLibrary.load(profile: .tactile, key: .regular, variant: 0)
        let blue = try SoundLibrary.load(profile: .clicky, key: .regular, variant: 0)
        #expect(red != brown && brown != blue && red != blue)
        let variant = try SoundLibrary.load(profile: .linear, key: .regular, variant: 1)
        let space = try SoundLibrary.load(profile: .linear, key: .space, variant: 0)
        #expect(red != variant)
        #expect(red != space)
    }

    @Test func testDamagedRecordingsFailExplicitly() throws {
        #expect(throws: SoundLibrary.LoadingError.self) { try SoundLibrary.decode(Data()) }
        #expect(throws: SoundLibrary.LoadingError.self) {
            try SoundLibrary.decode(Data("RIFF0000WAVE".utf8))
        }
        #expect(throws: SoundLibrary.LoadingError.self) {
            try SoundLibrary.load(profile: .linear, key: .regular, variant: 99)
        }
    }

    @Test func testAutoRepeatAndDuplicateDownDoNotProduceExtraSounds() {
        var tracker = KeyPressTracker()
        #expect(tracker.keyDown(0, isRepeat: false, isShortcut: false) == .regular)
        #expect(tracker.keyDown(0, isRepeat: true, isShortcut: false) == nil)
        #expect(tracker.keyDown(0, isRepeat: false, isShortcut: false) == nil)
        #expect(tracker.keyUp(0) == .regular)
        #expect(tracker.keyUp(0) == nil)
    }

    @Test func testShortcutsAndOrphanReleasesAreSilent() {
        var tracker = KeyPressTracker()
        #expect(tracker.keyUp(49) == nil)
        #expect(tracker.keyDown(49, isRepeat: false, isShortcut: true) == nil)
        #expect(tracker.keyUp(49) == nil)
        #expect(tracker.keyDown(49, isRepeat: true, isShortcut: false) == nil)
        #expect(tracker.keyUp(49) == nil)
    }

    @Test func testResetDiscardsKeysAcrossPauseOrSecureInput() {
        var tracker = KeyPressTracker()
        #expect(tracker.keyDown(49, isRepeat: false, isShortcut: false) == .space)
        #expect(tracker.keyDown(36, isRepeat: false, isShortcut: false) == .enter)
        tracker.reset()
        #expect(tracker.keyUp(49) == nil)
        #expect(tracker.keyUp(36) == nil)
        #expect(tracker.keyDown(49, isRepeat: false, isShortcut: false) == .space)
    }

    @Test func testPhysicalKeyCategories() {
        #expect(KeyKind(keyCode: 49) == .space)
        #expect(KeyKind(keyCode: 36) == .enter)
        #expect(KeyKind(keyCode: 76) == .enter)
        #expect(KeyKind(keyCode: 51) == .delete)
        #expect(KeyKind(keyCode: 117) == .delete)
        #expect(KeyKind(keyCode: 0) == .regular)
    }
}
