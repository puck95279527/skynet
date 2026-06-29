#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/publish/lua"
DST="$ROOT/publish/lua-bytecode"
LUAC="$ROOT/publish/3rd/lua-x/lua-x-compiler"

if [[ ! -x "$LUAC" ]]; then
  echo "luac not found or not executable: $LUAC" >&2
  exit 1
fi

if [[ ! -d "$SRC" ]]; then
  echo "lua source directory not found: $SRC" >&2
  exit 1
fi

rm -rf "$DST"
mkdir -p "$DST"

count=0
while IFS= read -r -d '' file; do
  rel="${file#$SRC/}"
  out="$DST/${rel%.lua}.luac"
  mkdir -p "$(dirname "$out")"
  (cd "$SRC" && "$LUAC" -o "$out" "$rel")
  count=$((count + 1))
done < <(find "$SRC" -type f -name '*.lua' -print0 | sort -z)

copied=0
while IFS= read -r -d '' file; do
  rel="${file#$SRC/}"
  out="$DST/$rel"
  mkdir -p "$(dirname "$out")"
  cp "$file" "$out"
  copied=$((copied + 1))
done < <(find "$SRC" -type f ! -name '*.lua' -print0 | sort -z)

cat > "$DST/examples/config.path" <<'CONFIG_PATH'
root = "./"
lua_root = root .. "lua-bytecode/"
luaservice = lua_root.."service/?.luac;"..lua_root.."test/?.luac;"..lua_root.."examples/?.luac;"..lua_root.."test/?/init.luac"
lualoader = lua_root .. "lualib/loader.luac"
lua_path = lua_root.."lualib/?.luac;"..lua_root.."lualib/?/init.luac"
lua_cpath = root .. "lib/luaclib/?.so"
snax = lua_root.."examples/?.luac;"..lua_root.."test/?.luac"
CONFIG_PATH

echo "Compiled $count Lua files"
echo "Copied $copied non-Lua files"
echo "Source: $SRC"
echo "Output: $DST"
