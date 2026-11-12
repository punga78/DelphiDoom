{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - a script of keys for the whole program           }
{  Port of xGreed (Jim Valavanis, GPL v2 or later)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.ApplicationScript;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.CommandState,
  DelphiDoom.Greed.Application.Intf;

type
  /// <summary>
  ///   Presses keys at the tics of the program, in the menus and in the game alike, so that a whole session can be
  ///   driven without a keyboard. The lines are
  ///     tic name down|up    the key goes down or up when the tic runs (the first tic of the program is 1)
  ///     tic type TEXT       the characters are typed, one for each reading of the game (a secret code)
  ///   The name is a key of the menus (up, down, left, right, enter, esc, backspace, space, a letter or a digit)
  ///   or a command of the game without the "gc" (north, east, fire, use, weapon2, menu ...); "space" is also use
  ///   and restart, "esc" is also the menu command, "shift" is run and shift, "alt" is strafe and alt, as the keys
  ///   of the original. Empty lines and lines that start with # are skipped; the lines may be in any order of tics.
  ///   The script is the keyboard of the screens (IGreedKeyboard), the source of the commands of the game (with
  ///   an inner source, the window, a command is pressed if either says so) and the listener of the tics
  /// </summary>
  TGreedApplicationScript = class(TInterfacedObject, IGreedKeyboard, IGreedCommandSource, IGreedTicListener)
  strict private
    const
      KEY_COUNT = 128;
    type
      TGreedCommandSet = set of TGreedCommand;
      TStep = record
        Tic: Integer;
        ScanCode: Integer;
        Commands: TGreedCommandSet;
        Down: Boolean;
        Text: string;
      end;
    var
      FInner: IGreedCommandSource;
      FSteps: TList<TStep>;
      FNext: Integer;
      FKeys: array[0..KEY_COUNT - 1] of Boolean;
      FPressed: TGreedCommandSet;
      FTyping: string;
      FTypedInReading: Boolean;
    class function CommandsOf(const AName: string; out ACommands: TGreedCommandSet): Boolean; static;
    class function ScanCodeOfName(const AName: string): Integer; static;
  public
    /// <summary>AInner can be nil (the script alone); EGreedException with the number of the line if one is not understood</summary>
    constructor Create(const AScript: TStrings; const AInner: IGreedCommandSource);
    destructor Destroy; override;
    // IGreedKeyboard
    function IsDown(AScanCode: Integer): Boolean;
    // IGreedTicListener
    procedure TicStarting(ATic: Integer);
    // IGreedCommandSource
    procedure BeginReading;
    function IsPressed(ACommand: TGreedCommand): Boolean;
    function TakeTyped(out ACharacter: Char): Boolean;
    function IsMousePressed(AButton: TGreedMouseButton): Boolean;
    procedure TakeMouseMove(out ADeltaX, ADeltaY: Integer);
  end;

implementation

uses
  System.TypInfo, DelphiDoom.Greed.Types, DelphiDoom.Greed.MenuInput;

resourcestring
  SScriptLine = 'Greed: line %d of the script is not "tic key|command down|up" or "tic type TEXT": %s';

const
  WORD_TYPE = 'type';
  WORD_DOWN = 'down';
  WORD_UP = 'up';
  NO_SCAN_CODE = -1;

{ TGreedApplicationScript }

constructor TGreedApplicationScript.Create(const AScript: TStrings; const AInner: IGreedCommandSource);
var
  LIndex, LPosition: Integer;
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
    LStep.ScanCode := NO_SCAN_CODE;
    if (Length(LWords) < 3) or not TryStrToInt(LWords[0], LStep.Tic) then
      raise EGreedException.CreateFmt(SScriptLine, [LIndex + 1, LLine]);
    if SameText(LWords[1], WORD_TYPE) then
      LStep.Text := UpperCase(LWords[2])
    else
    begin
      LStep.ScanCode := ScanCodeOfName(LWords[1]);
      if (not CommandsOf(LWords[1], LStep.Commands)) and (LStep.ScanCode = NO_SCAN_CODE) then
        raise EGreedException.CreateFmt(SScriptLine, [LIndex + 1, LLine]);
      if SameText(LWords[2], WORD_DOWN) then
        LStep.Down := True
      else if not SameText(LWords[2], WORD_UP) then
        raise EGreedException.CreateFmt(SScriptLine, [LIndex + 1, LLine]);
    end;
    LPosition := FSteps.Count;
    while (LPosition > 0) and (FSteps[LPosition - 1].Tic > LStep.Tic) do
      Dec(LPosition);
    FSteps.Insert(LPosition, LStep);
  end;
end;

destructor TGreedApplicationScript.Destroy;
begin
  FSteps.Free;
  inherited Destroy;
end;

class function TGreedApplicationScript.ScanCodeOfName(const AName: string): Integer;
begin
  Result := NO_SCAN_CODE;
  if SameText(AName, 'up') then
    Result := GREED_SC_UPARROW
  else if SameText(AName, 'down') then
    Result := GREED_SC_DOWNARROW
  else if SameText(AName, 'left') then
    Result := GREED_SC_LEFTARROW
  else if SameText(AName, 'right') then
    Result := GREED_SC_RIGHTARROW
  else if SameText(AName, 'enter') or SameText(AName, 'return') then
    Result := GREED_SC_ENTER
  else if SameText(AName, 'esc') or SameText(AName, 'escape') then
    Result := GREED_SC_ESCAPE
  else if SameText(AName, 'backspace') then
    Result := GREED_SC_BACKSPACE
  else if SameText(AName, 'space') then
    Result := GREED_SC_SPACE
  else if (Length(AName) = 1) and CharInSet(UpCase(AName[1]), ['A'..'Z', '0'..'9']) then
    Result := TGreedMenuInput.ScanCodeOfChar(AName[1]);
end;

class function TGreedApplicationScript.CommandsOf(const AName: string; out ACommands: TGreedCommandSet): Boolean;
var
  LValue: Integer;
begin
  ACommands := [];
  Result := True;
  if SameText(AName, 'space') then
    ACommands := [gcUse, gcRestart]
  else if SameText(AName, 'esc') or SameText(AName, 'escape') then
    ACommands := [gcMenu]
  else if SameText(AName, 'shift') then
    ACommands := [gcRun, gcShift]
  else if SameText(AName, 'alt') then
    ACommands := [gcStrafe, gcAlt]
  else
  begin
    LValue := GetEnumValue(TypeInfo(TGreedCommand), 'gc' + AName);
    Result := LValue >= 0;
    if Result then
      ACommands := [TGreedCommand(LValue)];
  end;
end;

function TGreedApplicationScript.IsDown(AScanCode: Integer): Boolean;
begin
  Result := (AScanCode >= 0) and (AScanCode < KEY_COUNT) and FKeys[AScanCode];
end;

procedure TGreedApplicationScript.TicStarting(ATic: Integer);
var
  LStep: TStep;
begin
  // the steps are served in the order of the script: a step waits for the ones before it
  while (FNext < FSteps.Count) and (FSteps[FNext].Tic <= ATic) do
  begin
    LStep := FSteps[FNext];
    if LStep.Text <> '' then
      FTyping := FTyping + LStep.Text
    else
    begin
      if LStep.ScanCode <> NO_SCAN_CODE then
        FKeys[LStep.ScanCode] := LStep.Down;
      if LStep.Down then
        FPressed := FPressed + LStep.Commands
      else
        FPressed := FPressed - LStep.Commands;
    end;
    Inc(FNext);
  end;
end;

procedure TGreedApplicationScript.BeginReading;
begin
  FTypedInReading := False;
  if Assigned(FInner) then
    FInner.BeginReading;
end;

function TGreedApplicationScript.IsPressed(ACommand: TGreedCommand): Boolean;
begin
  Result := (ACommand in FPressed) or (Assigned(FInner) and FInner.IsPressed(ACommand));
end;

function TGreedApplicationScript.TakeTyped(out ACharacter: Char): Boolean;
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

function TGreedApplicationScript.IsMousePressed(AButton: TGreedMouseButton): Boolean;
begin
  Result := Assigned(FInner) and FInner.IsMousePressed(AButton);
end;

procedure TGreedApplicationScript.TakeMouseMove(out ADeltaX, ADeltaY: Integer);
begin
  ADeltaX := 0;
  ADeltaY := 0;
  if Assigned(FInner) then
    FInner.TakeMouseMove(ADeltaX, ADeltaY);
end;

end.
