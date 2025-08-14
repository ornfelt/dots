import os
from itertools import combinations

def remove_txt_files_in_current_dir():
    """Remove all `.txt` files in the current directory."""
    current_dir = os.getcwd()
    for item in os.listdir(current_dir):
        if item.endswith('.txt'):
            try:
                os.remove(os.path.join(current_dir, item))
                print(f"Removed file: {item}")
            except Exception as e:
                print(f"Error removing file {item}: {e}")

def get_top_dirs_containing_update_script(base_dir):
    """Get a list of immediate directories containing an 'update.sh' file, excluding 'scripts'."""
    parent_dir = os.path.dirname(base_dir)
    update_dirs = []
    for entry in os.listdir(parent_dir):
        if entry == "scripts":
            continue  # Skip the 'scripts' directory
        full_path = os.path.join(parent_dir, entry)
        if os.path.isdir(full_path):
            if 'update.sh' in os.listdir(full_path):
                update_dirs.append(entry)
    return update_dirs

def gather_entries_from_file(filepath):
    """Read file and gather unique entries by splitting content on '=' or ' '."""
    entries = set()
    if os.path.exists(filepath):
        with open(filepath, 'r') as f:
            for line in f:
                part = line.split('=', 1)[0].split(' ', 1)[0].strip()
                if part:
                    entries.add(part)
    return entries

def diff_and_print(unique1, unique2, dir1, dir2, package_type, write_to_file, line_sep):
    """Print differences and optionally save them to a file."""
    filename = f"{dir1}_{dir2}_{package_type}_diff.txt" if write_to_file else None
    separator = "-" * 50 # Define a line separator

    with open(filename, 'w') if write_to_file else None as file:
        def safe_print(msg):
            # Print to console
            #print(msg)
            if file:
                file.write(msg + "\n")

        diff1 = unique1 - unique2
        diff2 = unique2 - unique1

        if diff1 or diff2:
            safe_print(f"Differences between {dir1} and {dir2} for {package_type} packages:\n")
            if diff1:
                entries_1 = "\n".join(sorted(diff1)) if line_sep else ", ".join(sorted(diff1))
                safe_print(f"-> {dir1} has unique entries:\n{entries_1}")
                safe_print("\n" + separator + "\n")
            if diff2:
                entries_2 = "\n".join(sorted(diff2)) if line_sep else ", ".join(sorted(diff2))
                safe_print(f"-> {dir2} has unique entries:\n{entries_2}")
        else:
            safe_print(f"No differences found between {dir1} and {dir2} for {package_type} packages.")

def main():
    # Remove all .txt files in the current directory
    remove_txt_files_in_current_dir()

    current_dir = os.getcwd()
    print(f"Current Directory: {current_dir}")

    # Step 2: Determine directories containing 'update.sh' one level up
    update_dirs = get_top_dirs_containing_update_script(current_dir)

    # Step 3: Check directories found
    if len(update_dirs) == 0:
        print("No directories with 'update.sh'.")
        return
    elif len(update_dirs) == 1:
        print(f"Only one directory found with 'update.sh': {update_dirs[0]}")
        return
    else:
        print(f"Found directories with 'update.sh': {update_dirs}")

    # Step 4 & 5: Compare pairs of directories
    directory_base = "/home/jonas/Documents/installation"
    python_use_merged = False
    arch_use_other = False
    deb_use_all = True
    write_to_file = True  # Option to write differences to files
    line_sep = True  # Option to print differences with line separation

    for dir1, dir2 in combinations(update_dirs, 2):
        print(f"Comparing '{dir1}' and '{dir2}'")

        # Compare Arch Python requirements file
        py_file_1 = os.path.join(directory_base, dir1, 'merged_requirements.txt' if python_use_merged else 'requirements.txt')
        py_file_2 = os.path.join(directory_base, dir2, 'merged_requirements.txt' if python_use_merged else 'requirements.txt')
        
        if os.path.exists(py_file_1) and os.path.exists(py_file_2):
            py_entries1 = gather_entries_from_file(py_file_1)
            py_entries2 = gather_entries_from_file(py_file_2)
            diff_and_print(py_entries1, py_entries2, dir1, dir2, "python", write_to_file, line_sep)
        else:
            if not os.path.exists(py_file_1):
                print(f"Missing Python requirements file in {dir1}")
            if not os.path.exists(py_file_2):
                print(f"Missing Python requirements file in {dir2}")

        # Compare Debian Python requirements file
        deb_py_file_1 = os.path.join(directory_base, dir1, 'packages', 'debian', 'merged_requirements.txt' if python_use_merged else 'requirements.txt')
        deb_py_file_2 = os.path.join(directory_base, dir2, 'packages', 'debian', 'merged_requirements.txt' if python_use_merged else 'requirements.txt')
        
        if os.path.exists(deb_py_file_1) and os.path.exists(deb_py_file_2):
            deb_py_entries1 = gather_entries_from_file(deb_py_file_1)
            deb_py_entries2 = gather_entries_from_file(deb_py_file_2)
            diff_and_print(deb_py_entries1, deb_py_entries2, dir1, dir2, "debian_python", write_to_file, line_sep)
        else:
            if not os.path.exists(deb_py_file_1):
                print(f"Missing Debian Python requirements file in {dir1}")
            if not os.path.exists(deb_py_file_2):
                print(f"Missing Debian Python requirements file in {dir2}")

        # TODO: cross compare requirements deb->arch and vice versa?

        # Arch packages
        arch_file_1 = os.path.join(directory_base, dir1, 'other.txt' if arch_use_other else 'package_list.txt')
        arch_file_2 = os.path.join(directory_base, dir2, 'other.txt' if arch_use_other else 'package_list.txt')
        
        if os.path.exists(arch_file_1) and os.path.exists(arch_file_2):
            arch_entries1 = gather_entries_from_file(arch_file_1)
            arch_entries2 = gather_entries_from_file(arch_file_2)
            diff_and_print(arch_entries1, arch_entries2, dir1, dir2, "arch", write_to_file, line_sep)
        else:
            if not os.path.exists(arch_file_1):
                print(f"Missing Arch package list in {dir1}")
            if not os.path.exists(arch_file_2):
                print(f"Missing Arch package list in {dir2}")

        # Debian packages
        deb_file_1 = os.path.join(directory_base, dir1, 'packages', 'debian', 'package_list_all.txt' if deb_use_all else 'package_list.txt')
        deb_file_2 = os.path.join(directory_base, dir2, 'packages', 'debian', 'package_list_all.txt' if deb_use_all else 'package_list.txt')
        
        if os.path.exists(deb_file_1) and os.path.exists(deb_file_2):
            deb_entries1 = gather_entries_from_file(deb_file_1)
            deb_entries2 = gather_entries_from_file(deb_file_2)
            diff_and_print(deb_entries1, deb_entries2, dir1, dir2, "debian", write_to_file, line_sep)
        else:
            if not os.path.exists(deb_file_1):
                print(f"Missing Debian package list in {dir1}")
            if not os.path.exists(deb_file_2):
                print(f"Missing Debian package list in {dir2}")

if __name__ == '__main__':
    main()

