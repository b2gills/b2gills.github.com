package BuildWeb;
use warnings;
use strict;

use App::Cmd::Setup -app;

use YAML 'LoadFile';

sub global_opt_spec{
  my( $app ) = @_;
  return (
    [ 'build=s' => 'Build directory',
      {
        default => $app->config->{build_dir}
      }
    ]
  );
}

sub config_file{
  my($app) = @_;
  return $app->{config_file} if $app->{config_file};
  $app->{config_file} = 'config.yml';
}

sub config{
  my($app) = @_;
  return $app->{config} if $app->{config};

  $app->{config} = LoadFile $app->config_file;
}


1;
