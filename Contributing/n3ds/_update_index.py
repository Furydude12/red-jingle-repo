import sys, json

if len(sys.argv) != 4:
    print("Usage: _update_index.py <index.json path> <game title> <jingle path>")
    sys.exit(1)

index_path, game_title, jingle_path = sys.argv[1], sys.argv[2], sys.argv[3]

# Normalize path separators to forward slashes (for cross-platform consistency)
jingle_path = jingle_path.replace('\\', '/')

try:
    with open(index_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
except FileNotFoundError:
    data = {"name": "Red's Jingles Pack", "entries": []}

entries = data.get("entries", [])

# Remove any existing entry with the same file path (idempotent re-runs)
entries = [e for e in entries if e.get("file") != jingle_path]

entries.append({"game": game_title, "file": jingle_path})

# Sort alphabetically by game title (case-insensitive)
entries.sort(key=lambda e: e["game"].lower())

data["entries"] = entries

with open(index_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')

print(f"[index.json] Added: {game_title} -> {jingle_path}")
