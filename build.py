# Author: Daniel Penrod
# Python Version: 3.13
# Description:
#   This script automates the process of combining multiple PowerShell scripts into a single file.
#   It reads from a main PowerShell script, identifies and includes referenced module scripts,
#   and writes the combined script to an output file in a 'build' directory. Before creating the build,
#   it ensures that any existing build directory is deleted to avoid conflicts. Additionally, the script
#   maintains a version number (major, minor, patch, build) in a settings JSON file, updating the build
#   number with each run.
#
# How to Run:
#   1. Ensure you have Python 3.13 installed.
#   2. Place this script in the same directory as your 'winDragon.ps1' file and 'Modules' folder.
#   3. Run this script using the command: python build.py
#   4. The combined script will be saved in a 'build' directory as 'winDragon_<version>.ps1'.
#
# What it Will Do:
#   - Read settings from a JSON file, creating default settings if none exist.
#   - Increment the build number in the version information.
#   - Delete any existing 'build' directory to create a clean build environment.
#   - Combine the main PowerShell script and referenced module scripts into a single output file.
#   - Save the combined script in the 'build' directory with a versioned filename.

import os
import re
import json
from pathlib import Path
import shutil


def read_file(file_path):
    # Read the file and return all lines as a list
    with open(file_path, "r", encoding="utf-8") as file:
        return file.readlines()


def clean_lines(lines):
    # Remove comments and leading/trailing whitespace from each line, except for ASCII art sections
    cleaned_lines = []
    inside_ascii_art = False
    for line in lines:
        if "Show-Dragon" in line:
            # If the function Show-Dragon is found, assume ASCII art follows
            inside_ascii_art = True
        if inside_ascii_art:
            # Preserve lines exactly if inside the ASCII art section
            cleaned_lines.append(line.rstrip())
            if line.strip() == "":  # Assuming a blank line ends the ASCII art section
                inside_ascii_art = False
        else:
            stripped_line = re.sub(
                r"#.*", "", line
            ).strip()  # Remove anything after '#' (comments)
            if stripped_line:  # Add the line only if it's not empty
                cleaned_lines.append(stripped_line)
    return cleaned_lines


def read_settings(settings_file):
    # Read settings from a JSON file or create default settings if the file doesn't exist
    settings_path = Path(settings_file)
    if not settings_path.exists():
        # Define default settings
        settings = {
            "defaultSource": "D:\\",
            "defaultDestination": "B:\\DayAfter",
            "version": {"major": 1, "minor": 0, "patch": 0, "build": 0},
        }
        # Write default settings to the settings file
        with settings_path.open("w", encoding="utf-8") as file:
            json.dump(settings, file, indent=2)
    else:
        # Load existing settings from the settings file
        with settings_path.open("r", encoding="utf-8") as file:
            settings = json.load(file)
        # Ensure that the 'version' key exists in settings
        if "version" not in settings:
            settings["version"] = {"major": 1, "minor": 0, "patch": 0, "build": 0}
    return settings


def update_build_number(settings_file, settings):
    # Update the build number in the settings, reset if it exceeds 9999
    if settings["version"]["build"] >= 9999:
        settings["version"]["build"] = 0  # Reset build number
        settings["version"]["patch"] += 1  # Increment patch version
    else:
        settings["version"]["build"] += 1  # Increment build number
    # Save updated settings back to the settings file
    settings_path = Path(settings_file)
    with settings_path.open("w", encoding="utf-8") as file:
        json.dump(settings, file, indent=2)


def get_version_string(version):
    # Construct a version string from the version dictionary
    return (
        f"{version['major']}.{version['minor']}.{version['patch']}.{version['build']}"
    )


def ensure_directory_exists(directory):
    # Create the directory if it doesn't exist
    Path(directory).mkdir(parents=True, exist_ok=True)


def delete_build_directory(directory):
    # Delete the build directory if it exists
    build_path = Path(directory)
    if build_path.exists() and build_path.is_dir():
        shutil.rmtree(build_path)


def combine_powershell_scripts(source_file, modules_folder, output_file):
    # Ensure the build directory exists
    ensure_directory_exists("build")

    # Read the main script file
    main_script_lines = read_file(source_file)
    combined_script = []

    # Pre-compile the regex pattern for module imports for better performance
    module_pattern = re.compile(
        r"^\.\s+(.*\\Modules\\.*\.ps1)$"
    )  # Match module import lines that start with '. '
    inside_show_dragon = False

    for line in main_script_lines:
        if "function Show-Dragon" in line:
            # If we encounter the Show-Dragon function, copy it verbatim until it ends
            inside_show_dragon = True

        if inside_show_dragon:
            combined_script.append(line.rstrip())
            if line.strip() == "":  # Assuming a blank line ends the function
                inside_show_dragon = False
        else:
            # Check if the line imports a module
            module_match = module_pattern.match(line)
            if module_match:
                # Extract the module path from the match
                module_path = module_match.group(1)
                # Construct the full path to the module using Path for better cross-platform compatibility
                module_full_path = Path(modules_folder) / Path(module_path).name
                if module_full_path.exists():
                    # Read and clean lines from the module file
                    module_lines = read_file(module_full_path)
                    combined_script.extend(
                        module_lines
                    )  # Keep the original lines without cleaning them
            else:
                # Clean and add the current line if it's not a module import
                combined_script.extend(clean_lines([line]))

    # Write the combined script to the output file, ensuring UTF-8 encoding
    output_path = Path(output_file)
    with output_path.open("w", encoding="utf-8") as out:
        out.write("\n".join(combined_script))


def update_launcher_script(launcher_file, output_file):
    found = False
    # PowerShell code to append
    ps_code_to_insert = """
    # Define a local temporary file path
    $tempFilePath = "$env:TEMP\\winDragon.ps1"

    # Download the script
    try {
        Invoke-WebRequest -Uri $winDragonScriptURL -OutFile $tempFilePath -ErrorAction Stop
        Write-Host "WinDragon script downloaded successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to download the script: $_" -ForegroundColor Red
        exit
    }
    $winDragonScriptPath = $tempFilePath
    """

    # Extract the filename from the output file path
    output_filename = Path(output_file).name
    # Read the launcher script
    launcher_lines = read_file(launcher_file)
    updated_lines = []
    for line in launcher_lines:
        if "$winDragonScriptPath" in line and not found:
            # Update the winDragonScriptPath to the new output file path
            updated_lines.append(
                f'$winDragonScriptPath = "https://raw.githubusercontent.com/galactic-plane/windragon/main/build/{output_filename}"'
            )
            updated_lines.append(ps_code_to_insert)
            found = True
        else:
            updated_lines.append(line.rstrip())
    # Write the updated launcher script to the build directory
    output_launcher_path = Path("build") / Path(launcher_file).name
    with output_launcher_path.open("w", encoding="utf-8") as out:
        out.write("\n".join(updated_lines))


if __name__ == "__main__":
    # Define source script, modules folder, and settings file
    source_file = "winDragon.ps1"
    modules_folder = "Modules"
    settings_file = "settings.json"

    # Delete the build directory before each build
    delete_build_directory("build")

    # Read or create settings
    settings = read_settings(settings_file)
    # Get the version string from the settings
    version_string = get_version_string(settings["version"])
    # Define the output file path
    output_file = Path("build") / f"winDragon_{version_string}.ps1"

    # Combine the PowerShell scripts
    combine_powershell_scripts(source_file, modules_folder, output_file)
    # Update the build number in settings
    update_build_number(settings_file, settings)
    # Update and copy the launcher script to the build directory
    update_launcher_script("launcher.ps1", output_file)

    # Print the location of the combined script
    print(f"Combined script has been saved to {output_file}")
