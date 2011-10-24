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
cfg.read( os.path.join(os.path.dirname(sys.argv[0]), 'backup.cfg') )
SOURCE_DIR = cfg.get('main', 'source_dir')
TARGET_DIR = cfg.get('main', 'target_dir')
EXCLUDE_FILE = cfg.get('main', 'exclude')

skip_list = []
try:
    with open(EXCLUDE_FILE, 'r') as f:
        for line in f:
            if line[0] == '#':
                continue
            skip_list.append(line.strip())
except IOError, e:
    skip_list = []

cmd = ['tar',
        '--create',
        '--gzip',
        '--preserve-permission',
        '--one-file-system',
        ]
if skip_list:
    cmd += ['--exclude-from', EXCLUDE_FILE]

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


def backup_dir(source_path, target_dir, target_name):
    output = ''

    target_path = os.path.join(target_dir, target_name)

    cmd_args = ['-g', os.path.join(target_path, '_status'),
        '--file={0}-{1}.tar.gz'.format(
            os.path.join(target_path, target_name),
            datetime.datetime.now().strftime('%Y_%m_%d-%H_%M_%S_%f')),
        source_path]

    try:
        if not os.path.exists(target_path):
            os.makedirs(target_path, 0700)
        if DEBUG_PRETEND:
            output += "{0}\n".format(cmd + cmd_args)
        else:
            tar = subprocess.Popen(cmd + cmd_args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            tar_out = tar.communicate()
            if tar.returncode != 0:
                output += "----------------------\nBackup of {0} failed:\n".format(source_path)
                output += str(tar_out[1])
                output += "\n----------------------\n"
    except OSError, e:
        output += "----------------------\nBackup of {0} failed:\n".format(source_path)
        output += "Error #" + str(e.errno) + ": " + e.strerror
        output += "\n----------------------\n"
        pass
    return output

def do_backup(source_directories, target_dir):
    output = ''
    for source_dir in source_directories:
        if source_dir.endswith('/*'):
            source_dir = source_dir[:-2]
            subdirs = os.listdir(source_dir)
        else:
            subdirs = [source_dir,]

        for sub in subdirs:
            source_path = os.path.join(source_dir, sub)
            target_name = slugify(source_path)

            if source_path in skip_list:
                continue

            output += backup_dir(source_path, target_dir, target_name)

    return output

output = do_backup(
        SOURCE_DIR.split(':'),
        TARGET_DIR)
if output:
    print("_...----=======[ QSBackup starting ]=======----..._")
    print(output)

