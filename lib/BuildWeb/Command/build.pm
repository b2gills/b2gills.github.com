package BuildWeb::Command::build;
use strict;
use warnings;

use BuildWeb -command;

use YAML 'LoadFile';

sub opt_spec {
  my( $class, $app ) = @_;
  my $default = $app->config->{template};
  return (
    $app->global_opt_spec,
    [ 'tt=s' => 'Template Toolkit base directory',
      { default => $default->{base} || 'tt' },
    ],
    [ 'data=s' => 'Data file',
      { default => $default->{data} || 'data.yml' }
    ],
  );
}

sub validate_args {
  my( $self, $opt, $args ) = @_;
  my $global = $self->app->global_options;
  %$opt = (%$opt,%$global);
}

sub list_tt_files{
  my( $base ) = @_;

  require File::Spec;
  require File::Find;

  my $path = File::Spec->rel2abs($base);

  my @list;
  File::Find::find( {
    no_chdir => 1,
    preprocess => sub{
      if( $File::Find::dir eq $path ){
        return grep {
          $_ ne 'inc'
        } @_;
      }
      return @_;
    },
    wanted => sub{
      if( -f ){
        push @list, File::Spec->abs2rel($_,$path);
      }
    },
  }, $path );

  return @list;
}

sub execute {
  my( $self, $opt, $args ) = @_;

  require File::Spec;
  require Template;

  my $path = $opt->tt;
  my @list = list_tt_files(
    File::Spec->catdir($path,'html')
  );

  my $process_path = File::Spec->catfile('inc','html.tt');
  my $output_path = $opt->build;

  my $data = $opt->data;
  if( $data && !ref $data ){
    $data = LoadFile($data);
  }

  my $tt = Template->new(
    INCLUDE_PATH => $path,
    PROCESS => $process_path,
    OUTPUT_PATH => $output_path,
    VARIABLES  => $data,
  );

  for my $template( @list ){
    my $out = $template;
    $out =~ s/[.]tt2?$/.html/;

    my $input_path  = File::Spec->catdir( $process_path, $template );
    my $output_path = File::Spec->catdir( $output_path, $out );
    print "$input_path    =>    $output_path\n";

    $tt->process(
      File::Spec->catfile('html',$template),
      undef,
      $out,
    ) or die $tt->error, "\n";
  }
}
1;
