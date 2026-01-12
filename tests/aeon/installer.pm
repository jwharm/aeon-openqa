# Copyright 2014-2018 SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

use Mojo::Base 'basetest';
use testapi;

sub run {
    my $encryption_passphrase = 'the encryption passphrase';

    # wait for welcome screen to appear, this can take a while
    assert_screen 'welcome-to-aeon', 600;

    # click the welcome screen, to close the GNOME Overview
    assert_and_click 'welcome-to-aeon';

    # press "Install Now"
    send_key 'ret';

    # ignore warning about tpm
    assert_screen 'installer-warning-no-tpm';
    send_key 'ret';

    # confirm disk erasure
    assert_and_click 'confirm-erase-disk';

    # deploy
    assert_screen 'deploying-image';

    # give the deployment some time, wait for the encryption info screen
    assert_screen 'set-encryption-passphrase-1', 600;
    send_key 'ret';

    # input a passphrase
    assert_screen 'set-encryption-passphrase-2';
    type_string $encryption_passphrase;
    send_key 'ret';
    wait_still_screen 3;

    # repeat the passphrase
    type_string $encryption_passphrase;
    send_key 'ret';

    # confirm the encryption recovery key
    assert_screen 'encryption-recovery-key';
    send_key 'ret';

    # confirm reboot
    assert_screen 'installation-complete';
    send_key 'ret';
}

1;
