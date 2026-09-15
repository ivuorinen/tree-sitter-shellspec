/**
 * @file ShellSpec grammar for tree-sitter (extends bash)
 * @author Ismo Vuorinen <ismo@ivuorinen.net>
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
/// <reference path="types/tree-sitter-bash-grammar.d.ts" />
// @ts-check

// ESM because the package is "type": "module" for the generated node binding.
// tree-sitter-bash is CommonJS without an exports map, so the import needs the .js extension.
import bashGrammar from "tree-sitter-bash/grammar.js";

/**
 * Argument slot shared by every ShellSpec statement, block description and filter.
 *
 * Covers the bash literals spec authors write unquoted — words, numbers, `$var`,
 * `${var}` and `$(cmd)` — alongside quoted strings, so those arguments parse instead
 * of producing ERROR nodes. `concatenation` is excluded on purpose: bash's
 * concatenation repeat creates unresolvable conflicts inside ShellSpec argument
 * lists, so `--opt=$x` parses as two adjacent arguments. `Include` takes a single
 * path and adds `concatenation` explicitly.
 *
 * @param {GrammarSymbols<string>} $ grammar symbols
 * @returns {ChoiceRule}
 */
function argument($) {
  return choice($.word, $.string, $.raw_string, $.number, $.simple_expansion, $.expansion, $.command_substitution);
}

export default grammar(bashGrammar, {
  name: "shellspec",

  // Precedence Strategy:
  // ShellSpec extends bash grammar by adding BDD test constructs. ShellSpec rules take
  // precedence over bash commands when followed by their specific syntax (descriptions,
  // arguments, End keywords), so "Describe", "It", etc. still work as regular bash
  // commands or function names in any other context.
  //
  // Precedence levels used below:
  // - 1: blocks ending in End (Describe/Context/It, Parameters, Mock)
  // - 2: single-line statements and % directives other than %text
  // - 3: conditional `Skip if`; Data with arguments and a pipe filter
  // - 4: `Data < FILE`
  // - 5: Data block with #| lines; %text directive
  // - 6: Data block with a pipe filter and #| lines

  // Conflicts inherited from tree-sitter-bash arrive through `previous`.
  conflicts: ($, previous) =>
    previous.concat([
      // Parameters blocks go straight from the keyword into the statement repeat
      // shared by every block, which needs an explicit conflict.
      [$.shellspec_utility_block],
    ]),

  rules: {
    // Extend the main statement rule to include ShellSpec blocks and directives
    _statement_not_subshell: ($, original) =>
      choice(
        // `original` is optional in RuleBuilder's type but always set when extending bash
        /** @type {RuleOrLiteral} */ (original),
        $.shellspec_describe_block,
        $.shellspec_context_block,
        $.shellspec_it_block,
        $.shellspec_utility_block,
        $.shellspec_parameters_value_statement,
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
      prec.right(1, seq(choice("Describe", "fDescribe", "xDescribe"), field("description", argument($)), repeat($._terminated_statement), "End")),

    // ShellSpec Context/ExampleGroup blocks
    shellspec_context_block: ($) =>
      prec.right(
        1,
        seq(
          choice("Context", "ExampleGroup", "fContext", "xContext", "fExampleGroup", "xExampleGroup"),
          field("description", argument($)),
          repeat($._terminated_statement),
          "End",
        ),
      ),

    // ShellSpec It/Example/Specify blocks
    shellspec_it_block: ($) =>
      prec.right(
        1,
        seq(
          choice("It", "Example", "Specify", "fIt", "fExample", "fSpecify", "xIt", "xExample", "xSpecify"),
          field("description", argument($)),
          repeat($._terminated_statement),
          "End",
        ),
      ),

    // ShellSpec Parameters blocks (Parameters, Parameters:block, :matrix, :dynamic). Every line
    // inside is a parameter row; ShellSpec Parameters blocks have no label. `Parameters:value`
    // is single-line and has its own rule below.
    shellspec_utility_block: ($) =>
      prec.right(1, seq(choice("Parameters", "Parameters:block", "Parameters:matrix", "Parameters:dynamic"), repeat($._terminated_statement), "End")),

    // ShellSpec `Parameters:value v1 v2 ...`: single-line parameter values (no End)
    shellspec_parameters_value_statement: ($) => prec.right(2, seq("Parameters:value", repeat1(field("value", argument($))))),

    // ShellSpec Data blocks - optimized for performance while maintaining functionality
    shellspec_data_block: ($) =>
      choice(
        // Block style with pipe filter + #| lines (highest precedence)
        prec.right(
          6,
          seq(
            choice("Data", "Data:raw", "Data:expand"),
            "|",
            repeat1(field("filter", argument($))),
            repeat1(seq("#|", field("data_line", $.shellspec_data_line_content))),
            "End",
          ),
        ),
        // Block style with #| lines: `Data`, `Data:raw` or `Data:expand` (no space before the modifier)
        prec.right(5, seq(choice("Data", "Data:raw", "Data:expand"), repeat1(seq("#|", field("data_line", $.shellspec_data_line_content))), "End")),
        // Argument(s) with pipe filter (no End, single line)
        prec.right(3, seq("Data", field("argument", argument($)), repeat(field("extra_argument", argument($))), "|", repeat1(field("filter", argument($))))),
        // File input: `Data < FILE` (no End)
        prec.right(4, seq("Data", "<", field("file", argument($)))),
        // String argument style (no End) - lowest precedence
        seq("Data", field("argument", argument($))),
      ),

    // Phase 1: When statement — core ShellSpec assertion DSL
    shellspec_when_statement: ($) =>
      prec.right(
        2,
        seq(
          "When",
          field("type", choice("call", seq("run", optional(choice("command", "script", "source"))))),
          field("function", argument($)),
          repeat(field("argument", argument($))),
        ),
      ),

    // Phase 1: The statement — core ShellSpec expectation DSL
    // Subject consumes words until "should", then matcher consumes the rest
    shellspec_subject: ($) => repeat1(argument($)),

    // Right-associative so a matcher that ends a command substitution is not
    // ambiguous with the subject repeat.
    shellspec_matcher: ($) => prec.right(repeat1(argument($))),

    shellspec_the_statement: ($) =>
      prec.right(2, seq("The", field("subject", $.shellspec_subject), "should", optional(field("negation", "not")), field("matcher", $.shellspec_matcher))),

    // Phase 1: Assert statement
    shellspec_assert_statement: ($) => prec.right(2, seq("Assert", repeat1(field("argument", argument($))))),

    // Phase 2: Mock block
    shellspec_mock_block: ($) => prec.right(1, seq("Mock", field("name", argument($)), repeat($._terminated_statement), "End")),

    // Phase 2: Path/File/Dir statement
    shellspec_path_statement: ($) => prec.right(2, seq(choice("Path", "File", "Dir"), repeat1(field("argument", argument($))))),

    // Phase 2: Set statement
    shellspec_set_statement: ($) => prec.right(2, seq("Set", repeat1(field("option", argument($))))),

    // Phase 2: Dump statement (standalone, no arguments)
    shellspec_dump_statement: () => prec.right(2, "Dump"),

    // Phase 2: Intercept statement
    shellspec_intercept_statement: ($) => prec.right(2, seq("Intercept", repeat1(field("argument", argument($))))),

    // ShellSpec hooks as statements (standalone, without End)
    shellspec_hook_statement: ($) =>
      prec.right(
        2,
        seq(
          choice("Before", "After", "BeforeEach", "AfterEach", "BeforeAll", "AfterAll", "BeforeCall", "AfterCall", "BeforeRun", "AfterRun"),
          repeat1(field("argument", argument($))),
        ),
      ),

    // ShellSpec directives (Include, Skip with conditions)
    shellspec_directive_statement: ($) =>
      prec.right(
        2,
        choice(
          // Include directive; the single path may be a concatenation such as `$ROOT/lib.sh`
          seq("Include", field("path", choice(argument($), $.concatenation))),
          // Conditional `Skip if` (plain Skip is shellspec_skip_statement)
          prec.right(3, seq("Skip", "if", field("reason", argument($)), field("condition", repeat1(choice(argument($), $.test_command))))),
        ),
      ),

    // Phase 3: Todo standalone statement (without End block).
    // The description is optional: ShellSpec accepts a bare `Todo`.
    shellspec_todo_statement: ($) => prec.right(2, seq("Todo", optional(field("description", argument($))))),

    // Phase 4: Pending standalone statement (without End block).
    // The reason is optional: ShellSpec accepts a bare `Pending`.
    shellspec_pending_statement: ($) => prec.right(2, seq("Pending", optional(field("reason", argument($))))),

    // Phase 4: Skip standalone statement (without End block).
    // The reason is optional: ShellSpec accepts a bare `Skip` (official example: `Skip # without reason`).
    shellspec_skip_statement: ($) => prec.right(2, seq("Skip", optional(field("reason", argument($))))),

    // Phase 4: %text directive
    shellspec_text_directive: ($) =>
      prec.right(
        5,
        seq(
          choice("%text", "%text:raw", "%text:expand"),
          optional(seq("|", repeat1(field("filter", argument($))))),
          repeat1(seq("#|", field("data_line", $.shellspec_data_line_content))),
        ),
      ),

    // Reusable data line content for #| lines
    shellspec_data_line_content: () => /[^\n]*/,

    // Phase 4: %const directive
    shellspec_const_directive: ($) => prec.right(2, seq(choice("%const", "%"), field("name", $.word), field("value", argument($)))),

    // Phase 4: Output directives
    shellspec_output_directive: ($) => prec.right(2, seq(choice("%puts", "%putsn", "%-", "%="), repeat1(field("argument", argument($))))),

    // Phase 4: %preserve directive
    shellspec_preserve_directive: ($) => prec.right(2, seq("%preserve", repeat1(field("variable", argument($))))),

    // Phase 4: %logger directive
    shellspec_logger_directive: ($) => prec.right(2, seq("%logger", repeat1(field("argument", argument($))))),
  },
});
