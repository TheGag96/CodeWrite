import tkd.tkdapplication;
import std.stdio, std.file, std.process, std.array, std.conv, std.string, std.regex,
       std.algorithm, std.range;

enum VERSION = "1.0.3";

class Application : TkdApplication {
  Text asmBox;
  Text codeBox;
  Entry addressEntry;

  string currentFile = "";
  string lastASM = "";

  //////////////////////
  //GUI setup
  //////////////////////

  override protected void initInterface() {
    mainWindow.setTitle("CodeWrite")
              .setMinSize(652, 0)
              .setDefaultIcon(new EmbeddedPng!("icon.png"))
              .bind("<Control-o>", &open)
              .bind("<Control-s>", &save)
              .bind("<Control-n>", &newFile)
              .bind("<Control-Shift-s>", &saveAs)
              .setProtocolCommand(WindowProtocol.deleteWindow, (args) {
                if (confirmDiscard(args)) this.exit();
              });

    ////
    //Menu bar things
    ////
    auto menuBar = new MenuBar(mainWindow);

    auto fileMenu = new Menu(menuBar, "File")
                      .addEntry("New ASM File", &newFile)
                      .addEntry("Open ASM File...", &open)
                      .addEntry("Save ASM", &save)
                      .addEntry("Save ASM File As...", &saveAs);

    auto helpMenu = new Menu(menuBar, "Help")
                      .addEntry("About", &about);

    ////
    //Left frame (ASM text box)
    ////
    auto leftFrame = new Frame().pack(10, 10, GeometrySide.left, GeometryFill.both, AnchorPosition.west, true);

    auto addressFrame = new LabelFrame(leftFrame, "Insertion Address").pack(0, 0, GeometrySide.top, GeometryFill.x);
    addressEntry = new Entry(addressFrame).pack(8, 0, GeometrySide.left);

    auto asmFrame = new LabelFrame(leftFrame, "ASM").pack(0, 0, GeometrySide.top, GeometryFill.both,  AnchorPosition.west, true);
    asmBox = new Text(asmFrame).pack(8, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true)
                       .setWidth(30)
                       .setUndoLevels(100)
                       .setWrapMode("none");

    auto asmYScroll = new YScrollBar(asmBox).attachWidget(asmBox).pack(0, 0, GeometrySide.right, GeometryFill.y);
    auto asmXScroll = new XScrollBar(asmBox).attachWidget(asmBox).pack(0, 0, GeometrySide.bottom, GeometryFill.x);
    asmBox.attachXScrollBar(asmXScroll);
    asmBox.attachYScrollBar(asmYScroll);

    ////
    //Right frame (Gecko code text box)
    ////
    auto codesFrame = new LabelFrame("Codes").pack(10, 0, GeometrySide.right, GeometryFill.y, AnchorPosition.east);
    //new Button(codesFrame, "Send to Code Manager").pack(8, 0, GeometrySide.top, GeometryFill.x);
    codeBox = new Text(codesFrame).pack(8, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true)
                        .setWidth(25)
                        .setUndoLevels(100);
    //auto codesYScroll = new YScrollBar(codeBox).attachWidget(codeBox).pack(0, 0, GeometrySide.right, GeometryFill.y);
    //codeBox.attachYScrollBar(codesYScroll).setWidth(25);

    ////
    //In-between buttons
    ////
    new Button("←").pack(10, 0, GeometrySide.top, GeometryFill.none, AnchorPosition.north)
                   .setCommand(&codeToAsm);
    new Button("→").pack(10, 0, GeometrySide.bottom, GeometryFill.none, AnchorPosition.south)
                   .setCommand(&asmToCode);
  }

  //////////////////////
  //Menu commands
  //////////////////////

  void newFile(CommandArgs args) {
    if (!confirmDiscard(args)) return;

    asmBox.clear;
    lastASM = "";
    currentFile = "";
  }

  void open(CommandArgs args) {
    if (!confirmDiscard(args)) return;

    auto dialog = new OpenFileDialog("Open an ASM file...")
      .setMultiSelection(false)
      .setDefaultExtension(".asm")
      .addFileType("{{ASM files} {.asm}}")
      .addFileType("{{All files} {*}}")
      .show;

    if (dialog.getResult != "") {
      asmBox.clear;
      currentFile = dialog.getResult;
      auto openedText = readText(currentFile);

      auto firstLine = openedText.until("\n").to!string;
      auto re = ctRegex!(`#To be inserted at ([a-f,A-F,0-9]{8})(\r)?$`);
      auto result = matchFirst(firstLine, re);
      if (!result.empty) {
        addressEntry.setValue(result.hit[$-8..$]);
        openedText = openedText[firstLine.length+1..$];
      }

      asmBox.insertText(1, 0, openedText);
      lastASM = openedText;
    }
  }

  bool confirmDiscard(CommandArgs args) {
    auto asmText = (asmBox.getText)[0..$-1];  //chop of trailing newline from Text widget
    if (lastASM != asmText && asmText != "") {
      auto result = new MessageDialog("Save file?")
        .setIcon(MessageDialogIcon.question)
        .setMessage("Save changes to this file?")
        .setType(MessageDialogType.yesnocancel)
        .show
        .getResult;  

      if (result == "yes") {
        save(args);
      }
      else if (result == "cancel") {
        return false;
      }
    }

    return true;
  }

  void save(CommandArgs args) {
    if (currentFile == "") saveAs(args);
    else {
      writeOutASM();
    }
  }

  void saveAs(CommandArgs args) {
    auto result = new SaveFileDialog("Save an ASM file...")
      .setConfirmOverwrite(true)
      .setDefaultExtension(".asm")
      .addFileType("{{ASM files} {.asm}}")
      .addFileType("{{All files} {*}}")
      .show
      .getResult;

    if (result != "") {
      currentFile = result;
      writeOutASM();      
    }
  }

  void writeOutASM() {
    auto asmText = (asmBox.getText)[0..$-1];  //chop off trailing newline from Text widget
    lastASM = asmText;

    auto address = addressEntry.getValue;
    auto re = ctRegex!("([a-f,A-F,0-9]{8})$");

    if (!matchFirst(address, re).empty) {
      asmText = "#To be inserted at " ~ address ~ "\n" ~ asmText;
    }

    std.file.write(currentFile, asmText);

  }

  void about(CommandArgs args) {
    auto dialog = new MessageDialog("About CodeWrite")
      .setMessage("CodeWrite v" ~ VERSION ~ "\n" ~
                  "by TheGag96/codeThaumaturge\n" ~
                  "written in D using tkd for Tcl/Tk bindings")
      .show;
  }

  //////////////////////
  //Internal functions
  //////////////////////

  void asmToCode(CommandArgs args) {
    if (asmBox.getText.strip == "") return;

    ////
    //Preprocess code string to remove ; comments
    ////
    auto re = regex(r";.*$", "gm"); //" fix shitty sublime parsing
    string assembly = replaceAll(asmBox.getText, re, "");

    ////
    //Check validity of start address
    ////
    bool codeIsExecute = (addressEntry.getValue.toUpper == "N/A");
    uint startAddress;

    writeln(codeIsExecute);

    if (!codeIsExecute) {
      try {
        startAddress = addressEntry.getValue.to!uint(16);
        if (startAddress < 0x80000000 || startAddress > 0x81FFFFFF) throw new Exception("ayy lmao");
      }
      catch (Exception e) {
        errorNotice("Your address should be a hex number between 80000000 and 81FFFFFF (or use N/A for the C0 codetype).");
        return;
      }
    }

    ////
    //Run compiler and get results
    ////
    std.file.write("temptemptemp.asm", assembly);
    scope(exit) std.file.remove("temptemptemp.asm");

    auto shell = execute(["powerpc-gekko-as.exe", "-a32", "-mbig", "-mregnames", "-mgekko", "temptemptemp.asm"], null, Config.suppressConsole);

    if (!exists("a.out")) {
      errorNotice("Looks like the ASM failed to compile. Output:\n\n " ~ shell.output);
      return;
    }

    scope(exit) std.file.remove("a.out");

    auto data = cast(ubyte[]) std.file.read("a.out");
    data = data[52..data.countUntil([0x00, 0x2E, 0x73, 0x79, 0x6D, 0x74, 0x61, 0x62])];

    auto numLines = data.length/8+1;

    ////
    //Output formatted code to text box
    ////
    auto code = appender!string;

    if (codeIsExecute) code.put("C0000000");
    else code.put(format("%08X", startAddress + 0x42000000)); 

    code.put(" ");
    code.put(format("%08X", numLines));

    int counter = 0;
    foreach (b; data) {
      if (counter % 8 == 4) code.put(" ");
      else if (counter % 8 == 0) code.put("\n");

      code.put(format("%02X", b));

      counter++;
    }

    if (counter % 8 == 4) {
      code.put(" 00000000");
    }
    else {
      code.put("\n60000000 00000000");
    }

    codeBox.clear();
    codeBox.insertText(0, 0, code.data);
  }

  void codeToAsm(CommandArgs args) {
    if (codeBox.getText.strip == "") return;

    ////
    //Process code
    ////
    ubyte[] bytes;
    auto pureCode = codeBox.getText.replace(" ", "").replace("\n", "").replace("*", "").toUpper;    
    uint offset;

    try {
      if (pureCode.length % 8 != 0) throw new Exception("invalid");

      //needs to be a valid code command
      if (pureCode[0..2] == "C2") {
        offset = pureCode[2..8].to!uint(16) + 0x80000000;
      }
      else if (pureCode[0..2] == "C3") {
        offset = pureCode[2..8].to!uint(16) + 0x81000000;
      }
      else if (pureCode[0..2] == "C0") {
        offset = 0;
      }
      else {
        throw new Exception("invalid");
      }

      //get offset for later
      
    
      //convert every two characters to bytes
      pureCode = pureCode[16..$];
      foreach (i; iota(0, pureCode.length, 2)) {
        bytes ~= pureCode[i..i+2].to!ubyte(16);   
      }  

      //trim off trailing 00000000
      if (bytes[$-8..$] == [0, 0, 0, 0, 0, 0, 0, 0]) bytes = bytes[0..$-8];
    }
    catch (Exception e) {
      errorNotice("Looks like this isn't a valid ASM code.");
      return;
    }

    //write code to file
    std.file.write("code.bin", bytes);
    scope(exit) std.file.remove("code.bin");

    ////
    //Run disassembler and get results
    ////
    auto command = execute(["vdappc", "code.bin", "0"], null, Config.suppressConsole);

    auto decompiled = command.output.replace("\t", " ").lineSplitter.map!(x => x[20..$]).join("\n");

    //remove trailing 0 data
    if (decompiled.endsWith(".word 0x00000000")) decompiled = decompiled[0..$-17];
    if (decompiled.endsWith("nop ")) decompiled = decompiled[0..$-5];

    if (offset == 0) {
      addressEntry.setValue("N/A");
    }
    else {
      addressEntry.setValue(offset.to!string(16));
    }
    
    ////
    //Fix absolute branches to relative ones
    ////
    auto fixed = appender!(string[]);
    bool[uint] labelTable = [0 : true];
    static immutable IMMEDIATES = ["li", "lis", "ori", "addi", "cmpwi", "subi", "andi.", "andis.", "cmpli", "mulli", "oris"];

    foreach (line; decompiled.lineSplitter) {
      bool madeFix = false;

      try {
        if (line.startsWith('b')) {
          uint jumpLocation = line[line.countUntil(' ')+3 .. $].to!int(16);
          labelTable[jumpLocation] = true;
          fixed.put(format("  %sloc_0x%X\n", line.until(' ', OpenRight.no), jumpLocation));
          madeFix = true;
        }
        else if (IMMEDIATES.canFind(line[0..line.countUntil(' ')])) {
          string unedited = line[0..line.lastIndexOf(',')+1];
          int value = line[unedited.length..$].to!int & 0xFFFF;

          fixed.put(format("  %s0x%X\n", unedited, value));
          madeFix = true;
        }
      }
      catch (ConvException e) { /* Sometimes just starting with "b" doesn't mean it's an immediate branch lel */ }
      catch (core.exception.RangeError e) { }
      
      if (!madeFix) {
        fixed.put(format("  %s\n", line));
      }
    }

    asmBox.clear();

    uint pos     = 0;
    uint lineNum = 1;
    foreach (line; fixed.data) {
      if (pos in labelTable) {
        if (pos != 0) {
          asmBox.insertText(lineNum, 0, "\n");
          lineNum++;
        }

        asmBox.insertText(lineNum, 0, format("loc_0x%X:\n", pos));
        lineNum++;
      }

      asmBox.insertText(lineNum, 0, line.replace(",", ", "));
      
      pos += 4;
      lineNum++;
    }
  }

  void errorNotice(string message) {
    new MessageDialog("Whoopsie!")
      .setMessage(message)
      .show();
  }
}

void main() {
  auto application = new Application;
  application.run();
}