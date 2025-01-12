import sys
from collections import OrderedDict

def merge_requirements(req_file, temp_file):
    # Read requirements.txt into an OrderedDict to preserve order
    existing_packages = OrderedDict()
    with open(req_file, 'r') as req:
        for line in req:
            if '==' in line:
                package, version = line.strip().split('==', 1)
                existing_packages[package.lower()] = line.strip()

    # Read temp_file and add any new packages (prioritize req_file versions)
    with open(temp_file, 'r') as temp:
        for line in temp:
            if '==' in line:
                package, version = line.strip().split('==', 1)
                package_lower = package.lower()
                if package_lower not in existing_packages:
                    existing_packages[package_lower] = line.strip()

    # Write merged and sorted output back to req_file
    with open(req_file, 'w') as req:
        #for package in sorted(existing_packages.values(), key=lambda x: x.split('==')[0].lower()):
        for package in sorted(existing_packages.values(), key=lambda x: x.lower()):
            req.write(package + '\n')

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 merge_requirements.py <req_file> <temp_file>")
        sys.exit(1)

    merge_requirements(sys.argv[1], sys.argv[2])

