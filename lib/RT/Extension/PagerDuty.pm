use strict;
use warnings;

package RT::Extension::PagerDuty;

our $VERSION = '0.01';

=head1 NAME

RT-Extension-PagerDuty - Two way integration with PagerDuty

=head1 DESCRIPTION

This RT extension allows for two-way integration with PagerDuty.

On ticket creation in RT, trigger an alert in PagerDuty. When a ticket is
acknowledged or resolved in RT, update the incident in PagerDuty.

Configure a PagerDuty webhook to send updates to RT from PagerDuty. When
a new incident is triggered in PagerDuty, create a ticket in RT.
If an incident is acknowledged or resolved in PagerDuty, update the
corresponding ticket in RT.

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

See below for additional configuration details.

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

This section describes how to configure RT to integrate
with your PagerDuty account and services. See the
L<PagerDuty services documentation|https://support.pagerduty.com/docs/services-and-integrations>
for details on configuring services on the PagerDuty side.

=head2 PagerDuty Webhook

PagerDuty will call a webhook provided by this extension to
send information to your RT. To allow PagerDuty to send data
to RT without a referrer, set this option in your RT configuration:

    Set( %ReferrerComponents,
        '/PagerDuty/WebHook.html' => 1,
    );

See L</PagerDuty Webhook> for details on setting up the webhook in
PagerDuty.

=head2 PagerDuty Services and RT Queues

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
optional C<create_queue> value is the RT queue where new RT tickets
should be created if a PagerDuty incident creates a new RT ticket.
C<create_queue> defaults to the General queue if not specified. Use '*' as
the C<PagerDuty Service ID> to apply to multiple PagerDuty services.

The C<queues> section maps an RT queue name to the PagerDuty service where it
should trigger new incidents when an RT ticket is created. The C<service>
value is required and must be a PagerDuty service id. The C<acknowledged> and
C<resolved> optional values indicate what RT ticket status to use when an
incident is acknowledged or resolved on PagerDuty. If not specified, they
default to acknowledged => 'open' and resolved => 'resolved'. Use '*' as the
C<RT Queue Name> to apply to multiple RT queues.

To get the C<PagerDuty Service ID>, login to your PagerDuty account and go to
Services > Service Directory. If you are creating a new service for this
integration, when you come to the "Integrations" section of the create new
service process, click "Create service without an integration". The
RT integration uses the Incidents API, as recommented by PagerDuty, and
that doesn't require a specific Integrations configuration in PagerDuty.

Click on the Service you want the ID for and
the the ID will be at the end of the URL. For example:

    pagerduty.com/service-directory/P3AFFQR

the Service ID is P3AFFQR.

To create an C<api_token>, login to your PagerDuty account and go to
Integrations > API Access Keys. Click the C<Create New API Key> button. Add
a description and click C<Create Key>. Copy the key and paste it into the
C<$PagerDuty> config as the C<api_token>. You will not be able to view the
key again but you can generate a new one if you lose the key.

The C<api_user> is the email address for a valid PagerDuty user that has
access to the PagerDuty Service you are integrating with. This is set as
the "From" for any incidents created. You can create a utility user account
in PagerDuty just for RT alerts.

=head1 RT Scrips and Custom Fields

=head2 Scrips

This extension will install three new Scrips:

=over

=item On Acknowledge PagerDuty Acknowledge

=item On Create PagerDuty Trigger

=item On Resolve PagerDuty Resolve

=back

They are not applied to any queues when they are initially installed. Edit
the scrips and click "Applies To" to select the queues that should integrate
with PagerDuty.

=head2 Custom Fields

This extension adds two ticket custom fields: C<PagerDuty ID> and
C<PagerDuty URL>.

You need to apply them to the queues that integrate with PagerDuty.

When an RT ticket creates an incident in PagerDuty, or an incident on PagerDuty
creates an RT ticket, the custom fields are automatically set to the
corresponding PagerDuty incident ID and URL. The PagerDuty URL links
directly to the incident on PagerDuty.

If you would like to group the new custom fields in their own PagerDuty group
you can use the CustomFieldGroupings configuration in RT:

    Set(
        %CustomFieldGroupings,
        'RT::Ticket' => [
            'Alerts' => [ 'PagerDuty ID', 'PagerDuty URL' ],
        ],
    );

=head1 PagerDuty Webhook

To set up the PagerDuty webhook, do the following.

=over 4

=item 1. Create an auth token in RT

Select or create an RT user that will be used for the webhook, then create an
auth token from the user admin page.

The API user must be a Privileged user. If you use a user account that is
Unprivileged, the calls to the webhook will redirect to Self Service and
not work.

The RT user will also need some rights in RT to update tickets. A typical
set of rights to grant for the API user are C<SeeQueue>, C<CreateTicket>,
C<ModifyTicket>, and C<ModifyCustomField>.

=item 2. Create the WebHook

Go to the PagerDuty Service Integrations Webhooks, add a new webhook. Use
C<https://your.rt.example/PagerDuty/WebHook.html> as the webhook URL,
replacing C<https://your.rt.example> with your real RT domain.

For Scope Type and Scope, pick Service and the service you want to
integrate with RT.

In the Event Subscriptions section, deselect all, then select the following
supported events:

=over

=item incident.acknowledged

=item incident.resolved

=item incident.triggered

=back

At the bottom of the page, click Add custom header. Add a custom header
with the name C<Authorization> and value C<token #-#-abc123> where
C<#-#-abc123> is the value of the auth token you created in step one.
Note the word "token" followed by a space before the actual token value.

The C<Send Test Event> button sends a C<ping> event and no tickets will
be created in RT.

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
