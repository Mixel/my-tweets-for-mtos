package MT::MyTweets;

use strict;
use base qw( MT::Object );
use URI::Escape;

__PACKAGE__->install_properties({
    column_defs => {      
        'url'           => 'string(400) not null',
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
      'porblog' => {
        columns => ['tweets','blog_id'],   
      }
    'id' => 1,
    },
    datasource => 'mytweets',
    primary_key => 'url',
});