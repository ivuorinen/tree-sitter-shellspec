import assert from "node:assert";
import { test } from "node:test";
import Parser from "tree-sitter";

// The callback is async and the assertion awaited: assert.doesNotReject returns a
// promise, so without the await the test ends before the dynamic import or
// setLanguage can reject, and a real failure passes silently.
test("can load grammar", async () => {
  const parser = new Parser();
  await assert.doesNotReject(async () => {
    const { default: language } = await import("./index.js");
    parser.setLanguage(language);
  });
});
