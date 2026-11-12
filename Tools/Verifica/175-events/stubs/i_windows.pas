unit i_windows;
// stub of the harness: the drive of the CD-ROM where the original looks for the films
interface
var
  cdr_drivenum: integer = 0;
  ClockValue: LongWord = 0;
// clock of i_windows.pas: the program sets its value
function clock: LongWord;
implementation
function clock: LongWord;
begin
  Result := ClockValue;
end;
end.
