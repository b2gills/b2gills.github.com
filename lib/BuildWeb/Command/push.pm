package BuildWeb::Command::push;
use strict;
use warnings;

use BuildWeb -command;

sub opt_spec {
  my( $class, $app ) = @_;
  my $default = $app->config->{push};
  return (
    [ 'to=s@', 'refs to push',
      {
        default => $default
      }
    ]
  );
}

sub execute {
  my( $self, $opt, $args ) = @_;
  my $push = $opt->to;
  return unless Scalar::Util::reftype($push) eq 'ARRAY';
  
  require Git::Wrapper;
  
  my $git  = Git::Wrapper->new('.');

  # push everything on remote branch
  for my $remote ( @$push ) { 
    print "pushing to $remote\n";
    my @remote = split(/\s+/,$remote);
    print STDERR "$_\n" for $git->push( @remote );
  }
}
1;
