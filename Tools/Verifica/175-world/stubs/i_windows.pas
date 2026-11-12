unit i_windows;
// stub of the harness: there is no window; the clock of the system is the one of the harness (a function of the
// tics that the game has run), an error is written and stops the program
interface
uses
  g_delphi, Windows;
var
  hMainWnd: HWND = 0;
const
  IMB_ERROR = MB_OK or MB_ICONERROR or MB_APPLMODAL;
function I_MessageBox(hWnd: HWND; lpText, lpCaption: PChar; uType: UINT): Integer;
function I_GetFocus: HWND;
procedure I_PeekAndDisplatch;
procedure I_Sleep(const msecs: integer);
function I_GetTime: integer;
function clock: LongWord;
var
  basedefault: string;
  maindatafile: string255_t;
  maindatapath: string;
  stdoutfile: string;
  cdr_drivenum: integer;
  // set by the harness
  HarnessClock: LongWord = 0;
implementation
function I_MessageBox(hWnd: HWND; lpText, lpCaption: PChar; uType: UINT): Integer;
begin
  Writeln(ErrOutput, string(lpText));
  Result := 0;
end;
function I_GetFocus: HWND;
begin
  Result := 0;
end;
procedure I_PeekAndDisplatch;
begin
end;
procedure I_Sleep(const msecs: integer);
begin
end;
function I_GetTime: integer;
begin
  Result := integer(HarnessClock);
end;
function clock: LongWord;
begin
  Result := HarnessClock;
end;
end.
