#!/usr/bin/env python2.6
import os
import sys
import re
from subprocess import check_output

#SOURCE_DIR = "/home/www/"
#TARGET_DIR = "/.backup/"
SOURCE_DIR = "C:\\Users\\queria\\Documents\\share_downloader"
TARGET_DIR = "C:\\Users\\queria\\Documents\\backup"

skip_list = []
with open('./backup.exclude', 'r') as f:
	for line in f:
		if line[0] == '#':
			continue
		skip_list.append(line.strip())

def warning(message):
	print(message)

def error(message):
	print(message)
	sys.exit(1)

_slugify_strip_re = re.compile(r'([^\w\s-]|[\s])+')
#_slugify_hyphenate_re = re.compile(r'[_\s]+')
def slugify(value):
    """
    Normalizes string, converts to lowercase, removes non-alpha characters,
    and converts spaces to hyphens.
    
    From Django's "django/template/defaultfilters.py".
    """
    import unicodedata
    if not isinstance(value, unicode):
        value = unicode(value)
    value = unicodedata.normalize('NFKD', value).encode('ascii', 'ignore')
    value = unicode(_slugify_strip_re.sub('_', value).strip().lower())
    return value
	#_slugify_hyphenate_re.sub('-', value)


result_output = ''
to_backup = []
failed_paths = []

cmd = ['tar',
		'--create',
		'--gzip',
		'--preserve-permission',
		'--one-file-system',
		]

for sub in os.listdir(SOURCE_DIR):
	#if not os.path.isdir(SOURCE_DIR + sub):
	#	not_dirs.append(SOURCE_DIR + sub)
	#else:
	srcdir = os.path.join(SOURCE_DIR, sub)
	stgt = slugify(srcdir)
	tgtdir = os.path.join(TARGET_DIR, stgt)

	if srcdir in skip_list:
		continue

	cmd_args = ['-g', os.path.join(tgtdir, '_status'),
			'--file={0}.tar.gz'.format(os.path.join(tgtdir, stgt)),
			srcdir]
	
	try:
		result_output += "{0}\n".format(cmd + cmd_args)
	except CalledProcessError, e:
		result_output += "----------------------\nBackup of {0} failed:\n".format(srcdir)
		result_output += str(e.output)
		result_output += "----------------------\n"
		pass
	except OSError, e:
		result_output += "----------------------\nBackup of {0} failed:\n".format(srcdir)
		result_output += str(e)
		result_output += "----------------------\n"
		pass
	

# TAROPTS="--gzip --preserve-permission --one-file-system"
# if ! tar --create ${TAROPTS} -g ${QS_TGTDIR}"/_status" --file=${QS_TGTDIR}"/"${QS_TGT}"_"${STAMP}".tar.gz" ${QS_SRC} &> /dev/null;

if failed_paths:
	warning("Nasledujici cesty se nepovedlo zalohovat: {0}".format(failed_paths))

print skip_list
print(result_output)

raw_input()
