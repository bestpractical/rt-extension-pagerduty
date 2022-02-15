package RT::Condition::OnAcknowledge;

use strict;
use warnings;
use base 'RT::Condition';

sub IsApplicable {
    my $self = shift;

    my $txn = $self->TransactionObj;

    # only applicable if status was changed from initial status
    return 0
        unless $self->TicketObj->LifecycleObj->IsInitial( $txn->OldValue );

    return 1;
}

1;
