// Merges Rakuen's VS Code settings or keybindings into a user file (task 16.4).
//
// Run by bin/install.sh through: osascript -l JavaScript merge-vscode-json.js
//   <settings|keybindings> <target file> <source file>
//
// - settings: every key of the source is set in the target (the source wins), other
//   keys are kept.
// - keybindings: source entries missing from the target (same key, command and
//   when) are appended; the user's own entries stay.
//
// Prints "changed", "unchanged" or "created". A target with comments (VS Code's
// own template has one) is edited in place: missing keys or entries are inserted
// and the comments stay; values the user already set are kept. Exits 2 when the
// target is not valid JSON even without comments, and the installer leaves it alone.

ObjC.import("Foundation");
ObjC.import("stdlib");

function read_text(path) {
  const text = $.NSString.stringWithContentsOfFileEncodingError($(path), $.NSUTF8StringEncoding, null);

  if (text.isNil()) {
    return null;
  }
  return ObjC.unwrap(text);
}

function write_text(path, text) {
  const ok = $(text).writeToFileAtomicallyEncodingError($(path), true, $.NSUTF8StringEncoding, null);

  if (!ok) {
    throw new Error("could not write " + path);
  }
}

function binding_id(entry) {
  return [entry.key, entry.command, entry.when || ""].join("|");
}

function merge_settings(target, source) {
  let changed = false;

  Object.keys(source).forEach(function (key) {
    if (JSON.stringify(target[key]) !== JSON.stringify(source[key])) {
      target[key] = source[key];
      changed = true;
    }
  });
  return changed;
}

function merge_keybindings(target, source) {
  const known = {};
  let changed = false;

  target.forEach(function (entry) {
    known[binding_id(entry)] = true;
  });

  source.forEach(function (entry) {
    if (!known[binding_id(entry)]) {
      target.push(entry);
      changed = true;
    }
  });
  return changed;
}

// Text without // and /* */ comments or trailing commas (strings are respected).
function strip_jsonc(text) {
  let result = "";
  let in_string = false;
  let index = 0;

  while (index < text.length) {
    const char = text[index];
    const next = text[index + 1];

    if (in_string) {
      result += char;
      if (char === "\\") {
        result += next;
        index += 1;
      } else if (char === '"') {
        in_string = false;
      }
    } else if (char === '"') {
      in_string = true;
      result += char;
    } else if (char === "/" && next === "/") {
      while (index < text.length && text[index] !== "\n") {
        index += 1;
      }
      continue;
    } else if (char === "/" && next === "*") {
      index += 2;
      while (index < text.length && !(text[index] === "*" && text[index + 1] === "/")) {
        index += 1;
      }
      index += 1;
    } else {
      result += char;
    }
    index += 1;
  }

  return result.replace(/,(\s*[}\]])/g, "$1");
}

function indent(text) {
  return text.split("\n").map(function (line) { return "  " + line; }).join("\n");
}

// Adds `fragments` (already formatted entries) before the closing bracket of the
// original text, so the user's comments and layout stay as they are.
function insert_fragments(original, stripped, fragments, closing) {
  const close_index = original.lastIndexOf(closing);
  const body = stripped.slice(0, stripped.lastIndexOf(closing)).trim();
  const needs_comma = !/[\[{,]$/.test(body);
  const added = fragments.map(indent).join(",\n");

  return original.slice(0, close_index).replace(/\s*$/, "") + (needs_comma ? "," : "") + "\n" + added + "\n" + original.slice(close_index);
}

// Merge into a file that has comments: only missing keys or entries are added.
// Settings the user already set to another value are kept, not overwritten.
function merge_commented(kind, original, stripped, target, source) {
  const fragments = [];

  if (kind === "settings") {
    Object.keys(source).forEach(function (key) {
      if (!(key in target)) {
        fragments.push(JSON.stringify(key) + ": " + JSON.stringify(source[key], null, 2));
      }
    });
  } else {
    const known = {};
    target.forEach(function (entry) {
      known[binding_id(entry)] = true;
    });
    source.forEach(function (entry) {
      if (!known[binding_id(entry)]) {
        fragments.push(JSON.stringify(entry, null, 2));
      }
    });
  }

  if (fragments.length === 0) {
    return null;
  }
  return insert_fragments(original, stripped, fragments, kind === "settings" ? "}" : "]");
}

function run(argv) {
  const kind = argv[0];
  const target_path = argv[1];
  const source = JSON.parse(read_text(argv[2]));
  const existing = read_text(target_path);
  const empty = kind === "settings" ? {} : [];

  let target = empty;
  let commented = false;
  if (existing !== null && existing.trim() !== "") {
    try {
      target = JSON.parse(existing);
    } catch (error) {
      commented = true;
      try {
        target = JSON.parse(strip_jsonc(existing));
      } catch (second_error) {
        $.NSFileHandle.fileHandleWithStandardError.writeData(
          $("not valid JSON: " + target_path + "\n").dataUsingEncoding($.NSUTF8StringEncoding)
        );
        $.exit(2);
      }
    }
  }

  if (commented) {
    const merged = merge_commented(kind, existing, strip_jsonc(existing), target, source);

    if (merged === null) {
      return "unchanged";
    }
    write_text(target_path, merged.replace(/\s*$/, "") + "\n");
    return "changed (comments kept, your own values kept)";
  }

  const changed = kind === "settings" ? merge_settings(target, source) : merge_keybindings(target, source);

  if (!changed && existing !== null) {
    return "unchanged";
  }

  write_text(target_path, JSON.stringify(target, null, 2) + "\n");
  return existing === null ? "created" : "changed";
}
