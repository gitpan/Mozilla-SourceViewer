use strict;
use warnings FATAL => 'all';

use Test::More tests => 7;
use Mozilla::Mechanize;
use URI::file;
use File::Slurp;

BEGIN { use_ok('Mozilla::SourceViewer') };

my $url = URI::file->new_abs("t/test.html")->as_string;
my $moz = Mozilla::Mechanize->new(quiet => 1, visible => 0);

my @_last_call;
ok($moz->get($url));
is($moz->title, "Test-forms Page");

my $e = $moz->agent->{embed};
my $vs = Get_Page_Source($e);
like($vs, qr#<input type="hidden" name="dummy2" value="empty" />#);

ok($moz->get('http://www.google.com'));
is($moz->title, "Google");
$vs = Get_Page_Source($e);
like($vs, qr#</html>#);

$moz->close();
