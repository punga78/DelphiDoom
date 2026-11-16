{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - the states of a definition                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.StateReader;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Scanner.Scanner, DelphiDoom.ActorDef.Types,
  DelphiDoom.ActorDef.StateOwner;

type
  /// <summary>
  ///   Reads the lines of the states of an actor or a weapon (the old ParseState): a line is
  ///   [label:] sprite frames duration [BRIGHT] [FAST] [action]; the words LOOP, STOP, WAIT and GOTO
  ///   say where the last state goes next. The states are kept until the definition ends
  /// </summary>
  TActorDefStateReader = class
  private
    FScanner: TScriptScanner;
    FLog: ILog;
    FOwner: IActorDefStateOwner;
    FTokens: TArray<string>;
    FStates: TActorDefStates;
    FCount: Integer;
    function IsDefinitionKeyword(const AToken: string): Boolean;
    procedure ReadGoto;
    procedure ReadDuration(out ATics, ATics2, AFlags: Integer);
    procedure ReadAction(out AAction: string; out ABright, AFast: Boolean);
  public
    constructor Create(AScanner: TScriptScanner; const ALog: ILog);
    /// <summary>The states of another thing start: nothing is kept</summary>
    procedure Start(const AOwner: IActorDefStateOwner);
    /// <summary>
    ///   Reads a line. ABase is the first state of the group of the label. False when the group
    ///   ends: the next word is not a state of it
    /// </summary>
    function Read(ABase: Integer): Boolean;
    /// <summary>The state that comes next of the last one when it is the end of the definition</summary>
    procedure CloseLastState;
    function States: TActorDefStates;
    property Count: Integer read FCount;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings, DelphiDoom.Scanner.Text, DelphiDoom.ActorDef.Text;

{ TActorDefStateReader }

constructor TActorDefStateReader.Create(AScanner: TScriptScanner; const ALog: ILog);
begin
  inherited Create;
  FScanner := AScanner;
  FLog := ALog;
  SetLength(FStates, ACTORDEF_MAX_STATES);
end;

procedure TActorDefStateReader.Start(const AOwner: IActorDefStateOwner);
begin
  FOwner := AOwner;
  FTokens := AOwner.LabelTokens;
  FCount := 0;
end;

function TActorDefStateReader.States: TActorDefStates;
begin
  Result := Copy(FStates, 0, FCount);
end;

procedure TActorDefStateReader.CloseLastState;
begin
  if FCount > 0 then
    if FStates[FCount - 1].NextState = FCount then
      FStates[FCount - 1].NextState := FCount - 1;
end;

function TActorDefStateReader.IsDefinitionKeyword(const AToken: string): Boolean;
begin
  Result := (AToken = 'ACTOR') or
    (AToken = 'WEAPON') or
    (AToken = 'ACTORALIAS') or
    (AToken = 'DEH_PARSE') or
    (AToken = 'DEH_PARSE_ALL') or
    (AToken = 'COMPILED') or
    (AToken = 'PRECOMPILED') or
    (AToken = 'EXTERNAL') or
    (AToken = 'SCRIPT') or
    (AToken = 'THINKER') or
    (AToken = 'GLOBAL');
end;

procedure TActorDefStateReader.ReadGoto;
var
  LGoto: string;
  LPosition: Integer;
  LTarget: Integer;
begin
  LGoto := TScannerStrings.UpperAscii(FScanner.GetStringEOL);
  LPosition := Pos('//', LGoto);
  if LPosition > 0 then
    LGoto := Copy(LGoto, 1, LPosition - 1);
  // the old code wrote before the first state when there was none
  if FCount = 0 then
    Exit;
  if FOwner.TryResolveLabel(LGoto, LTarget) then
  begin
    FStates[FCount - 1].NextState := LTarget;
    FStates[FCount - 1].HasGoto := True;
  end
  else
  begin
    FStates[FCount - 1].GotoNeedsCalc := True;
    FStates[FCount - 1].GotoText := LGoto;
  end;
end;

procedure TActorDefStateReader.ReadDuration(out ATics, ATics2, AFlags: Integer);
begin
  AFlags := 0;
  FScanner.GetString;
  if FScanner.MatchString('RANDOMSELECT') then
  begin
    FScanner.GetInteger;
    ATics := FScanner.AsInteger;
    FScanner.GetInteger;
    ATics2 := FScanner.AsInteger;
    AFlags := AFlags or ACTORDEF_STATE_RANDOM_SELECT;
  end
  else if FScanner.MatchString('RANDOMRANGE') then
  begin
    FScanner.GetInteger;
    ATics := FScanner.AsInteger;
    FScanner.GetInteger;
    ATics2 := FScanner.AsInteger;
    AFlags := AFlags or ACTORDEF_STATE_RANDOM_RANGE;
  end
  else
  begin
    ATics := TScannerStrings.ToInteger(FScanner.AsString);
    ATics2 := ATics;
  end;
end;

procedure TActorDefStateReader.ReadAction(out AAction: string; out ABright, AFast: Boolean);
var
  LToken: string;
  LText: string;
  LRest: string;
begin
  ABright := False;
  AFast := False;
  AAction := '';
  FScanner.GetString;
  if FScanner.NewLine then
    FScanner.UnGet
  else
  begin
    LToken := TScannerStrings.UpperAscii(FScanner.AsString);
    if LToken = 'BRIGHT' then
      LText := 'BRIGHT ' + TScannerText.RemoveLineComments(FScanner.GetStringEOLUnchanged)
    else if LToken = 'FAST' then
      LText := 'FAST ' + TScannerText.RemoveLineComments(FScanner.GetStringEOLUnchanged)
    else
    begin
      LRest := TScannerStrings.Trim(TScannerText.RemoveLineComments(FScanner.GetStringEOLUnchanged));
      if LRest <> '' then
      begin
        if LRest[Length(LRest)] = ')' then
          LRest := '(' + LRest;
        if LRest[1] <> '(' then
          LRest := ' ' + LRest;
      end;
      LText := FScanner.AsString + LRest;
    end;

    ABright := False;
    AFast := False;

    LText := TScannerStrings.Trim(LText);
    if TScannerStrings.UpperAscii(TActorDefText.FirstWord(LText)) = 'BRIGHT' then
    begin
      ABright := True;
      AAction := TScannerStrings.Trim(Copy(LText, 7, Length(LText) - 6));
    end
    else if TScannerStrings.UpperAscii(TActorDefText.LastWord(LText)) = 'BRIGHT' then
    begin
      ABright := True;
      AAction := TScannerStrings.Trim(Copy(LText, 1, Length(LText) - 6));
    end
    else
      AAction := LText;

    // MBF21 - Fast keyword (the old code cuts one character too many after a leading FAST)
    LText := TScannerStrings.Trim(AAction);
    if TScannerStrings.UpperAscii(TActorDefText.FirstWord(LText)) = 'FAST' then
    begin
      AFast := True;
      AAction := TScannerStrings.Trim(Copy(LText, 6, Length(LText) - 6));
    end
    else if TScannerStrings.UpperAscii(TActorDefText.LastWord(LText)) = 'FAST' then
    begin
      AFast := True;
      AAction := TScannerStrings.Trim(Copy(LText, 1, Length(LText) - 5));
    end
    else
      AAction := LText;

    // The fast keyword was first or last word
    if (not ABright) and AFast then
    begin
      LText := TScannerStrings.Trim(AAction);
      if TScannerStrings.UpperAscii(TActorDefText.FirstWord(LText)) = 'BRIGHT' then
      begin
        ABright := True;
        AAction := TScannerStrings.Trim(Copy(LText, 7, Length(LText) - 6));
      end
      else if TScannerStrings.UpperAscii(TActorDefText.LastWord(LText)) = 'BRIGHT' then
      begin
        ABright := True;
        AAction := TScannerStrings.Trim(Copy(LText, 1, Length(LText) - 6));
      end
      else
        AAction := LText;
    end;
  end;

  if AAction = '' then
    AAction := 'A_Null';
end;

function TActorDefStateReader.Read(ABase: Integer): Boolean;
var
  LToken: string;
  LLevel: Integer;
  LAlias: string;
  LSaveAlias: string;
  LSprite: string;
  LFrames: string;
  LTics: Integer;
  LTics2: Integer;
  LStateFlags: Integer;
  LAction: string;
  LBright: Boolean;
  LFast: Boolean;
  LIndex: Integer;
  LState: TActorDefState;
begin
  Result := False;
  if FScanner.Finished then
    Exit;

  FScanner.GetString;
  LToken := TScannerStrings.UpperAscii(FScanner.AsString);
  if LToken = 'LOOP' then
  begin
    if FCount > 0 then
      FStates[FCount - 1].NextState := ABase;
    LLevel := FScanner.BracketLevel;
    if FScanner.GetString then
    begin
      if LLevel = FScanner.BracketLevel then
        if Pos(':', FScanner.AsString) < 1 then
          Result := True; // the definition is not finished: same bracket level and not a new state
      FScanner.UnGet;
    end;
    Exit;
  end
  else if LToken = 'STOP' then
  begin
    if FCount > 0 then
      FStates[FCount - 1].NextState := -1; // none
    Exit;
  end
  else if LToken = 'WAIT' then
  begin
    if FCount > 0 then
      FStates[FCount - 1].NextState := FCount - 1; // the same state
    Exit;
  end
  else if IsDefinitionKeyword(LToken) then
  begin
    if FCount > 0 then
      if not FStates[FCount - 1].HasGoto then
        FStates[FCount - 1].NextState := -1;
    FScanner.UnGet;
    Exit;
  end
  else if LToken = 'GOTO' then
  begin
    ReadGoto;
    Result := FScanner.MatchString(FTokens) = -1;
    Exit;
  end;

  Result := FScanner.MatchString(FTokens) = -1;
  if not Result then
  begin
    FScanner.UnGet;
    Exit;
  end;

  if FScanner.BracketLevel = 0 then
  begin
    if FCount > 0 then
      if not FStates[FCount - 1].HasGoto then
        FStates[FCount - 1].NextState := FCount - 1; // finished without a stop keyword
    Result := False;
    FScanner.UnGet;
    Exit;
  end;

  Result := True;

  LAlias := FScanner.AsString;
  LSaveAlias := '';
  if LAlias <> '' then
  begin
    if LAlias[Length(LAlias)] = ':' then
    begin
      SetLength(LAlias, Length(LAlias) - 1);
      LSaveAlias := LAlias;
      LAlias := FOwner.AliasFor(LAlias);
      FScanner.GetString;
    end
    else
      LAlias := '';
  end;

  LSprite := FScanner.AsString;
  FScanner.GetString;
  LFrames := FScanner.AsString;

  ReadDuration(LTics, LTics2, LStateFlags);
  ReadAction(LAction, LBright, LFast);

  for LIndex := 1 to Length(LFrames) do
  begin
    if FCount = ACTORDEF_MAX_STATES then
    begin
      if Assigned(FLog) then
        FLog.Warning(Format('SC_ActordefToDEH(): Object has more than %d states'#13#10,
          [ACTORDEF_MAX_STATES]));
      Break;
    end;
    LState := Default(TActorDefState);
    LState.Sprite := LSprite;
    LState.Frame := Ord(LFrames[LIndex]) - Ord('A');
    LState.Tics := LTics;
    LState.Tics2 := LTics2;
    LState.FlagsEx := LStateFlags;
    LState.Action := LAction;
    LState.NextState := FCount + 1;
    LState.Bright := LBright;
    LState.Fast := LFast;
    LState.Alias := LAlias;
    LState.SaveAlias := LSaveAlias;
    LAlias := ''; // alias only for the first state
    LSaveAlias := '';
    FStates[FCount] := LState;
    Inc(FCount);
  end;
end;

end.
