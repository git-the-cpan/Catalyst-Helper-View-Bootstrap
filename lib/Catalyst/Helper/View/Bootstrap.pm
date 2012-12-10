package Catalyst::Helper::View::Bootstrap;

our $VERSION = '0.0001';
$VERSION = eval $VERSION;

use strict;
use File::Spec;

sub mk_compclass {
    my ( $self, $helper, @args ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
    $self->mk_templates( $helper, @args );
}

sub mk_templates {
    my ( $self, $helper ) = @_;
    my $base = $helper->{base},;
    my $ldir = File::Spec->catfile( $base, 'root', 'lib' );
    my $sdir = File::Spec->catfile( $base, 'root', 'src' );

    $helper->mk_dir($ldir);
    $helper->mk_dir($sdir);

    my $dir = File::Spec->catfile( $ldir, 'config' );
    $helper->mk_dir($dir);

    foreach my $file (qw( main url )) {
        $helper->render_file( "config_$file",
            File::Spec->catfile( $dir, $file ) );
    }

    $dir = File::Spec->catfile( $ldir, 'site' );
    $helper->mk_dir($dir);

    foreach my $file (qw( wrapper layout html header footer sidemenu )) {
        $helper->render_file( "site_$file",
            File::Spec->catfile( $dir, $file ) );
    }

    foreach my $file (qw( welcome.tt2 message.tt2 error.tt2 ttsite.css )) {
        $helper->render_file( $file, File::Spec->catfile( $sdir, $file ) );
    }

}

=head1 NAME

Catalyst::Helper::View::Bootstrap - Helper for Twitter Bootstrap and TT view which builds a skeleton web site

=head1 SYNOPSIS

# use the helper to create the view module and templates

    $ script/myapp_create.pl view HTML Bootstrap

# add something like the following to your main application module

    sub message : Global {
        my ( $self, $c ) = @_;
        $c->stash->{template} = 'message.tt2';
        $c->stash->{message}  ||= $c->req->param('message') || 'No message';
    }

    sub default : Private {
        my ( $self, $c ) = @_;
        $c->stash->{template} = 'welcome.tt2';
    }

    sub end : Private { # Or use Catalyst::Action::RenderView
        my ( $self, $c ) = @_;
        $c->forward( $c->view('HTML') );
    }

=head1 DESCRIPTION

This helper module creates a TT View module.  It goes further than
Catalyst::Helper::View::TT in that it additionally creates a simple
set of templates to get you started with your web site presentation.

It creates the templates in F<root/> directory underneath your
main project directory.  In here two further subdirectories are
created: F<root/src> which contains the main page templates, and F<root/lib>
containing a library of other template components (header, footer,
etc.) that the page templates use.

The view module that the helper creates is automatically configured
to locate these templates.

It sets character encoding to utf-8 and it delivers HTML5 pages.


=head2 Default Rendering

To render a template the following process is applied:

The configuration template F<root/lib/config/main> is rendered. This is
controlled by the C<PRE_PROCESS> configuration variable set in the controller
generated by Catalyst::Helper::View::Bootstrap. Additionally, templates referenced by
the C<PROCESS> directive will then be rendered.

Next, the template defined by the C<WRAPPER> config variable is called. The default
wrapper template is located in F<root/lib/site/wrapper>. The wrapper template
passes files with C<.css/.js/.txt> extensions through as text OR processes
the templates defined after the C<WRAPPER> directive: C<site/html> and C<site/layout>.

Based on the default value of the C<WRAPPER> directive in F<root/lib/site/wrapper>,
the following templates are processed in order:

=over 4

=item * F<root/src/your_template.tt2>

=item * F<root/lib/site/footer>

=item * F<root/lib/site/header>

=item * F<root/lib/site/sidemenu>

=item * F<root/lib/site/layout>

=item * F<root/lib/site/html>

=back

Finally, the rendered content is returned to the bowser.

=head1 METHODS

=head2 mk_compclass

Generates the component class.

=head2 mk_templates

Generates the templates.

=cut

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::View::TT>, L<Catalyst::Helper>,
L<Catalyst::Helper::View::TT>

=head1 AUTHOR

Ferruccio Zamuner <nonsolosoft@diff.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config({
    INCLUDE_PATH => [
        [% app %]->path_to( 'root', 'src' ),
        [% app %]->path_to( 'root', 'lib' )
    ],
    PRE_PROCESS  => 'config/main',
    WRAPPER      => 'site/wrapper',
    ERROR        => 'error.tt2',
    TIMER        => 0,
    render_die   => 1,
});

=head1 NAME

[% class %] - Catalyst TT Twitter Bootstrap View

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Catalyst TTSite View.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__config_main__
[% USE Date;
   year = Date.format(Date.now, '%Y');
-%]
[% TAGS star -%]
[% # config/main
   #
   # This is the main configuration template which is processed before
   # any other page, by virtue of it being defined as a PRE_PROCESS
   # template.  This is the place to define any extra template variables,
   # macros, load plugins, and perform any other template setup.

   IF Catalyst.debug;
     # define a debug() macro directed to Catalyst's log
     MACRO debug(message) CALL Catalyst.log.debug(message);
   END;

   # define a data structure to hold sitewide data
   site = {
     title     => 'Catalyst::View::Bootstrap Example Page',
     copyright => '[* year *] Your Name Here',
   };

   # load up any other configuration items
   PROCESS config/url;

   # set defaults for variables, etc.
   DEFAULT
     message = 'There is no message';

-%]
__config_url__
[% TAGS star -%]
[% base = Catalyst.req.base;

   site.url = {
     base    = base
     home    = "${base}welcome"
     message = "${base}message"
   }
-%]
__site_wrapper__
[% TAGS star -%]
[% IF template.name.match('\.(css|js|txt)');
     debug("Passing page through as text: $template.name");
     content;
   ELSE;
     debug("Applying HTML page layout wrappers to $template.name\n");
     content WRAPPER site/html + site/layout;
   END;
-%]
__site_html__
[% TAGS star -%]
<!DOCTYPE HTML>
<html>
 <head>
  <title>[% template.title or site.title %]</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.2.2/css/bootstrap-combined.min.css" rel="stylesheet">
  <meta http-equiv="Content-Type" content="text/html;charset=utf-8" >

  <style type="text/css">
body {
padding-top: 60px;
padding-bottom: 40px;
}
.sidebar-nav {
padding: 9px 0;
}
[% PROCESS ttsite.css %]
  </style>
 </head>
 <body>
[% content %]
 <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js"></script>
 <script type="text/javascript" src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.2.2/js/bootstrap.min.js"></script>
 </body>
</html>
__site_layout__
[% TAGS star -%]
[% PROCESS site/header %]

<div class="container-fluid">
[% content %]

<div id="footer">[% PROCESS site/footer %]</div>
</div><!-- container-fluid -->
__site_header__
[% TAGS star -%]
<!-- BEGIN site/header -->
<div class="navbar navbar-inverse navbar-fixed-top">
      <div class="navbar-inner">

        <div class="container-fluid">
          <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </a>
          <a class="brand" href="#">[% template.title or site.title %]</a>
          <div class="nav-collapse collapse">

            <p class="navbar-text pull-right">
              Logged in as <a href="#" class="navbar-link">Username</a>
            </p>
            <ul class="nav">
              <li class="active"><a href="#">Home</a></li>
              <li><a href="#about">About</a></li>
              <li><a href="#contact">Contact</a></li>

            </ul>
          </div><!--/.nav-collapse -->
        </div>
      </div>
</div>
<!-- END site/header -->
__site_sidemenu__
[% TAGS star -%]
          <div class="well sidebar-nav">
            <ul class="nav nav-list">
              <li class="nav-header">Sidebar</li>
              <li class="active"><a href="#">Link</a></li>
              <li><a href="#">Link</a></li>
              <li><a href="#">Link</a></li>
              <li><a href="#">Link</a></li>

              <li class="nav-header">Sidebar</li>
              <li><a href="#">Link</a></li>
              <li><a href="#">Link</a></li>
              <li><a href="#">Link</a></li>
              <li><a href="#">Link</a></li>
              <li><a href="#">Link</a></li>

              <li><a href="#">Link</a></li>
              <li class="nav-header">Sidebar</li>
              <li><a href="#">Link</a></li>
              <li><a href="#">Link</a></li>
              <li><a href="#">Link</a></li>
            </ul>

          </div><!--/.well -->
__site_footer__
[% TAGS star -%]
<!-- BEGIN site/footer -->
      <div class="row-fluid">
       <div class="span4">
         <div id="copyright">&copy; [% site.copyright %]</div>
       </div>
      </div>
<!-- END site/footer -->
__welcome.tt2__
[% TAGS star -%]
[% META title = 'Catalyst/Boostrap TT View' %]
      <div class="row-fluid">
        <div class="span3">
         [% PROCESS site/sidemenu %]
        </div><!--/span-->
        <div class="span9">
          <div class="hero-unit">
            <h1>Welcome to Catalyst world!</h1>
            <p>Yay!  You're looking at a page generated by the Catalyst::View::TT 
  plugin module and <a href="http://twitter.github.com/bootstrap/">Twitter Bootstrap</a>.<br>
You can use the power of <a href="http://www.template-toolkit.org/">Template Toolkit 2</a> and the look and features of Bootstrap CSS.
This is a template for a simple marketing or informational website. 
It includes a large callout called the hero unit and three supporting pieces of content. Use it as a starting point to create something more unique.</p>
            <p><a class="btn btn-primary btn-large">Learn more &raquo;</a></p>

          </div>
          <div class="row-fluid">
            <div class="span4">
              <h2>This is only a sample</h2>
              <p>You can change this page</p>
              <p><a class="btn" href="#">View details &raquo;</a></p>
            </div><!--/span-->

            <div class="span4">
              <h2>Heading</h2>
              <p>Donec id elit non mi porta gravida at eget metus. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Etiam porta sem malesuada magna mollis euismod. Donec sed odio dui. </p>
              <p><a class="btn" href="#">View details &raquo;</a></p>
            </div><!--/span-->
            <div class="span4">
              <h2>Heading</h2>

              <p>Donec id elit non mi porta gravida at eget metus. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Etiam porta sem malesuada magna mollis euismod. Donec sed odio dui. </p>
              <p><a class="btn" href="#">View details &raquo;</a></p>
            </div><!--/span-->
          </div><!--/row-->
          <div class="row-fluid">
            <div class="span4">
              <h2>Heading</h2>

              <p>Donec id elit non mi porta gravida at eget metus. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Etiam porta sem malesuada magna mollis euismod. Donec sed odio dui. </p>
              <p><a class="btn" href="#">View details &raquo;</a></p>
            </div><!--/span-->
            <div class="span4">
              <h2>Heading</h2>
              <p>Donec id elit non mi porta gravida at eget metus. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Etiam porta sem malesuada magna mollis euismod. Donec sed odio dui. </p>
              <p><a class="btn" href="#">View details &raquo;</a></p>

            </div><!--/span-->
            <div class="span4">
              <h2>Heading</h2>
              <p>Donec id elit non mi porta gravida at eget metus. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Etiam porta sem malesuada magna mollis euismod. Donec sed odio dui. </p>
              <p><a class="btn" href="#">View details &raquo;</a></p>
            </div><!--/span-->
          </div><!--/row-->

        </div><!--/span-->
      </div><!--/row-->
__message.tt2__
[% TAGS star -%]
[% META title = 'Catalyst/TT View!' %]
<p>
  Yay!  You're looking at a page generated by the Catalyst::View::TT
  plugin module and Twitter Bootstrap.
</p>
<p>
  We have a message for you: <span class="message">[% message %]</span>.
</p>
<p>
  Why not try updating the message?  Go on, it's really exciting, honest!
</p>
<form action="[% site.url.message %]"
      method="POST" enctype="application/x-www-form-urlencoded">
 <input type="text" name="message" value="[% message %]" />
 <input type="submit" name="submit" value=" Update Message "/>
</form>
__error.tt2__
[% TAGS star -%]
[% META title = 'Catalyst/TT Error' %]
<p>
  An error has occurred.  We're terribly sorry about that, but it's
  one of those things that happens from time to time.  Let's just
  hope the developers test everything properly before release...
</p>
<p>
  Here's the error message, on the off-chance that it means something
  to you: <span class="error">[% error %]</span>
</p>
__ttsite.css__
[% TAGS star %]

.error {
    color: #F11;
}
