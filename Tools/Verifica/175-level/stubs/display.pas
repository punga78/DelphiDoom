unit display;
// stub of the harness: the variables of the status bar that the rules set, and its calls in the trace
interface
var
  oldinventory, oldshots, oldgoalitem, totaleffecttime: integer;
procedure resetdisplay;
procedure inventoryright;
procedure inventoryleft;
implementation
uses harness_level;
procedure resetdisplay; begin HarnessTrace.Call('resetdisplay', []); end;
procedure inventoryright; begin HarnessTrace.Call('inventoryright', []); end;
procedure inventoryleft; begin HarnessTrace.Call('inventoryleft', []); end;
end.
