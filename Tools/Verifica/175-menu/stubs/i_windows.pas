unit i_windows;
// stub of the harness: the folders where the original looks for its files (FindFLIFile) and no window
interface
var
  basedefault: string;
  maindatapath: string;
  cdr_drivenum: integer = -1;
procedure I_PeekAndDisplatch;
procedure I_Sleep(const msecs: integer);
implementation
procedure I_PeekAndDisplatch; begin end;
procedure I_Sleep(const msecs: integer); begin end;
end.
