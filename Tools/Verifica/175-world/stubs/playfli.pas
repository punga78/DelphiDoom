unit playfli;
// stub of the harness: no film is played, and the time that the original waits for (Wait of intro.pas, the fades of
// d_video.pas) has always come: without the timer thread nothing would make it pass
interface
function CheckTime(const n1, n2: integer): boolean;
function FindFLIFile(var fname: string): boolean;
function DoPlayFLI(const afname: string; const offset: integer): boolean;
implementation
function CheckTime(const n1, n2: integer): boolean;
begin
  Result := true;
end;
function FindFLIFile(var fname: string): boolean;
begin
  Result := false;
end;
function DoPlayFLI(const afname: string; const offset: integer): boolean;
begin
  Result := false;
end;
end.
