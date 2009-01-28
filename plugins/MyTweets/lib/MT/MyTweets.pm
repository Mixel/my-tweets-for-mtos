package MT::MyTweets;

use strict;
use base qw( MT::Object );
use URI::Escape;
use Data::Dumper;
use MT::Util qw (encode_url encode_html convert_high_ascii);
__PACKAGE__->install_properties({
    column_defs => {      
        'id'            => 'integer not null auto_increment',
        'url'           => 'string(230) not null',
        'blog_id'       => 'integer',
        'search_string' => 'string(140)',
        'html'          => 'string(3000)',
        'tweets'        => 'integer',
        'title'         => 'string(256)',
    },
    audit => 0,
    indexes => {
      'url' => {
        columns => [ 'url' ],   
      },
       'id' => 1,
      'porblog' => {
        columns => ['tweets','blog_id'],   
      },
    },
    datasource => 'mytweets',
    primary_key => 'id',
});

sub class_label {
    MT->translate("My Tweets");
}
sub class_label_plural {
     MT->translate("My Tweets");
}

sub load{
  my $obj = shift;
  my ($p) = @_;
 return  $obj->SUPER::load(@_) unless ($p->{url});
 $p->{url} =   uri_escape($p->{url} ) ;
  return  $obj->SUPER::load($p);
}


sub url{
   my $obj = shift;
   my ($url_) = @_;
# We scape the url---
   if($url_){   
     $obj->search_string(_Obtener_short_urls($url_));
     $obj->SUPER::html($obj->CreaHtml($obj->busqueda_twitter()));
     return $obj->SUPER::url(uri_escape($url_)) if($url_);

   }
 # and unscape it
  $url_  = $obj->SUPER::url();
  $url_ =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
 return $url_;
}


sub search_string{
    my $obj = shift;
    my ($str_) = @_;       
    return $obj->SUPER::search_string($str_) if($str_);    
    $str_  = $obj->SUPER::search_string();
    return $str_;
}

sub _ObtenerURL{
   use LWP::UserAgent;
   my ($url) =  @_;
   my $ua = LWP::UserAgent->new();
   my $req = HTTP::Request->new('GET' => $url);
   my $res = $ua->request($req);
   return   ($res->is_success)? $res->content:'';
}

sub _Obtener_short_urls{ 
  my ($url) = @_;
  my @urls;
  push (@urls, _ObtenerURL('http://tinyurl.com/api-create.php?url=' . $url));
  push (@urls, _ObtenerURL('http://bit.ly/api?url=' . $url));
  push (@urls, _ObtenerURL('http://is.gd/api.php?longurl=' . encode_url($url)));
  return  join('+',@urls);
}

sub busqueda_twitter{
  my $obj = shift;
  my $res = _ObtenerURL('http://search.twitter.com/search.json?q=&ors=' .$obj->search_string());
  $res =~ s/\\u/\\\\u/g; #necestitamos escapar todas las \u por \\u para que jsonToObj funcione..
  $res =~ s/'/&#39;/g; #cambiamos todas las ' por su equivalente en html
  use JSON qw (jsonToObj);
  $res = jsonToObj($res);
  return $res->{results};
} 
# 
sub valida_urls{
 my $obj = shift;
  my ($res) = @_;
  my @s;

  foreach my $x (@$res){
  my $text = $x->{text};
   foreach my $u (split(/\+/,$obj->search_string)) {
     if ($text =~ m/\Q$u\E/){
        push (@s,$x);
        last;
     }
   }    
 }
 #la cantidad de tweets
 my $c = @s;
 $obj->tweets($c);
 return @s;
}
# 
sub CreaHtml{
    my $obj = shift;
    my ($res) = @_;
    my $params = plugin()->get_config_hash("blog:".$obj->blog_id);
    #los tweets para la url
    my @tweets = $obj->valida_urls($res);
  

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

1;