
public class DisplayPlug : Gtk.Application {
    Gtk.Box main_box;
    Gtk.Button apply_button;
    OutputList output_list;

    Gtk.Switch mirror_display;
    Gtk.Grid mirror_display_grid;

    Gtk.InfoBar error_bar;
    Gtk.Label error_label;

    bool ui_update = false;

    public DisplayPlug () {
        main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);

        error_bar = new Gtk.InfoBar ();
        error_bar.message_type = Gtk.MessageType.ERROR;
        error_bar.no_show_all = true;
        error_label = new Gtk.Label ("");
        error_bar.get_content_area ().add (error_label);

        output_list = new OutputList ();
        output_list.set_size_request (700, 350);

        var output_frame = new Gtk.Frame (null);
        output_frame.margin = 12;
        output_frame.margin_bottom = 0;
        output_frame.add (output_list);

        var bottom_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        bottom_box.margin = 12;
        bottom_box.margin_top = 0;

        mirror_display = new Gtk.Switch ();
        mirror_display.halign = Gtk.Align.START;
        mirror_display.notify["active"].connect (() => {update_clone ();});

        mirror_display_grid = new Gtk.Grid ();
        mirror_display_grid.orientation = Gtk.Orientation.HORIZONTAL;
        mirror_display_grid.column_spacing = 12;
        mirror_display_grid.add (new Utils.RLabel.right (_("Mirror Display:")));
        mirror_display_grid.add (mirror_display);

        var detect_displays = new Gtk.Button.with_label (_("Detect Displays"));
        apply_button = new Gtk.Button.with_label (_("Apply"));
        apply_button.sensitive = false;
        apply_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        apply_button.clicked.connect (() => {Configuration.get_default ().apply ();});

        bottom_box.pack_start (mirror_display_grid, false);
        bottom_box.pack_end (apply_button, false);
        bottom_box.pack_end (detect_displays, false);

        main_box.pack_start (error_bar);
        main_box.pack_start (output_frame);
        main_box.pack_start (bottom_box, false);

        var config = Configuration.get_default ();
        config.report_error.connect (report_error);
        config.update_outputs.connect (update_outputs);
        config.apply_state_changed.connect ((can_apply) => {
            apply_button.sensitive = can_apply;
        });

        config.screen_changed ();
    }

    void update_clone () {
        if (ui_update)
            return;

        var configuration = Configuration.get_default ();

        if (mirror_display.active == true) {
            if (configuration.enable_clone_mode () == false) {
                ui_update = true;
                mirror_display.active = false;
                ui_update = false;
            }
        } else {
            configuration.disable_clone_mode ();
        }
    }

    void update_outputs (Gnome.RRConfig current_config) {
        ui_update = true;

        var enabled_monitors = 0;

        output_list.clone_mode = current_config.get_clone ();
        output_list.remove_all ();
        foreach (unowned Gnome.RROutputInfo output in current_config.get_outputs ()) {
            if (output.is_connected ()) {
                if (output_list.clone_mode && !output.is_active ())
                    continue;

                output_list.add_output (output);

                if (output.is_active ())
                    enabled_monitors++;

                // a single active monitor is already enough while in clone mode
                if (output_list.clone_mode)
                    break;
            }
        }

        mirror_display.active = current_config.get_clone ();
        if (mirror_display.active || enabled_monitors > 1) {
            mirror_display_grid.no_show_all = false;
            mirror_display_grid.show_all ();
        } else {
            mirror_display_grid.no_show_all = true;
            mirror_display_grid.hide ();
        }

        ui_update = false;
    }

    void report_error (string message) {
        error_label.label = message;
        error_label.show ();
        error_bar.show ();
    }

    public Gtk.Widget get_widget () {
        return main_box;
    }

    protected override void activate () {
        // Create the window of this application and show it
        Gtk.ApplicationWindow window = new Gtk.ApplicationWindow (this);
        window.set_default_size (800, 400);

        window.add (get_widget ());
        window.show_all ();
    }

    public static int main (string[] args) {
        GtkClutter.init (ref args);
        DisplayPlug app = new DisplayPlug ();
        return app.run (args);
    }
}