package BuildWeb::Command::commit;
use strict;
use warnings;

use String::Formatter method_stringf => {
  -as   => 'message_format',
  codes => {
    d => sub {
      my($self,$method_str) = @_;
      my($method,$format) =
        $method_str =~ /^( [^()]+ )
        (?:
          [(] ( (?:\\{2}|\\[()]|[^()]+)++ ) [)]
        )?
      /x;
      die "invalid format $method_str" unless $method;
      no warnings 'uninitialized';
      $format =~ s(\\(\\)|\\){$1}g;
      require DateTime;
      DateTime->now->$method($format);
    },
  },
};

use BuildWeb -command;

# App::Cmd methods

sub opt_spec {
  my( $class, $app ) = @_;
  my $defaults = $app->config->{commit};
  return (
    $app->global_opt_spec,
    [ 'branch=s','Commit to Branch',
      { default => $defaults->{branch} || 'master' }
    ],
    [ 'message=s','Commit message',
      { default => $defaults->{message} || 'Built on %{ymd}d' }
    ],
  );
}

sub validate_args {
  my( $self, $opt, $args ) = @_;
  my $global = $self->app->global_options;
  %$opt = (%$opt,%$global);
  $self->{opt} = $opt;
}

sub execute{
  my( $self, $opt, $args ) = @_;

  my $message = $self->message;
  print commit_build( $opt->build, $opt->branch, $message ),"\n";
}

# our methods

sub message {
  my( $self ) = @_;
  message_format( $self->opt->message, $self );
}
sub opt{ $_[0]->{opt} }



sub verify_rev_list{
  my($git,$verify) = @_;
  eval{
    $git->rev_parse(
      { q=>1, verify => 1 }, $verify
    )
  }
}
sub commit_build {
  my ( $build_dir, $branch, $message ) = @_;

  return unless $branch and $message;

  require Cwd;
  require File::Spec;
  require File::Temp;
  require Git::Wrapper;

  our $CWD = Cwd::getcwd;

  my $tmp_dir = File::Temp->newdir( CLEANUP => 1 ) ;
  my $src     = Git::Wrapper->new('.');

  my $tree = do {
    # don't overwrite the user's index
    local $ENV{GIT_INDEX_FILE}
      = File::Spec->catfile( $tmp_dir, "temp_git_index" );

    local $ENV{GIT_DIR}
      = File::Spec->catfile( $CWD,     '.git' );

    local $ENV{GIT_WORK_TREE}
      = $build_dir;

    local $CWD = $build_dir;

    my $write_tree_repo = Git::Wrapper->new('.');

    $write_tree_repo->add({ v => 1, force => 1}, '.' );
    ($write_tree_repo->write_tree)[0];
  };

  if(
    verify_rev_list($src,$branch)
    and not $src->diff( { 'stat' => 1 }, $branch, $tree )
  ){
    return 'No difference detected';
  }

  my @parents = grep {
    verify_rev_list($src,$_)
  } $branch, 'HEAD';

  my @commit;
  {
    # Git::Wrapper doesn't read from STDIN, which is
    # needed for commit-tree, so we have to everything
    # ourselves
    #
    my ($fh, $filename) = File::Temp::tempfile();
    $fh->autoflush(1);
    print {$fh} $message;
    $fh->close;

    my @args=('git', 'commit-tree', $tree, map { ( -p => $_ ) } @parents);
    push @args,'<'.$filename;
    my $cmdline=join(' ',@args);
    @commit=qx/$cmdline/;

    chomp(@commit);
  }

  $src->update_ref( 'refs/heads/' . $branch, $commit[0] );
  return "refs/heads/$branch $commit[0]";
}
1;
