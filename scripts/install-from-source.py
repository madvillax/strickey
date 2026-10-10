#!/usr/bin/env python3
"""Build strickey from its Git source and install it in a macOS Applications folder."""

import argparse
import os
import platform
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


DEFAULT_REPOSITORY = "madvillax/strickey"
REQUIRED_COMMANDS = ("git", "swift", "zsh")


def run(command, *, cwd=None, check=True):
    return subprocess.run(command, cwd=cwd, check=check)


def remove_path(path):
    if path.is_symlink() or (path.exists() and not path.is_dir()):
        path.unlink()
    elif path.exists():
        shutil.rmtree(path)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Build strickey from GitHub source and install it locally."
    )
    parser.add_argument(
        "--repository",
        default=os.environ.get("STRICKEY_GITHUB_REPOSITORY", DEFAULT_REPOSITORY),
        help="GitHub owner/repository (default: %(default)s)",
    )
    parser.add_argument(
        "--ref",
        default=os.environ.get("STRICKEY_SOURCE_REF", "main"),
        help="branch or tag to build (default: %(default)s)",
    )
    parser.add_argument(
        "--install-directory",
        default=os.environ.get(
            "STRICKEY_INSTALL_DIRECTORY", str(Path.home() / "Applications")
        ),
        help="destination directory (default: %(default)s)",
    )
    return parser.parse_args()


def validate_environment(repository, ref):
    if platform.system() != "Darwin":
        raise RuntimeError("strickey can only be installed on macOS.")
    if sys.version_info < (3, 9):
        raise RuntimeError("Python 3.9 or newer is required.")
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository):
        raise RuntimeError("Repository must be written as OWNER/REPO.")
    if any(part in (".", "..") for part in repository.split("/")):
        raise RuntimeError("Repository must be a GitHub OWNER/REPO name.")
    if not ref or ref.startswith("-") or any(character.isspace() for character in ref):
        raise RuntimeError("Ref must be a branch or tag name.")

    version = subprocess.check_output(
        ["/usr/bin/sw_vers", "-productVersion"], text=True
    ).strip()
    try:
        macos_major = int(version.split(".", 1)[0])
    except ValueError as error:
        raise RuntimeError(f"Could not read the macOS version: {version}") from error
    if macos_major < 14:
        raise RuntimeError("strickey requires macOS 14 or newer.")

    missing = [command for command in REQUIRED_COMMANDS if shutil.which(command) is None]
    if missing:
        raise RuntimeError(
            "Missing build tools: "
            + ", ".join(missing)
            + ". Install Xcode 26+ or Apple's Command Line Tools with Swift 6+."
        )

    running = subprocess.run(
        ["/usr/bin/pgrep", "-x", "Strickey"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    if running.returncode == 0:
        raise RuntimeError("Quit strickey before installing or updating it.")


def install_source(repository, ref, install_directory):
    install_directory = install_directory.expanduser().resolve()
    install_directory.mkdir(parents=True, exist_ok=True)
    target_app = install_directory / "Strickey.app"

    with tempfile.TemporaryDirectory(prefix="strickey-source-") as temporary:
        source_directory = Path(temporary) / "source"
        run(
            [
                "git",
                "clone",
                "--depth",
                "1",
                "--branch",
                ref,
                f"https://github.com/{repository}.git",
                str(source_directory),
            ]
        )
        run(
            [
                "/bin/zsh",
                str(source_directory / "scripts" / "build-app.sh"),
                "release",
                "native",
            ],
            cwd=source_directory,
        )
        built_app = source_directory / "dist" / "Strickey.app"
        if not built_app.is_dir():
            raise RuntimeError("The source build completed without producing Strickey.app.")

        staging_directory = Path(
            tempfile.mkdtemp(prefix=".strickey-install-", dir=install_directory)
        )
        staged_app = staging_directory / "Strickey.app"
        backup_app = install_directory / f".Strickey.backup-{os.getpid()}.app"
        try:
            run(["/usr/bin/ditto", str(built_app), str(staged_app)])
            if backup_app.exists() or backup_app.is_symlink():
                raise RuntimeError(f"Temporary backup already exists: {backup_app}")

            had_existing_app = target_app.exists() or target_app.is_symlink()
            if had_existing_app:
                os.replace(target_app, backup_app)
            try:
                os.replace(staged_app, target_app)
            except Exception:
                if had_existing_app and (backup_app.exists() or backup_app.is_symlink()):
                    os.replace(backup_app, target_app)
                raise
            if had_existing_app:
                remove_path(backup_app)
        finally:
            shutil.rmtree(staging_directory, ignore_errors=True)

    print(f"Installed strickey from {repository}@{ref} at {target_app}")
    print("Open strickey and enable Input Monitoring in System Settings > Privacy & Security.")
    run(["/usr/bin/open", str(target_app)], check=False)


def main():
    arguments = parse_args()
    try:
        validate_environment(arguments.repository, arguments.ref)
        install_source(
            arguments.repository,
            arguments.ref,
            Path(arguments.install_directory),
        )
    except (OSError, subprocess.CalledProcessError, RuntimeError) as error:
        print(f"strickey source install failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
