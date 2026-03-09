/**
 * @file ShellSpec grammar for tree-sitter (extends bash)
 * @author Ismo Vuorinen <ismo@ivuorinen.net>
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

const bashGrammar = require("tree-sitter-bash/grammar");

module.exports = grammar(bashGrammar, {
  name: "shellspec",

  // Precedence Strategy:
  // ShellSpec extends bash grammar by adding BDD test constructs. The key design
  // principle is to make ShellSpec blocks take precedence over bash commands when
  // followed by their specific syntax (descriptions, End keywords).
  //
  // Precedence levels:
  // - Level 1: bash_statement (base level, all bash constructs)
  // - Level 2: ShellSpec statements (higher precedence than bash)
  // - Level 5: Data block with #| lines (highest specificity)
  //
  // This allows "Describe", "It", etc. to work as both:
  // 1. ShellSpec block keywords (when followed by description + End)
  // 2. Regular bash commands/functions (in any other context)

  conflicts: ($, previous) =>
    previous.concat([
      // Essential bash conflicts only
      [$._expression, $.command_name],
      [$.command, $.variable_assignments],
      [$.function_definition, $.command_name],
      // Required ShellSpec conflicts
      [$.command_name, $.shellspec_data_block],
      [$.command_name, $.shellspec_hook_statement],
      [$.shellspec_hook_block],
    ]),

  rules: {
    // Extend the main statement rule to include ShellSpec blocks and directives
    _statement_not_subshell: ($, original) =>
      choice(
        // @ts-ignore
        original,
        $.shellspec_describe_block,
        $.shellspec_context_block,
        $.shellspec_it_block,
        $.shellspec_hook_block,
        $.shellspec_utility_block,
        $.shellspec_data_block,
        $.shellspec_hook_statement,
        $.shellspec_directive_statement,
        // Phase 1: When/The/Assert statements
        $.shellspec_when_statement,
        $.shellspec_the_statement,
        $.shellspec_assert_statement,
        // Phase 2: Mock block, Path/Set/Dump/Intercept statements
        $.shellspec_mock_block,
        $.shellspec_path_statement,
        $.shellspec_set_statement,
        $.shellspec_dump_statement,
        $.shellspec_intercept_statement,
        // Phase 3: Todo standalone statement
        $.shellspec_todo_statement,
        // Phase 4: Pending/Skip standalone statements
        $.shellspec_pending_statement,
        $.shellspec_skip_statement,
        // Phase 4: Percent directives
        $.shellspec_text_directive,
        $.shellspec_const_directive,
        $.shellspec_output_directive,
        $.shellspec_preserve_directive,
        $.shellspec_logger_directive,
      ),

    // ShellSpec Describe blocks
    shellspec_describe_block: ($) =>
      prec.right(
        1,
        seq(
          choice("Describe", "fDescribe", "xDescribe"),
          field("description", choice($.string, $.raw_string, $.word)),
          repeat($._terminated_statement),
          "End",
        ),
      ),

    // ShellSpec Context/ExampleGroup blocks
    shellspec_context_block: ($) =>
      prec.right(
        1,
        seq(
          choice(
            "Context",
            "ExampleGroup",
            "fContext",
            "xContext",
            "fExampleGroup",
            "xExampleGroup",
          ),
          field("description", choice($.string, $.raw_string, $.word)),
          repeat($._terminated_statement),
          "End",
        ),
      ),

    // ShellSpec It/Example/Specify blocks
    shellspec_it_block: ($) =>
      prec.right(
        1,
        seq(
          choice(
            "It",
            "Example",
            "Specify",
            "fIt",
            "fExample",
            "fSpecify",
            "xIt",
            "xExample",
            "xSpecify",
          ),
          field("description", choice($.string, $.raw_string, $.word)),
          repeat($._terminated_statement),
          "End",
        ),
      ),

    // ShellSpec hooks as blocks (with End)
    shellspec_hook_block: ($) =>
      prec.right(
        1,
        seq(
          choice(
            "BeforeEach",
            "AfterEach",
            "BeforeAll",
            "AfterAll",
            "BeforeCall",
            "AfterCall",
            "BeforeRun",
            "AfterRun",
          ),
          optional(field("label", choice($.string, $.raw_string, $.word))),
          repeat($._terminated_statement),
          "End",
        ),
      ),

    // ShellSpec utility blocks (Parameters, Skip, Pending - Data has its own rule)
    shellspec_utility_block: ($) =>
      prec.right(
        1,
        seq(
          choice(
            "Parameters",
            "Parameters:block",
            "Parameters:value",
            "Parameters:matrix",
            "Parameters:dynamic",
          ),
          optional(field("label", choice($.string, $.raw_string, $.word))),
          repeat($._terminated_statement),
          "End",
        ),
      ),

    // ShellSpec Data blocks - optimized for performance while maintaining functionality
    shellspec_data_block: ($) =>
      choice(
        // Block style with pipe filter + #| lines (highest precedence)
        prec.right(
          6,
          seq(
            choice("Data", "Data:raw", "Data:expand"),
            "|",
            repeat1(field("filter", choice($.string, $.raw_string, $.word))),
            repeat1(seq("#|", field("data_line", $.shellspec_data_line_content))),
            "End",
          ),
        ),
        // Block style with #| lines (supports both "Data :raw" and "Data:raw" forms)
        prec.right(
          5,
          seq(
            choice(
              seq("Data", optional(seq(":", field("modifier", choice("raw", "expand"))))),
              "Data:raw",
              "Data:expand",
            ),
            repeat1(seq("#|", field("data_line", $.shellspec_data_line_content))),
            "End",
          ),
        ),
        // Block style with regular statements
        prec.right(
          4,
          seq(
            "Data",
            optional(seq(":", field("modifier", choice("raw", "expand")))),
            optional(field("label", choice($.string, $.raw_string, $.word))),
            field("statements", repeat($._terminated_statement)),
            "End",
          ),
        ),
        // Argument(s) with pipe filter (no End, single line)
        prec.right(
          3,
          seq(
            "Data",
            field("argument", choice($.string, $.raw_string, $.word)),
            repeat(field("extra_argument", choice($.string, $.raw_string, $.word))),
            "|",
            repeat1(field("filter", choice($.string, $.raw_string, $.word))),
          ),
        ),
        // String argument style (no End) - lowest precedence
        seq(
          "Data",
          optional(seq(":", field("modifier", choice("raw", "expand")))),
          field("argument", choice($.string, $.raw_string, $.word)),
        ),
      ),

    // Phase 1: When statement — core ShellSpec assertion DSL
    shellspec_when_statement: ($) =>
      prec.right(
        2,
        seq(
          "When",
          field(
            "type",
            choice("call", seq("run", optional(choice("command", "script", "source")))),
          ),
          field("function", choice($.string, $.raw_string, $.word)),
          repeat(field("argument", choice($.string, $.raw_string, $.word))),
        ),
      ),

    // Phase 1: The statement — core ShellSpec expectation DSL
    // Subject consumes words until "should", then matcher consumes the rest
    shellspec_subject: ($) => repeat1(choice($.string, $.raw_string, $.word)),

    shellspec_matcher: ($) => repeat1(choice($.string, $.raw_string, $.word)),

    shellspec_the_statement: ($) =>
      prec.right(
        2,
        seq(
          "The",
          field("subject", $.shellspec_subject),
          "should",
          optional(field("negation", "not")),
          field("matcher", $.shellspec_matcher),
        ),
      ),

    // Phase 1: Assert statement
    shellspec_assert_statement: ($) =>
      prec.right(
        2,
        seq("Assert", repeat1(field("argument", choice($.string, $.raw_string, $.word)))),
      ),

    // Phase 2: Mock block
    shellspec_mock_block: ($) =>
      prec.right(
        1,
        seq(
          "Mock",
          field("name", choice($.string, $.raw_string, $.word)),
          repeat($._terminated_statement),
          "End",
        ),
      ),

    // Phase 2: Path/File/Dir statement
    shellspec_path_statement: ($) =>
      prec.right(
        2,
        seq(
          choice("Path", "File", "Dir"),
          repeat1(field("argument", choice($.string, $.raw_string, $.word))),
        ),
      ),

    // Phase 2: Set statement
    shellspec_set_statement: ($) =>
      prec.right(2, seq("Set", repeat1(field("option", choice($.string, $.raw_string, $.word))))),

    // Phase 2: Dump statement (standalone, no arguments)
    shellspec_dump_statement: () => prec.right(2, "Dump"),

    // Phase 2: Intercept statement
    shellspec_intercept_statement: ($) =>
      prec.right(
        2,
        seq("Intercept", repeat1(field("argument", choice($.string, $.raw_string, $.word)))),
      ),

    // ShellSpec hooks as statements (standalone, without End)
    shellspec_hook_statement: ($) =>
      prec.right(
        2,
        seq(
          choice(
            "Before",
            "After",
            "BeforeEach",
            "AfterEach",
            "BeforeAll",
            "AfterAll",
            "BeforeCall",
            "AfterCall",
            "BeforeRun",
            "AfterRun",
          ),
          repeat1(field("argument", choice($.string, $.raw_string, $.word))),
        ),
      ),

    // ShellSpec directives (Include, Skip with conditions)
    shellspec_directive_statement: ($) =>
      prec.right(
        2,
        choice(
          // Include directive
          seq("Include", field("path", choice($.string, $.raw_string, $.word))),
          // Skip with conditions (only conditional skip, simple skip handled by utility_block)
          prec.right(
            3,
            seq(
              "Skip",
              "if",
              field("reason", choice($.string, $.raw_string, $.word)),
              field(
                "condition",
                repeat1(
                  choice($.word, $.string, $.raw_string, $.command_substitution, $.test_command),
                ),
              ),
            ),
          ),
        ),
      ),

    // Phase 3: Todo standalone statement (without End block)
    shellspec_todo_statement: ($) =>
      prec.right(2, seq("Todo", field("description", choice($.string, $.raw_string, $.word)))),

    // Phase 4: Pending standalone statement (without End block)
    shellspec_pending_statement: ($) =>
      prec.right(2, seq("Pending", field("reason", choice($.string, $.raw_string, $.word)))),

    // Phase 4: Skip standalone statement (without End block)
    shellspec_skip_statement: ($) =>
      prec.right(2, seq("Skip", field("reason", choice($.string, $.raw_string, $.word)))),

    // Phase 4: %text directive
    shellspec_text_directive: ($) =>
      prec.right(
        5,
        seq(
          choice("%text", "%text:raw", "%text:expand"),
          optional(seq("|", repeat1(field("filter", choice($.string, $.raw_string, $.word))))),
          repeat1(seq("#|", field("data_line", $.shellspec_data_line_content))),
        ),
      ),

    // Reusable data line content for #| lines
    shellspec_data_line_content: () => /[^\n]*/,

    // Phase 4: %const directive
    shellspec_const_directive: ($) =>
      prec.right(
        2,
        seq(
          choice("%const", "%"),
          field("name", $.word),
          field("value", choice($.string, $.raw_string, $.word)),
        ),
      ),

    // Phase 4: Output directives
    shellspec_output_directive: ($) =>
      prec.right(
        2,
        seq(
          choice("%puts", "%putsn", "%-", "%="),
          repeat1(field("argument", choice($.string, $.raw_string, $.word))),
        ),
      ),

    // Phase 4: %preserve directive
    shellspec_preserve_directive: ($) =>
      prec.right(
        2,
        seq("%preserve", repeat1(field("variable", choice($.string, $.raw_string, $.word)))),
      ),

    // Phase 4: %logger directive
    shellspec_logger_directive: ($) =>
      prec.right(
        2,
        seq("%logger", repeat1(field("argument", choice($.string, $.raw_string, $.word)))),
      ),
  },
});
