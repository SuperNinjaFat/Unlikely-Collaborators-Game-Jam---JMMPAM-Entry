#!/usr/bin/env python3
"""Set the current section in the UCJam save file.

Usage:
    python tools/set_section.py <section_number> [level_path]

Examples:
    python tools/set_section.py 0
    python tools/set_section.py 3
    python tools/set_section.py 2 res://scenes/game_scene/levels/leaf_eater.tscn

If no level_path is given, it modifies all level states found in the save.
Run with no arguments to show the current state.
"""

import os
import re
import sys

SAVE_PATH = os.path.join(
    os.environ.get("APPDATA", ""),
    "Godot", "app_userdata", "UCJam", "global_state.tres",
)


def read_save():
    if not os.path.exists(SAVE_PATH):
        print(f"Save file not found: {SAVE_PATH}")
        sys.exit(1)
    with open(SAVE_PATH, "r", encoding="utf-8") as f:
        return f.read()


def show_state(content):
    sections = re.findall(r"current_section\s*=\s*(\d+)", content)
    levels = re.findall(r'"(res://[^"]+)":\s*SubResource', content)
    if not sections:
        print("No level states found in save.")
        return
    for level, section in zip(levels, sections):
        print(f"  {level}: section {section}")


def set_section(target_section, level_filter=None):
    content = read_save()

    print("Before:")
    show_state(content)

    if level_filter:
        # Find the sub_resource ID for the target level
        match = re.search(
            rf'"{re.escape(level_filter)}":\s*SubResource\("([^"]+)"\)',
            content,
        )
        if not match:
            print(f"\nLevel '{level_filter}' not found in save.")
            sys.exit(1)
        res_id = match.group(1)
        # Replace current_section only in that sub_resource block
        pattern = rf'(\[sub_resource type="Resource" id="{re.escape(res_id)}"\].*?current_section\s*=\s*)\d+'
        content = re.sub(pattern, rf"\g<1>{target_section}", content, flags=re.DOTALL)
    else:
        content = re.sub(
            r"(current_section\s*=\s*)\d+",
            rf"\g<1>{target_section}",
            content,
        )

    with open(SAVE_PATH, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"\nAfter:")
    show_state(content)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Current save state:")
        show_state(read_save())
        print(f"\nUsage: python {sys.argv[0]} <section_number> [level_path]")
        sys.exit(0)

    section = int(sys.argv[1])
    level = sys.argv[2] if len(sys.argv) > 2 else None
    set_section(section, level)
