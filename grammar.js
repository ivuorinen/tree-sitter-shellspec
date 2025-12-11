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

  // Optimize conflicts for performance while maintaining correctness
  conflicts: ($, previous) =>
    previous.concat([
      // Essential bash conflicts only
      [$._expression, $.command_name],
      [$.command, $.variable_assignments],
      [$.function_definition, $.command_name],
      // Required ShellSpec conflicts
      [$.command_name, $.shellspec_data_block],
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
          choice("Context", "ExampleGroup", "fContext", "xContext"),
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

    // ShellSpec utility blocks (Parameters, Skip, Pending, Todo - Data has its own rule)
    shellspec_utility_block: ($) =>
      prec.right(
        1,
        seq(
          choice("Parameters", "Skip", "Pending", "Todo"),
          optional(field("label", choice($.string, $.raw_string, $.word))),
          repeat($._terminated_statement),
          "End",
        ),
      ),

    // ShellSpec Data blocks - optimized for performance while maintaining functionality
    shellspec_data_block: ($) =>
      choice(
        // Block style with #| lines
        prec.right(
          5,
          seq(
            "Data",
            optional(seq(":", field("modifier", choice("raw", "expand")))),
            repeat1(seq("#|", field("data_line", /[^\n]*/))),
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
        // String argument style (no End) - lowest precedence
        seq(
          "Data",
          optional(seq(":", field("modifier", choice("raw", "expand")))),
          field("argument", choice($.string, $.raw_string, $.word)),
        ),
      ),

    // ShellSpec hooks as statements (Before/After without End)
    shellspec_hook_statement: ($) =>
      prec.right(
        2,
        seq(
          choice("Before", "After"),
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
          seq(
            "Skip",
            "if",
            field("reason", choice($.string, $.raw_string, $.word)),
            field("condition", repeat1(choice($.word, $.string, $.raw_string))),
          ),
        ),
      ),
  },
});
