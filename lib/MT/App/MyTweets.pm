package MT::App::MyTweets;
use strict;
use Data::Dumper;
use base 'MT::App';
use MT::Util qw (encode_url encode_html convert_high_ascii);

 our @urls;
 our $url;
sub init {
    my $app = shift;
    $app->SUPER::init(@_) or return;
    $app->{is_admin}     = 1;
     $app->add_methods(
        shorturls => \&_short_urls,
        twitter => \&_twitter_search,
    );
#     $app->{default_mode} = '';
    $app->init_core_callbacks();
}

sub init_request {
    my $app = shift;
    $app->SUPER::init_request(@_);
    $app->{requires_login} = 0;
}

sub init_core_callbacks {
    my $app = shift;
 }

sub mode_default { 
  my $app = shift;

  $url = $ENV{HTTP_REFERER} ||$app->param('url')|| die('No url :(');
#  $url = 'http://danzarrella.com/update-to-tweetsuite.html';
#  $url = encode_url($url);
#  return $url;
  my $res = todas();
#    return Dumper($res);
  return CreaHtml($res->{results},$app);
#return Dumper($fla->{results}); #$fla->{results}
}

sub busqueda_twitter{
  my $url2 = 'http://search.twitter.com/search.json?q=&ors=' . creaBusqueda() ;
  return ObtenerURL($url2);
}


sub todas{
  my $res = busqueda_twitter();
  $res =~ s/\\u/\\\\u/g; #necestitamos escapar todas las \u por \\u para que jsonToObj funcione..
  $res =~ s/'/&#39;/g; #cambiamos todas las ' por su equivalente en html
  use JSON qw (jsonToObj);
  $res = jsonToObj($res);
  return $res;
} 
sub Obtener_short_urls{
  push (@urls, ObtenerURL('http://tinyurl.com/api-create.php?url=' . $url));
  push (@urls, ObtenerURL('http://bit.ly/api?url=' . $url));
  push (@urls, ObtenerURL('http://is.gd/api.php?longurl=' . encode_url($url)));
}

sub creaBusqueda{
  Obtener_short_urls();
  return  join('+',@urls);
}

sub ObtenerURL{
  use LWP::UserAgent;
  my ($url) =  @_;
  my $ua = LWP::UserAgent->new();
  my $req = HTTP::Request->new('GET' => $url);
  my $res = $ua->request($req);
  return $res->content  if ($res->is_success);
  return '';
}

sub valida_urls{
  my ($res) = @_;
  my @s;
  foreach my $x (@$res){
  my $text = $x->{text};
   foreach my $u (@urls) {
     if ($text =~ m/\Q$u\E/){
        push (@s,$x);
        last;
     }
   }    
 }
 return @s;
}

sub CreaHtml{
my ($res,$app) = @_;
my $params = plugin()->get_config_hash("blog:".$app->param('b'));
my @tweets = valida_urls($res);
# return Dumper(@tweets);    

my $foto;
my $texto;



my $salida =   "obj = document.getElementById('mytweets');obj.innerHTML = '";
return $salida.'<h2 class="tweetscount">No TweetBacks yet</h2>' ."';" unless(@$res);
my $savatar =  ' style="float:left;margin:10px"' ;
my $stweet =  ' style="clear:both"';

  if($params->{tbstyling} eq "false"){
    $savatar = '';
    $stweet =  '';
  }
  return $salida . '<h2 class="tweetscount">' . @tweets . ' TweetBacks</h2>'  ."';" if($params->{tbcountonly} eq "true");
  $salida .= '<h2 class="tweetscount">' . @tweets . ' TweetBacks</h2>'  if($params->{tbcount} eq "true");

  $texto  =  '<div class="tweet-user"><a href="http://twitter/__USUARIO__"><strong>__USUARIO__</strong></div></a>';
  $texto .=  '<div class="tweet-text">__TEXTO__<div class="tweet-time"> __TIME__</div></div><br />' ; 
  $foto   =  '<div class="tweet-avatar"'.$savatar.'><img src="__AVATAR__" alt="__USUARIO__" /> </div>' if($params->{tbavatar} eq "true");
  my $open=  '<div class="tweet"'.$stweet.'">';
  my $i =0;
  my $max = $params->{tbmax}||10;
  $max = ($max < @tweets )?$max:@tweets;
  foreach my $x (@tweets){
    my $aux =  $open . $foto . $texto . '</div>'; 
#      my $texto = MT::I18N::encode_utf8($x->{text}); #, 'utf8', undef);
    my $texto = convert_high_ascii($x->{text});	
    $aux =~ s/__TEXTO__/$texto/;
    $aux =~ s/__TIME__/$x->{created_at}/;
    $aux =~ s/__AVATAR__/$x->{profile_image_url}/;
    $aux =~ s/__USUARIO__/$x->{from_user}/g;
    $salida .= $aux;
    $i +=1;  
    return $salida . "';" if ($i >= $max);   
  }
  return $salida . "';" 
}


sub plugin {
    return MT->component('MyTweets');
}
#### debug modes..
### Tal vez estos modos se puedan utilizar para otros propositos.... el tiempo lo dira
sub _short_urls{
 my $app = shift;
 $url = $ENV{HTTP_REFERER} ||$app->param('url')|| die('No url :('); 
 Obtener_short_urls();
 
 return join('<br />',@urls);
}

sub _twitter_search{
 my $app = shift;
 $url = $ENV{HTTP_REFERER} ||$app->param('url')|| die('No url :('); 
 return  busqueda_twitter();
}
1;