#!/usr/bin/env python2.6
import ConfigParser
import os
import sys
import re
import datetime
import subprocess

DEBUG_PRETEND = False

SOURCE_DIR = "/please-prepare-configuration-file"
TARGET_DIR = SOURCE_DIR
EXCLUDE_FILE = './backup.exclude'

cfg = ConfigParser.RawConfigParser()
cfg.read('backup.cfg')
SOURCE_DIR = cfg.get('main', 'source_dir')
TARGET_DIR = cfg.get('main', 'target_dir')

skip_list = []
try:
    with open(EXCLUDE_FILE, 'r') as f:
        for line in f:
            if line[0] == '#':
                continue
            skip_list.append(line.strip())
except IOError, e:
    skip_list = []

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
    if value[0] == '_':
        value = value[1:]
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
if skip_list:
    cmd += ['--exclude-from', EXCLUDE_FILE]


for sub in os.listdir(SOURCE_DIR):
    #if not os.path.isdir(SOURCE_DIR + sub):
    #   not_dirs.append(SOURCE_DIR + sub)
    #else:
    srcdir = os.path.join(SOURCE_DIR, sub)
    stgt = slugify(srcdir)
    tgtdir = os.path.join(TARGET_DIR, stgt)

    if srcdir in skip_list:
        continue

    cmd_args = ['-g', os.path.join(tgtdir, '_status'),
        '--file={0}-{1}.tar.gz'.format(
            os.path.join(tgtdir, stgt),
            datetime.datetime.now().strftime('%Y_%m_%d-%H_%M_%S_%f')),
        srcdir]

    try:
        if not os.path.exists(tgtdir):
            os.makedirs(tgtdir, 0700)
        if DEBUG_PRETEND:
            result_output += "{0}\n".format(cmd + cmd_args)
        else:
            tar = subprocess.Popen(cmd + cmd_args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            tar_out = tar.communicate()
            if tar.returncode != 0:
                result_output += "----------------------\nBackup of {0} failed:\n".format(srcdir)
                result_output += str(tar_out[1])
                result_output += "\n----------------------\n"
    except OSError, e:
        result_output += "----------------------\nBackup of {0} failed:\n".format(srcdir)
        result_output += "Error #" + str(e.errno) + ": " + e.strerror
        result_output += "\n----------------------\n"
        pass


if failed_paths:
    warning("Nasledujici cesty se nepovedlo zalohovat: {0}".format(failed_paths))

#print skip_list
if result_output:
    print("_...----=======[ QSBackup starting ]=======----..._")
    print(result_output)

