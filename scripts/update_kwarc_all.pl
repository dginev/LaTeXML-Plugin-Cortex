#!/usr/bin/perl -w

# We assume script user has their public keys added to all relevant machines' ~/.ssh/authorized_keys 
# (So far Deyan is the only one)

my $update_all_cmd = "hostname && ".
"cd ~/LaTeXML; git pull; cpanm .;".
"cd ~/LaTeXML-Plugin-Cortex; git pull; cpanm .;";

my $home_update = $update_all_cmd;
my $cortex_update = "ssh deyan\@cortex.mathweb.org 'source /home/deyan/.bashrc;$update_all_cmd'";
my $beryl_update="ssh deyan\@beryl.eecs.jacobs-university.de 'source /home/deyan/.bashrc;$update_all_cmd'";
my $hulk_update="ssh deyan\@cortex.mathweb.org \"ssh dginev\@hulk.clamv.jacobs-university.de \"ssh node101 'source /direct/home/dginev/.cshrc;$update_all_cmd'\"\"";

# Threads in a perl script? Hah! Let's fork it like it's 1989
if (fork()) {
  print STDERR `$cortex_update`,"\n\n";
} elsif (fork()) {
  print STDERR `$beryl_update`,"\n\n";
} elsif (fork()) {
  print STDERR `$hulk_update`,"\n\n";
} else {
  print STDERR `$home_update`,"\n\n";
}