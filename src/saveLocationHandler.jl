using Gtk
using Gtk.ShortNames

function openDialog(thisDir::String)
    dir = open_dialog("Select Directory to save", action=GtkFileChooserAction.SELECT_FOLDER)
    println(dir)
    if dir != thisDir
        return dir
    end
    return ""
end
