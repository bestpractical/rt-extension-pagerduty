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

To allow PagerDuty to send data to RT without a referrer:

    Set( %ReferrerComponents,
        '/PagerDuty/WebHook.html' => 1,
    );

To define the interactions between RT and PagerDuty:

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

The C<services> section maps a PagerDuty service id to the token and user to
use for API access. The C<api_token> and C<api_user> values are required. The
optional C<create_queue> value is the RT queue name where new RT tickets
should be created if a PagerDuty incident creates a new RT ticket.
C<create_queue> defaults to the General queue if not specified. Use '*' as
the C<PagerDuty Service ID> to apply to multiple PagerDuty services.

The C<queues> section maps an RT queue name to the PagerDuty service where it
should trigger new incidents when an RT ticket is created. The C<service>
value is required and must be a PagerDuty service id. The C<acknowledged> and
C<resolved> optional values indicate what RT ticket status to use when an
incident is acknowledged or resolved on PagerDuty. If not specified they
default to acknowledged => 'open' and resolved => 'resolved'. Use '*' as the
C<RT Queue Name> to apply to multiple RT queues.

To get the C<PagerDuty Service ID> login to your PagerDuty account and go to
Services -> Service Directory. Click on the Service you want the ID for and
the the ID will be at the end of the URL. For example:

    pagerduty.com/service-directory/P3AFFQR

the Service ID is P3AFFQR.

To create an C<api_token> login to your PagerDuty account and go to
Integrations -> API Access Keys. Click the C<Create New API Key> button. Add
a description and click C<Create Key>. Copy the key and paste it into the
C<$PagerDuty> config as the C<api_token>. You will not be able to view the
key again but you can generate a new one if you lose the key.

The C<api_user> is the email address for a valid PagerDuty user that has
access to the PagerDuty Service you are integrating with.

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 Scrips

This extension will install three new Scrips that do not apply to any queues:
C<On Acknowledge PagerDuty Acknowledge>, C<On Create PagerDuty Trigger> and
C<On Resolve PagerDuty Resolve>.

You need to apply them to all the queues that integrate with PagerDuty.

=head1 Custom fields

This extension adds two ticket custom fields: C<PagerDuty ID> and C<PagerDuty
URL>.

You need to apply them to all the queues that integrate with PagerDuty.

When an RT ticket creates an incident on PagerDuty or an incident on PagerDuty
creates an RT ticket the custom fields are automatically filled in. The
PagerDuty URL links directly to the incident on PagerDuty.

If you would like to group the new custom fields in their own PagerDuty group
you can use the CustomFieldGroupings config option:

    Set(
        %CustomFieldGroupings,
        'RT::Ticket' => [
            'PagerDuty' => [ 'PagerDuty ID', 'PagerDuty URL' ],
        ],
    );

=head1 Set up a webhook in PagerDuty

=over 4

=item 1. Create an auth token in RT

Select or create an RT user that will be used for the webhook, then create an
auth token from the user admin page.

Note that the user needs to be able to create and update tickets, usually you
can grant C<SeeQueue>, C<CreateTicket> and C<ModifyTicket> rights to all the
queues that integrate with PagerDuty.

=item 2. Create the WebHook

Go to the PagerDuty Service Integrations Webhooks, add a new webhook, use
C<https://your.rt.example/PagerDuty/WebHook.html> as the webhook URL, note
that you need to replace C<https://your.rt.example> with your real RT
instance.

Add a custom header with the name C<Authorization> and value
C<token #-#-abc123> where C<#-#-abc123> is the value of the auth token you
created in step one. Currently the only event subscriptions supported are
C<incident.acknowledged>, C<incident.resolved> and C<incident.triggered>.

Note that the C<Send Test Event> button sends a C<ping> event, no tickets will
be created.

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
