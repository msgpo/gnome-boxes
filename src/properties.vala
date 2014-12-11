// This file is part of GNOME Boxes. License: LGPLv2+
using Gtk;

private enum Boxes.PropertiesPage {
    GENERAL,
    SYSTEM,
    DEVICES,
    SNAPSHOTS,

    LAST,
}

private class Boxes.Properties: Gtk.Notebook, Boxes.UI {
    public UIState previous_ui_state { get; protected set; }
    public UIState ui_state { get; protected set; }

    private AppWindow window;

    private ulong stats_id;
    private bool restore_fullscreen;

    construct {
        notify["ui-state"].connect (ui_state_changed);
    }

    private void populate () {
        foreach (var page in get_children ())
            remove (page);

        var machine = window.current_item as Machine;

        if (machine == null)
            return;

        for (var i = 0; i < PropertiesPage.LAST; i++) {
            var page = new PropertiesPageWidget (i, machine);
            var label = new Gtk.Label (page.name);
            insert_page (page, label, i);
            set_data<PropertiesPageWidget> (@"boxes-property-$i", page);

            page.refresh_properties.connect (() => {
                var current_page = this.page;
                this.populate ();
                this.page = current_page;
            });
        }

        page = PropertiesPage.GENERAL;
    }

    public void setup_ui (AppWindow window, PropertiesWindow dialog) {
        this.window = window;

        show_all ();
    }

    private void ui_state_changed () {
        if (stats_id != 0) {
            window.current_item.disconnect (stats_id);
            stats_id = 0;
        }

        if (ui_state == UIState.PROPERTIES) {
            restore_fullscreen = (previous_ui_state == UIState.DISPLAY && window.fullscreened);
            window.fullscreened = false;

            populate ();
        } else if (previous_ui_state == UIState.PROPERTIES) {
            var reboot_required = false;

            for (var i = 0; i < PropertiesPage.LAST; i++) {
                var page = get_data<PropertiesPageWidget> (@"boxes-property-$i");
                reboot_required |= page.flush_changes ();
            }

            var machine = window.current_item as Machine;
            if (reboot_required && (machine.is_on () || machine.state == Machine.MachineState.SAVED)) {
                var message = _("Changes require restart of '%s'.").printf (machine.name);
                window.notificationbar.display_for_action (message, _("_Restart"), () => {
                    machine.restart ();
                });
            }

            if (restore_fullscreen) {
                window.fullscreened = true;
                restore_fullscreen = false;
            }
        }
    }
}
