#!/usr/bin/perl
# created by Queria Sa-Tas
# insired by http://lindesk.com/2008/06/perl-script-to-backup-mysql-databases/ (written by BinnyVA)

use POSIX qw/strftime/;
use List::Util qw/ min max /;
use YAML::Syck;
use File::Basename;
use File::Spec;

my $cfg = LoadFile(File::Spec->catdir(dirname($0), 'backup-db.cfg'));
#my $user = 'root';
#my $pass = 'cm3pr';
#my $skip_info_schema = 1;
#my $backup_dir = '/.backup/mysql/';

@databases = `mysql -u $cfg->{user} -p$cfg->{pass} -e 'show databases\\G'`;
@databases = grep(/Database: /, @databases);
$datetime = strftime "%Y%m%d-%H%M%S", localtime;
$maxlen = 0;

$pre = qr/^\s*Database:\s*/;
map {
	$_ =~ s/$pre//;
	chomp($_);
	$l = length($_);
	$maxlen = $l > $maxlen ? $l : $maxlen;
	$_;
} @databases;
$maxlen += 3;

# print $datetime." max=".$maxlen."\n";
# my $idx = 0;
# foreach my $db (@databases) {
# 	printf "%d. %s\n", ++$idx, $db;
# }
# exit 0;

$count = @databases;
print "$count databases in total.\n-------\n";

# create new backup dir
chdir($cfg->{backup_dir}) or die("cd $cfg->{backup_dir} failed!");
( mkdir($datetime) and chdir($datetime) ) or die("mkdir+chdir $datetime failed!");


foreach my $db (@databases) {
	chomp($db);
	next if ($db eq '');
	next if $cfg->{skip_info_schema} and ($db eq 'information_schema');

	$pad = $maxlen - length($db);
	print "Database '$db'" . ' ' x $pad;

	print "   dump: ";
	if( ! `mysqldump -u $cfg->{user} -p$cfg->{pass} --quick --disable-keys $db > $db.sql` ) {
		print "[done]  ";
	} else {
		print "[failed]";
	}

	print "   compress: ";
	if( ! `bzip2 -9 $db.sql` ) {
		print "[done]  ";
	} else {
		print "[failed]";
	}

	print "\n";
}

print "------------------------- end ---------------\n";

# mysql -u root -p -e 'show databases \G';
