#!/usr/bin/perl -w

# We assume script user has their public keys added to all relevant machines' ~/.ssh/authorized_keys 
# (So far Deyan is the only one)

my $update_all_cmd = "echo STARTING; hostname; ".
"cd ~/LaTeXML; git stash; git pull --rebase; git stash pop; cpanm . --notest; ".
"cd ~/LaTeXML-Plugin-Cortex; git stash; git pull --rebase; git stash pop; cpanm .; ".
"echo ENDING; hostname;";

my $home_update = $update_all_cmd;
$home_update =~ s/\\\$/\$/g;
my $cortex_update = "ssh deyan\@cortex.mathweb.org 'source /home/deyan/.bashrc;$update_all_cmd'";
my $beryl_update="ssh deyan\@beryl.eecs.jacobs-university.de 'source /home/deyan/.bashrc;$update_all_cmd'";
my $hulk_update="ssh deyan\@cortex.mathweb.org \"ssh dginev\@10.70.2.212 \\\"ssh node101 'source /direct/home/dginev/.cshrc;$update_all_cmd'\\\"\"";

# Threads in a perl script? Hah! Let's fork it like it's 1989
if (my $pid_cortex = fork()) {
  print STDERR `$cortex_update`,"\n\n";
  waitpid($pid_cortex, 0); 
} elsif (my $pid_beryl = fork()) {
  print STDERR `$beryl_update`,"\n\n";
  waitpid($pid_beryl, 0);
} elsif (my $pid_hulk = fork()) {
  print STDERR `$hulk_update`,"\n\n";
  waitpid($pid_hulk, 0);
} else {
  print STDERR `$home_update`,"\n\n";
}