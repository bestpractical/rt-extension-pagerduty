use strict;
use warnings;

package RT::Extension::PagerDuty;

our $VERSION = '0.01';

=head1 NAME

RT-Extension-PagerDuty - Two way integration with PagerDuty

=head1 DESCRIPTION

This RT extension allows for two way integration with the PagerDuty incident
response platform.

On ticket creation in RT trigger an incident in PagerDuty. When a ticket is
acknowledged or resolved in RT update the incident in PagerDuty.

Configure a PagerDuty webhook to push noticications to RT from PagerDuty. When
a new incident is triggered in PagerDuty have it create a ticket in RT. If an
incident is acknowledged or resolved in PagerDuty update the corresponding
ticket in RT.

=head1 RT VERSION

Works with RT 5.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item C<make initdb>

Only run this the first time you install this module.

If you run this twice, you may end up with duplicate data
in your database.

If you are upgrading this module, check for upgrading instructions
in case changes need to be made to your database.

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::PagerDuty');

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

To define the interactions between RT and PagerDuty use the C<$PagerDuty> config
option. This option takes the form of:

    Set(
        $PagerDuty,
        {
            services => {
                'PagerDuty Service ID' => {
                    api_token => 'PagerDuty API Token',
                    api_user => 'PagerDuty User',
                    create_queue => 'General',
                }
            },
            queues => {
                'RT Queue Name' => {
                    service => 'PagerDuty Service ID',
                    acknowledged => 'open',
                    resolved => 'resolved',
                }
            }
        }
    );

The services section maps a PagerDuty service id to the token and user to use
for API access. The C<api_token> and C<api_user> values are required. The
optional C<create_queue> value is the RT queue name where new RT tickets should
be created if a PagerDuty incident creates a new RT ticket. C<create_queue>
defaults to the General queue if not specified. Use '*' as the PagerDuty service
id to apply to multiple PagerDuty services.

The queues section maps an RT queue name to the PagerDuty service where it should
trigger new incidents when an RT ticket is created. The C<service> value is
required and must be a PagerDuty service id. The C<acknowledged> and C<resolved>
optional values indicate what RT ticket status to use when an incident is
acknowledged or resolved on PagerDuty. If not specified they default to
acknowledged => 'open' and resolved => 'resolved'. Use '*' as the RT queue name
to apply to multiple RT queues.

To get the PagerDuty Service ID login to your PagerDuty account and go to
Services -> Service Directory. Click on the Service you want the ID for and the
the ID will be at the end of the URL. For example:

    pagerduty.com/service-directory/P3AFFQR

the Service ID is P3AFFQR.

To create an api_token login to your PagerDuty account and go to
Integrations -> API Access Keys. Click the Create New API Key button. Add a
description and click Create Key. Copy the key and paste it into the $PagerDuty
config as the api_token. You will not be able to view the key again but you can generate a new
one if you lose the key.

The api_user is the email address for a valid PagerDuty user that has access to
the PagerDuty Service you are integrating with.

=head1 Scrips

This extension will install three new Scrips that do not apply to any queues:
C<On Acknowledge PagerDuty Acknowledge>, C<On Create PagerDuty Trigger>, and
C<On Resolve PagerDuty Resolve>.

Once you have added the configuration you can apply these Scrips to the queues
you want to integrate with PagerDuty.

=head1 CUSTOM FIELDS

This extension adds two ticket custom fields: PagerDuty ID and PagerDuty URL.

When an RT ticket creates an incident on PagerDuty or an incident on PagerDuty
creates an RT ticket the custom fields are automatically filled in. The PagerDuty
URL links directly to the incident on PagerDuty.

If you would like to group the new custom fields in their own PagerDuty group
you can use the CustomFieldGroupings config option:

    Set(
        %CustomFieldGroupings,
        'RT::Ticket' => [
            'PagerDuty' => [ 'PagerDuty ID', 'PagerDuty URL' ],
        ],
    );

=head1 WEBHOOK USAGE

To call the webhook from PagerDuty:

=over 4


=item 1. Create an auth token for a user with permissions to create tickets in
the PagerDuty create queue. To create an auth token go to
Logged in as -> Settings -> Auth Tokens and create a new token.

=item 2. Go to the PagerDuty Service Integrations Webhooks

=item 3. Add a new webhook, using: C<https://your.rt.example/PagerDuty/WebHook.html>
as the webhook URL. Add a custom header with the name Authorization and value
'token #-#-abc123' where '#-#-abc123' is the value for the auth token you
created in step one. Currently the only event subscriptions supported are
incident.acknowledged, incident.resolved, and incident.triggered.

=item 4. WEBHOOK WITH $RestrictReferrer ENABLED - If the RT config setting
$RestrictReferrer is enabled then the webhook will not work without allowing it
in the config:

    Set( %ReferrerComponents,
        '/PagerDuty/WebHook.html' => 1,
    );

=item 5. The PagerDuty Send Test Event button will send a message to the webhook
but nothing will happen as a result

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-PagerDuty@rt.cpan.org">bug-RT-Extension-PagerDuty@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-PagerDuty">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-PagerDuty@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-PagerDuty

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by BPS

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
