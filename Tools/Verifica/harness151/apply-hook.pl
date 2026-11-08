# Inserts the temporary hooks of the harness (issues 151 and 156) in the tree of the current directory.
# Used only to produce hook151.patch; the patch is what gets applied with "git apply".
use strict;
use warnings;

sub slurp { my ($f) = @_; open(my $h, '<:raw', $f) or die "$f: $!"; local $/; my $t = <$h>; close $h; return $t; }
sub spit { my ($f, $t) = @_; open(my $h, '>:raw', $f) or die "$f: $!"; print $h $t; close $h; }

foreach my $dpr (qw(Doom32 Heretic32 Hexen32 Strife32 GLDoom32)) {
  my $t = slurp("$dpr.dpr");
  $t =~ s/(  i_system in 'Base\\i_system\.pas',(\r?\n))/$1  Harness151 in 'Tools\\Verifica\\harness151\\Harness151.pas',$2/ or die "$dpr.dpr";
  spit("$dpr.dpr", $t);
}

my $loader = 'Base/DelphiDoom.Engine.Level.Loader.pas';
my $t = slurp($loader);
$t =~ s/(\r?\nimplementation\r?\n\r?\nuses\r?\n  System\.SysUtils,(\r?\n))/$1  Harness151,$2/ or die 'loader uses';
$t =~ s/(\r?\n  FinishLevel;(\r?\n))(end;)/$1  V151_AfterLevel(LMapName);$2$3/ or die 'loader call';
spit($loader, $t);

my $wad = 'Base/w_wad.pas';
$t = slurp($wad);
$t =~ s/(\r?\nimplementation\r?\n\r?\nuses\r?\n  i_system,(\r?\n))/$1  Harness151,$2/ or die 'wad uses';
$t =~ s/(procedure W_ReadLump\(const lump: integer; dest: pointer\);\r?\nbegin(\r?\n))(?=  if lump >= numlumps)/$1  V151_TraceLump(lump);$2/ or die 'wad trace';
spit($wad, $t);
print "ok\n";
