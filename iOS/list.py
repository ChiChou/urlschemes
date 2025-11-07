import plistlib
import subprocess
import sys

if __name__ == "__main__":
    # reuse ideviceinstaller command flags
    args = ["ideviceinstaller", "list", "--xml"] + sys.argv[1:]

    try:
        child = subprocess.Popen(args, stdout=subprocess.PIPE)
    except FileNotFoundError:
        sys.stderr.write("ideviceinstaller command does not exist")
        sys.exit(1)

    stdout, _ = child.communicate()
    result = plistlib.loads(stdout)
    for item in result:
        url_types = item.get("CFBundleURLTypes")
        if not url_types:
            continue

        path = item.get("Path")
        bundle = item.get("CFBundleIdentifier")
        name = item.get("CFBundleName")

        print(f"{name} ({bundle}):")
        print(path)
        print()

        for entry in url_types:
            url_schemes = entry.get("CFBundleURLSchemes", [])
            for scheme in url_schemes:
                print(
                    f"  {scheme}://",
                    "(private)" if entry.get("CFBundleURLIsPrivate") else "",
                )
        print()
