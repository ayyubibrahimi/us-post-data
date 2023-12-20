import os
import re
from datetime import datetime

def clean_filename(filename):
    name, ext = os.path.splitext(filename)
    name = re.sub(r'[^a-zA-Z0-9\-_ ]', '', name).replace(' ', '-').lower()
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    return f"{name}-{timestamp}{ext}"

def rename_files(root_directory, dry_run=True):
    log_file = os.path.join(root_directory, 'rename_log.txt')
    with open(log_file, 'w') as log:
        for root, dirs, files in os.walk(root_directory):
            print(f"Current directory: {root}")
            print(f"Subdirectories: {dirs}")
            print(f"Files: {files}")
            for file in files:
                old_path = os.path.join(root, file)
                new_filename = clean_filename(file)
                new_path = os.path.join(root, new_filename)

                log.write(f"Renaming '{old_path}' to '{new_path}'\n")

                if not dry_run:
                    os.rename(old_path, new_path)

        if dry_run:
            log.write("Dry run complete. No files were actually renamed.")

if __name__ == "__main__":
    root_directory = '../../data'  
    rename_files(root_directory, dry_run=False)  
