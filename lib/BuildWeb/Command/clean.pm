package BuildWeb::Command::clean;
use strict;
use warnings;

use BuildWeb -command;

sub opt_spec {
  my( $class, $app ) = @_;
  return (
    $app->global_opt_spec,
  );
}

sub validate_args {
  my( $self, $opt, $args ) = @_;
  my $global = $self->app->global_options;
  %$opt = (%$opt,%$global);
}

sub execute {
  my( $self, $opt, $args ) = @_;
  require File::Remove;
  
  if( -e $opt->build ){
    my($deleted) = File::Remove::remove(\1,$opt->build);
    
    if( $deleted ){
      print "Deleted $deleted\n";
    }
  }
}
1;
