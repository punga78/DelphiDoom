unit harness_menu;
// the state of the harness that the stubs share: the scenario in course, its tics and the trace of the calls of the
// original to the parts of the game that are not of this piece
interface
uses SysUtils, DelphiDoom.Tests.Greed.MenuScenarios;
type
  EHarnessStop = class(Exception);
var
  HTrace: TMenuTrace;
  HScenario: TMenuScenario;
  HTics: Integer;
  HNextKey: Integer;
  HDown: array[0..127] of Boolean;
  // the intro: a new or loaded game sets gameloaded, as newplayer and LoadGame of the original do
  HIntroMode: Boolean = False;
  // called before each tic: the dpr hashes the screen and the palette
  HCapture: procedure = nil;
implementation
end.
