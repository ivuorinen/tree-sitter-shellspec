import XCTest
import SwiftTreeSitter
import TreeSitterShellspec

final class TreeSitterShellspecTests: XCTestCase {
    func testCanLoadGrammar() throws {
        let parser = Parser()
        let language = Language(language: tree_sitter_shellspec())
        XCTAssertNoThrow(try parser.setLanguage(language),
                         "Error loading Shellspec grammar")
    }
}
