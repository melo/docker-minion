package My::Workers::Echo;
use Mojo::Base 'Mojolicious::Plugin';
 
sub register {
  my ($self, $app) = @_;
  $app->minion->add_task(echo => sub {
    my $job = shift;

    my $sleep = int(rand(4))+1;
    $job->note(sleep_for => $sleep);
    sleep($sleep);
    
    $job->finish({ done => $job->args, slept_for => $sleep });
  });
}
 
1;