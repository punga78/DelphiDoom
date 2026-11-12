{******************************************************************************}
{                                                                              }
{  Greed32: the commands of the player read from a script, to play without     }
{  touching the keyboard                                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.ScriptControls;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Greed.Types,
  DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.CommandState;

type
  /// <summary>
  ///   IGreedCommandSource from the lines of a script:
  ///     tic command down|up    a command of TGreedCommand without "gc" (north, fire, use, weapon2 ...) goes
  ///                            down or up at that tic; "space" is use and restart, "shift" is run and shift,
  ///                            "alt" is strafe and alt, as the keys of the original
  ///     tic type TEXT          the characters are typed, one for each reading (a secret code)
  ///   Empty lines and the ones that start with # are skipped. The game reads the controls on the odd tics: the
  ///   tic of a reading is counted here (the first reading is the tic 1, the next the tic 3 ...). With an inner
  ///   source (the keyboard) a command is pressed if the script or the inner source says so.
  ///   EGreedException with the number of the line if a line is not understood
  /// </summary>
  TGreedScriptControls = class(TInterfacedObject, IGreedCommandSource)
  strict private
    type
      TStep = record
        Tic: Integer;
        Commands: set of TGreedCommand;
        Down: Boolean;
        Text: string;
      end;
    var
      FInner: IGreedCommandSource;
      FSteps: TList<TStep>;
      FNext: Integer;
      FReadings: Integer;
      FPressed: set of TGreedCommand;
      FTyping: string;
      FTypedInReading: Boolean;
    class function CommandsOf(const AName: string; out ACommands: TStep): Boolean; static;
    function GetTic: Integer;
  public
    /// <summary>AInner can be nil (the script alone)</summary>
    constructor Create(const AScript: TStrings; const AInner: IGreedCommandSource);
    destructor Destroy; override;
    procedure BeginReading;
    function IsPressed(ACommand: TGreedCommand): Boolean;
    function TakeTyped(out ACharacter: Char): Boolean;
    function IsMousePressed(AButton: TGreedMouseButton): Boolean;
    procedure TakeMouseMove(out ADeltaX, ADeltaY: Integer);
    /// <summary>The tic of the last reading (0 before the first)</summary>
    property Tic: Integer read GetTic;
  end;

implementation

uses
  System.TypInfo;

resourcestring
  SScriptLine = 'Greed: line %d of the script of the commands is not "tic command down|up" or "tic type TEXT": %s';

const
  WORD_TYPE = 'type';
  WORD_DOWN = 'down';
  WORD_UP = 'up';

{ TGreedScriptControls }

constructor TGreedScriptControls.Create(const AScript: TStrings; const AInner: IGreedCommandSource);
var
  LIndex: Integer;
  LLine: string;
  LWords: TArray<string>;
  LStep: TStep;
begin
  inherited Create;
  if not Assigned(AScript) then
    raise EArgumentNilException.Create('AScript');
  FInner := AInner;
  FSteps := TList<TStep>.Create;
  for LIndex := 0 to AScript.Count - 1 do
  begin
    LLine := Trim(AScript[LIndex]);
    if (LLine = '') or (LLine[1] = '#') then
      Continue;
    LWords := LLine.Split([' ', #9], TStringSplitOptions.ExcludeEmpty);
    LStep := Default(TStep);
    if (Length(LWords) < 3) or not TryStrToInt(LWords[0], LStep.Tic) then
      raise EGreedException.CreateFmt(SScriptLine, [LIndex + 1, LLine]);
    if SameText(LWords[1], WORD_TYPE) then
      LStep.Text := UpperCase(LWords[2])
    else
    begin
      if not CommandsOf(LWords[1], LStep) then
        raise EGreedException.CreateFmt(SScriptLine, [LIndex + 1, LLine]);
      if SameText(LWords[2], WORD_DOWN) then
        LStep.Down := True
      else if not SameText(LWords[2], WORD_UP) then
        raise EGreedException.CreateFmt(SScriptLine, [LIndex + 1, LLine]);
    end;
    FSteps.Add(LStep);
  end;
end;

destructor TGreedScriptControls.Destroy;
begin
  FSteps.Free;
  inherited Destroy;
end;

class function TGreedScriptControls.CommandsOf(const AName: string; out ACommands: TStep): Boolean;
var
  LValue: Integer;
begin
  ACommands := Default(TStep);
  Result := True;
  if SameText(AName, 'space') then
    ACommands.Commands := [gcUse, gcRestart]
  else if SameText(AName, 'shift') then
    ACommands.Commands := [gcRun, gcShift]
  else if SameText(AName, 'alt') then
    ACommands.Commands := [gcStrafe, gcAlt]
  else
  begin
    LValue := GetEnumValue(TypeInfo(TGreedCommand), 'gc' + AName);
    Result := LValue >= 0;
    if Result then
      ACommands.Commands := [TGreedCommand(LValue)];
  end;
end;

function TGreedScriptControls.GetTic: Integer;
begin
  Result := FReadings * 2 - 1;
  if Result < 0 then
    Result := 0;
end;

procedure TGreedScriptControls.BeginReading;
var
  LStep: TStep;
  LTic: Integer;
begin
  Inc(FReadings);
  FTypedInReading := False;
  LTic := GetTic;
  // the steps are served in the order of the script: a step waits for the ones before it
  while (FNext < FSteps.Count) and (FSteps[FNext].Tic <= LTic) do
  begin
    LStep := FSteps[FNext];
    if LStep.Text <> '' then
      FTyping := FTyping + LStep.Text
    else if LStep.Down then
      FPressed := FPressed + LStep.Commands
    else
      FPressed := FPressed - LStep.Commands;
    Inc(FNext);
  end;
  if Assigned(FInner) then
    FInner.BeginReading;
end;

function TGreedScriptControls.IsPressed(ACommand: TGreedCommand): Boolean;
begin
  Result := (ACommand in FPressed) or (Assigned(FInner) and FInner.IsPressed(ACommand));
end;

function TGreedScriptControls.TakeTyped(out ACharacter: Char): Boolean;
begin
  // one character of the script for each reading: the game takes one character a tic
  if (FTyping <> '') and not FTypedInReading then
  begin
    ACharacter := FTyping[1];
    Delete(FTyping, 1, 1);
    FTypedInReading := True;
    Exit(True);
  end;
  if Assigned(FInner) then
    Exit(FInner.TakeTyped(ACharacter));
  ACharacter := #0;
  Result := False;
end;

function TGreedScriptControls.IsMousePressed(AButton: TGreedMouseButton): Boolean;
begin
  Result := Assigned(FInner) and FInner.IsMousePressed(AButton);
end;

procedure TGreedScriptControls.TakeMouseMove(out ADeltaX, ADeltaY: Integer);
begin
  ADeltaX := 0;
  ADeltaY := 0;
  if Assigned(FInner) then
    FInner.TakeMouseMove(ADeltaX, ADeltaY);
end;

end.
