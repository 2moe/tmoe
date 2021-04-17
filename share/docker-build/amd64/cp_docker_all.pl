#!/usr/bin/env perl
$de_file = "cp_docker_de";
$arch_file = "cp_docker_file";
$result = system "./$de_file";
$result02 = system "./$arch_file";
print "$result\n$result02 \n";
exec ("date;date -u");