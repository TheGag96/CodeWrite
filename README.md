# CodeWrite
A clone/alternative to ASMWiiRd.

![Screenshot](http://i.imgur.com/1FW9W73.png)

Advantages over ASMWiiRd:
* Disassembling creates labels in places that are branched to 
* Support for easy shortcuts like Crtl+A, Crtl+N, Crtl+S, Crtl+Shift+S, Crtl+O
* Confirms file discard with a popup
* Saves the insertion address to the .asm file and reloads it on re-open for convenience
* Compilation error gives a popup instead of dumping it to the code box

Just little things, really. I may add more features if I think of any useful ones. I might also rewrite this using GtkD instead of Tcl/Tk bindings due to how old and clunky the framework is.
