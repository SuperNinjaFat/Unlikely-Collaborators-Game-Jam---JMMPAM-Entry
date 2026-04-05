#!/usr/bin/env python3
"""Set the current section in the Caterpillar Climb save file.

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
    "Godot", "app_userdata", "Caterpillar Climb", "global_state.tres",
)


def read_save():
    if not os.path.exists(SAVE_PATH):
        print(f"Save file not found: {SAVE_PATH}")
        sys.exit(1)
    with open(SAVE_PATH, "r", encoding="utf-8") as f:
        return f.read()


def _get_level_sub_resource_ids(content):
    """Return dict mapping level path -> sub_resource id."""
    return dict(re.findall(r'"(res://[^"]+)":\s*SubResource\("([^"]+)"\)', content))


def _get_section_for_block(content, res_id):
    """Get current_section from a sub_resource block, defaulting to 0."""
    pattern = rf'\[sub_resource type="Resource" id="{re.escape(res_id)}"\](.*?)(?=\n\[|\Z)'
    match = re.search(pattern, content, re.DOTALL)
    if not match:
        return 0
    sec_match = re.search(r'current_section\s*=\s*(\d+)', match.group(1))
    return int(sec_match.group(1)) if sec_match else 0


def _set_section_in_block(content, res_id, target_section):
    """Set current_section in a sub_resource block, adding it if missing."""
    block_pattern = rf'(\[sub_resource type="Resource" id="{re.escape(res_id)}"\])(.*?)(?=\n\[|\Z)'
    match = re.search(block_pattern, content, re.DOTALL)
    if not match:
        return content
    block_header = match.group(1)
    block_body = match.group(2)
    if re.search(r'current_section\s*=\s*\d+', block_body):
        new_body = re.sub(r'(current_section\s*=\s*)\d+', rf'\g<1>{target_section}', block_body)
    else:
        new_body = block_body.rstrip('\n') + f'\ncurrent_section = {target_section}\n'
    return content[:match.start()] + block_header + new_body + content[match.end():]


def show_state(content):
    levels = _get_level_sub_resource_ids(content)
    if not levels:
        print("No level states found in save.")
        return
    for level_path, res_id in levels.items():
        section = _get_section_for_block(content, res_id)
        print(f"  {level_path}: section {section}")


def set_section(target_section, level_filter=None):
    content = read_save()

    print("Before:")
    show_state(content)

    levels = _get_level_sub_resource_ids(content)

    if level_filter:
        if level_filter in levels:
            content = _set_section_in_block(content, levels[level_filter], target_section)
        else:
            # Level not in save yet — create a new level state entry
            new_id = f"Resource_new_{abs(hash(level_filter)) % 100000:05d}"
            ls_match = re.search(
                r'\[ext_resource.*?path="res://scripts/level_state\.gd"\s+id="([^"]+)"\]',
                content,
            )
            if not ls_match:
                print("\nCould not find level_state.gd ext_resource in save file.")
                sys.exit(1)
            ls_ext_id = ls_match.group(1)
            new_block = (
                f'[sub_resource type="Resource" id="{new_id}"]\n'
                f'script = ExtResource("{ls_ext_id}")\n'
                f'current_section = {target_section}\n\n'
            )
            content = re.sub(
                r'(\[sub_resource type="Resource")',
                new_block + r'\1',
                content,
                count=1,
            )
            content = re.sub(
                r'(level_states\s*=\s*\{)',
                rf'\1\n"{level_filter}": SubResource("{new_id}"),',
                content,
            )
    else:
        for res_id in levels.values():
            content = _set_section_in_block(content, res_id, target_section)

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
