import os
import subprocess
from datetime import datetime, timedelta

# Define file types and their respective age limits
file_types = {
    '*.mkv': 7,
    '*.mpg': 7
}

default_motion_directory = '/var/lib/motion/'

def delete_old_files(directory, file_type, age_limit):
    now = datetime.now()
    cutoff = now - timedelta(days=age_limit)
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(file_type.split('.')[-1]):
                file_path = os.path.join(root, file)
                file_mtime = datetime.fromtimestamp(os.path.getmtime(file_path))
                if file_mtime < cutoff:
                    try:
                        os.remove(file_path)
                        print(f'Deleted {file_path}')
                    except Exception as e:
                        print(f'Error deleting {file_path}: {e}')

def run_delete():
    print('Running...\n')
    for file_type, age_limit in file_types.items():
        delete_old_files(default_motion_directory, file_type, age_limit)
    print('Complete...\n')

if __name__ == "__main__":
    run_delete()
