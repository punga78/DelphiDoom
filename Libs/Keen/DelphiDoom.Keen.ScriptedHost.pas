{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the clock and the keyboard of a run that a        }
{  script drives                                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.ScriptedHost;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf, DelphiDoom.Keen.Script;

const
  /// <summary>The steps that the game can wait after the last event of a script before the run is called stuck</summary>
  KEEN_SCRIPT_GRACE_STEPS = 20000;

type
  /// <summary>The script has no more events and the game still waits: the run would never end</summary>
  EKeenScriptEndedException = class(EKeenException);

  /// <summary>
  ///   The time and the keys of a game that runs without a player and without the clock of the machine: each time
  ///   the game waits (Idle of the clock, or a step that the program asks for) a tic goes by, and the events of the
  ///   script whose tic has come happen: a byte goes to the keyboard service of the input manager, a picture is
  ///   asked for, the run ends. The same script gives the same run every time. TimeCount is the one of the
  ///   game, that the game can change; the script has its own count of steps
  /// </summary>
  TKeenScriptedHost = class(TInterfacedObject, IKeenClock)
  strict private
    FEvents: TArray<TKeenScriptEvent>;
    FNext: Integer;
    FSteps: Integer;
    FTimeCount: Integer;
    FKeys: TProc<Byte>;
    FOnShot: TProc<string>;
    FOnStep: TProc;
    FStepping: Boolean;
  public
    /// <param name="AEvents">The script (TKeenScript.Parse)</param>
    constructor Create(const AEvents: TArray<TKeenScriptEvent>);
    function GetTimeCount: Integer;
    procedure SetTimeCount(AValue: Integer);
    procedure Idle;
    /// <summary>
    ///   A tic goes by: the events that are due happen. "quit" is an EKeenQuitException; a script that ended
    ///   KEEN_SCRIPT_GRACE_STEPS steps ago is an EKeenScriptEndedException
    /// </summary>
    procedure Step;
    /// <summary>The steps since the start</summary>
    property Steps: Integer read FSteps;
    /// <summary>Where the bytes of the keyboard go (IKeenInput.KeyService)</summary>
    property Keys: TProc<Byte> read FKeys write FKeys;
    /// <summary>What a "shot" does, with the name of the picture</summary>
    property OnShot: TProc<string> read FOnShot write FOnShot;
    /// <summary>What happens at each step after the clock moved (the sound of a tic, for instance)</summary>
    property OnStep: TProc read FOnStep write FOnStep;
  end;

implementation

const
  SScriptEnded = 'Keen: the script ended %d steps ago and the game still waits';

{ TKeenScriptedHost }

constructor TKeenScriptedHost.Create(const AEvents: TArray<TKeenScriptEvent>);
begin
  inherited Create;
  FEvents := Copy(AEvents);
end;

function TKeenScriptedHost.GetTimeCount: Integer;
begin
  Result := FTimeCount;
end;

procedure TKeenScriptedHost.SetTimeCount(AValue: Integer);
begin
  FTimeCount := AValue;
end;

procedure TKeenScriptedHost.Idle;
begin
  Step;
end;

procedure TKeenScriptedHost.Step;
var
  LEvent: TKeenScriptEvent;
begin
  // what an event does can wait in turn (a picture never does, a key hook might): one step at a time
  if FStepping then
    Exit;
  FStepping := True;
  try
    Inc(FSteps);
    Inc(FTimeCount);
    if Assigned(FOnStep) then
      FOnStep();
    while (FNext < Length(FEvents)) and (FEvents[FNext].Tic <= FSteps) do
    begin
      LEvent := FEvents[FNext];
      Inc(FNext);
      case LEvent.Kind of
        ksePort:
          if Assigned(FKeys) then
            FKeys(LEvent.Port);
        kseShot:
          if Assigned(FOnShot) then
            FOnShot(LEvent.Name);
        kseQuit:
          raise EKeenQuitException.Create(SKeenQuit);
      end;
    end;
    if (FNext >= Length(FEvents)) and
      ((Length(FEvents) = 0) and (FSteps > KEEN_SCRIPT_GRACE_STEPS) or
       (Length(FEvents) > 0) and (FSteps - FEvents[High(FEvents)].Tic > KEEN_SCRIPT_GRACE_STEPS)) then
      raise EKeenScriptEndedException.CreateFmt(SScriptEnded, [KEEN_SCRIPT_GRACE_STEPS]);
  finally
    FStepping := False;
  end;
end;

end.
