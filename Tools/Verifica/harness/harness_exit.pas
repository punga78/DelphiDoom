// TEMPORARY HARNESS (issues #149, #152, #153, #154; not for the build of the game): ends the game by
// itself, with a clean exit, so that the parity reports (written in the finalization of the harness
// units) are produced. G_Ticker calls HarnessExitCheck(gametic). Change HARNESS_EXIT_TIC to run longer.

{$I Doom32.inc}

unit harness_exit;

interface

const
  /// Tic at which the game quits (WM_DESTROY, the normal way out): 3000 for Hexen (no demos)
{$IFDEF HEXEN}
  HARNESS_EXIT_TIC = 3000;
{$ELSE}
  HARNESS_EXIT_TIC = 4000;
{$ENDIF}

procedure HarnessExitCheck(ATic: integer);

implementation

uses
  i_system;

var
  harness_posted: boolean = false;

procedure HarnessExitCheck(ATic: integer);
begin
  if (ATic >= HARNESS_EXIT_TIC) and not harness_posted then
  begin
    harness_posted := true;
    I_Quit;
  end;
end;

end.
