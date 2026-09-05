#!/usr/bin/env python3
"""Fail when the committed Eleblorb web deployment is absent or stale."""

from web_build import validate_build


def main() -> None:
    errors = validate_build()
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        raise SystemExit(1)
    print("Web build matches the current Eleblorb source.")


if __name__ == "__main__":
    main()
