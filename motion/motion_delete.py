import os

"""
This script checks a folder and deletes all files in that folder if they match a specific 
file type. Additionally, an age check is implemented only delete desired files.
"""

# Type in FileTypes you wish to delete
snapshot_filetype = '*.mkv'
timelapse_filetype = '*.mpg'

# Number of days to check back (e.g. if 7, it will delete files greater than or equal to 7 days old)
snapshot_age = '7'
timelapse_age = '7'

default_motion_directory = '/var/lib/motion/'

def run_delete():
	try:
		print(f'Running...\n')
		os.system(f"find {default_motion_directory} -type f -mtime +{snapshot_age} -name {snapshot_filetype} -delete")
		os.system(f"find {default_motion_directory} -type f -mtime +{timelapse_age} -name {timelapse_filetype} -delete")
		print(f'Complete...\n')
	except Exception as e:
		print(f'Something bad happened: {e}')

run_delete()
