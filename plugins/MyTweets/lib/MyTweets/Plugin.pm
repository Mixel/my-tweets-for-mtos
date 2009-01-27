# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>
 
####
#### MyTweets for MT
#### Copyright 2008 Mixel Adm
#### http://mixelandia.com
 
package MyTweets::Plugin;
use strict;
 
use base 'MT::Plugin';
use MT::Util qw (encode_url);
 
our $tb;

sub tb{
  return $tb if ($tb);
  my ($ctx,$args) = @_;
 debug('init');  
  my $blog_id = $ctx->stash('blog_id') or return "";
  my $ruta  = ruta_a_mt($ctx);
  $tb = '<div id="mytweets"></div>';
  $tb .= "<script> function tbjs(){";
  $tb .= "s_ = document.createElement('script');";
#   $tb .= "s_.setAttribute('type','text/javascript');";
  $tb .= "s_.setAttribute('src','". $ruta .'mt-tweets.cgi?b='.$blog_id."');";
  $tb .= "document.getElementsByTagName('head')[0].appendChild(s_);}";
  $tb .= "setTimeout('tbjs()',1)</script>";
  return $tb;
 
}

sub tbs{
 my ($ctx,$args) = @_;

 my $blog_id = $ctx->stash('blog_id') or return "";
 my $params = plugin()->get_config_hash("blog:$blog_id");
 my $x;
 my $salida = 'Nada aun :(';
 $x= '?max=' . $params->{tbmaxstats} if ($params->{tbmaxstats} ne "No limit");
 $salida =~ s/__EXTRA__/$x/;
 return $salida;
}
 
sub tbconfig{
  my $app = shift;
  my $blog_id = $app->{query}->param('blog_id') or return $app->error("No blog selected");
  my $plugin = plugin();
  my $params = $plugin->get_config_hash("blog:$blog_id");
  $params->{tbmax_} = maxs($params->{tbmax});
  $params->{tbmaxstats_} = maxs($params->{tbmaxstats});
  $params->{magic_token} = $app->make_magic_token;
  $params->{saved} = $app->{query}->param('saved');
  my $tmpl = $plugin->load_tmpl('config.tmpl') ;
  return $app->build_page( $tmpl,$params ) or $app->error('Error loading MyTweets config');
}
 
sub tbsave{
my $app = shift;
my $blog_id = $app->{query}->param('blog_id') or return $app->error("No blog selected");
my $plugin = plugin();
   $app->validate_magic() or return $app->error("Sory");
  foreach my $key (qw (tbmax tbavatar tbcount tbstats tbblockedusers tbcountonly tbstyling tbmaxstats)){
    $plugin->set_config_value($key, $app->{query}->param($key),"blog:$blog_id");
  }
  $app->add_return_arg( blog_id => $blog_id );
  $app->add_return_arg( __mode => 'mytweets_config' );
  $app->add_return_arg( saved => 1 );
  return $app->call_return;
}
#this sub makes the array for the selected templates.
sub maxs{
 my ($max) = @_;
 my @s;
 foreach my $x (1..10){
   push(@s,{key=> $x, selected => ($x eq $max)});
 }
 return \@s;
}
 
sub ruta_a_mt{
 my ($ctx) = @_;
my $ruta = $ctx->{config}->CGIPath;
    #codigo de MTOS para verificar si cgipath empieza en / y si es el caso, le agregamos la ruta del blog
    if ($ruta =~ m!^/!) {        
        if (my $blog = $ctx->stash('blog')) {
            my ($blog_domain) = $blog->archive_url =~ m|(.+://[^/]+)|;
            $ruta = $blog_domain . $ruta;
        }
    }
  if ($ruta !~ m!/$!) {   $ruta .= '/';}
  return $ruta;
}

sub plugin {
    return MT->component('MyTweets');
}
 
sub debug(){
 my ($msg) = @_;
 MT->log({message=>$msg});
}

 
1;