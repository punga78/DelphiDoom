unit d_font;
// stub of the harness: the line that event.pas prints after a film tells which film it was
interface
type
  Pfont_t = Pointer;
var
  font, font1: Pfont_t;
  fontbasecolor, printx, printy: integer;
  timemsg: integer;
procedure FN_PrintCentered(const s: string);
implementation
uses constant, d_disk, calllog, playfli, DelphiDoom.Tests.Greed.EventScenarios;
const
  names: array[0..2] of string = ('JETTISON.FLI', 'TMPL_DIE.FLI', 'KAAL_DIE.FLI');
procedure FN_PrintCentered(const s: string);
var
  n: integer;
  played: boolean;
begin
  n := TEventScenarios.FliOfCaption(s);
  // the film that was played must be the one of the line (in the demo it is a lump of GREED.BLO, otherwise a file
  // of the CD-ROM), and the line is at 160, 185 in the colour 8
  played := false;
  if n >= 0 then
  begin
    if DEMO then
      played := (LastMovie = 'GREED.BLO') and (LastOffset = infotable[DiskNumber(names[n])].filepos)
    else
      played := (LastMovie = 'A:\MOVIES\' + names[n]) and (LastOffset = 0);
  end;
  if not played or (printx <> 160) or (printy <> 185) or (fontbasecolor <> 8) then
    n := -2;
  Calls.AddCall(EVENT_CALL_FLI, [n]);
end;
end.
