{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the line functions of PS_GAME                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  TLine and the functions of the vertexes, special, arguments, flags, sides   }
{  and sectors of a line, and (not in Hexen, that has no tag) the tag, the     }
{  transparency and FindLinesFromTag (the PS_*Line* of psi_game.pas).          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.World.Lines;

interface

uses
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Types,
  DelphiDoom.ScriptHost.World.Intf;

type
  /// <summary>The line functions of the unit PS_GAME (called with the object as Self)</summary>
  TScriptLines = class(TInterfacedObject, IScriptLines, IScriptFunctionSection)
  strict private
    FWorld: IScriptWorld;
    FGame: TScriptGame;
    /// <summary>True if both sides of the line are numbers of sides of the level (the flags of a line can be changed only then)</summary>
    function HasBothSides(const ALine: Integer): Boolean;
  public
    /// <exception cref="EArgumentNilException">If the world is nil</exception>
    constructor Create(const AWorld: IScriptWorld; const AGame: TScriptGame);
    procedure Describe(const ATable: IScriptFunctionTable);
    function TLine(const AId: Integer): Integer;
    function GetLineVertex1(const ALine: Integer): Integer;
    function GetLineVertex2(const ALine: Integer): Integer;
    function GetLineSpecial(const ALine: Integer): Integer;
    procedure SetLineSpecial(const ALine: Integer; const ASpecial: Integer);
    function GetLineDX(const ALine: Integer): Integer;
    function GetLineDY(const ALine: Integer): Integer;
    function GetLineArgument(const ALine: Integer; const AArgument: Integer): Byte;
    procedure SetLineArgument(const ALine: Integer; const AArgument: Integer; const AValue: Byte);
    function GetLineTag(const ALine: Integer): Integer;
    procedure SetLineTag(const ALine: Integer; const ATag: Integer);
    /// <summary>
    ///   The state of a flag; the flags that change the line only when it has two sides
    ///   (blocking, blocking monsters, transparent) are read always
    /// </summary>
    function GetLineFlag(const ALine: Integer; const AFlag: TScriptLineFlag): Boolean;
    procedure SetLineFlag(const ALine: Integer; const AFlag: TScriptLineFlag; const AValue: Boolean);
    function GetLineFrontSide(const ALine: Integer): Integer;
    function GetLineBackSide(const ALine: Integer): Integer;
    function GetLineFrontSector(const ALine: Integer): Integer;
    function GetLineBackSector(const ALine: Integer): Integer;
    function IsValidLine(const ALine: Integer): Boolean;
    function GetLineCount: Integer;
    // the methods below are the ones that scripts call: the names of the scripts are in Describe
    function GetLineArg1(const ALine: Integer): Byte;
    procedure SetLineArg1(const ALine: Integer; const AValue: Byte);
    function GetLineArg2(const ALine: Integer): Byte;
    procedure SetLineArg2(const ALine: Integer; const AValue: Byte);
    function GetLineArg3(const ALine: Integer): Byte;
    procedure SetLineArg3(const ALine: Integer; const AValue: Byte);
    function GetLineArg4(const ALine: Integer): Byte;
    procedure SetLineArg4(const ALine: Integer; const AValue: Byte);
    function GetLineArg5(const ALine: Integer): Byte;
    procedure SetLineArg5(const ALine: Integer; const AValue: Byte);
    function GetLineTransparent(const ALine: Integer): Boolean;
    procedure SetLineTransparent(const ALine: Integer; const AValue: Boolean);
    function GetLineIsBlocking(const ALine: Integer): Boolean;
    procedure SetLineIsBlocking(const ALine: Integer; const AValue: Boolean);
    function GetLineIsBlockingMonsters(const ALine: Integer): Boolean;
    procedure SetLineIsBlockingMonsters(const ALine: Integer; const AValue: Boolean);
    function GetLineTriggerScripts(const ALine: Integer): Boolean;
    procedure SetLineTriggerScripts(const ALine: Integer; const AValue: Boolean);
    /// <summary>The numbers of the lines that have a tag, in the order of the level</summary>
    function FindLinesFromTag(const ATag: Integer): TArray<Integer>;
  end;

implementation

uses
  System.SysUtils;

{ TScriptLines }

constructor TScriptLines.Create(const AWorld: IScriptWorld; const AGame: TScriptGame);
begin
  inherited Create;
  if not Assigned(AWorld) then
    raise EArgumentNilException.Create('AWorld');
  FWorld := AWorld;
  FGame := AGame;
end;

procedure TScriptLines.Describe(const ATable: IScriptFunctionTable);
begin
  ATable.AddMethodWithCustomResult('procedure TLine(const id: Integer);', '!TLine',
    'function TLine(const id: Integer): !TLine;', Self, @TScriptLines.TLine);
  ATable.AddMethod('function GetLineVertex1(const ld: Integer): integer;', Self,
    @TScriptLines.GetLineVertex1);
  ATable.AddMethod('function GetLineVertex2(const ld: Integer): integer;', Self,
    @TScriptLines.GetLineVertex2);
  ATable.AddMethod('function GetLineDX(const ld: Integer): fixed_t;', Self, @TScriptLines.GetLineDX);
  ATable.AddMethod('function GetLineDY(const ld: Integer): fixed_t;', Self, @TScriptLines.GetLineDY);
  ATable.AddMethod('function GetLineSpecial(const ld: Integer): integer;', Self,
    @TScriptLines.GetLineSpecial);
  ATable.AddMethod('procedure SetLineSpecial(const ld: Integer; const spec: integer);', Self,
    @TScriptLines.SetLineSpecial);
  ATable.AddMethod('function GetLineArg1(const ld: Integer): byte;', Self, @TScriptLines.GetLineArg1);
  ATable.AddMethod('procedure SetLineArg1(const ld: Integer; const arg: byte);', Self,
    @TScriptLines.SetLineArg1);
  ATable.AddMethod('function GetLineArg2(const ld: Integer): byte;', Self, @TScriptLines.GetLineArg2);
  ATable.AddMethod('procedure SetLineArg2(const ld: Integer; const arg: byte);', Self,
    @TScriptLines.SetLineArg2);
  ATable.AddMethod('function GetLineArg3(const ld: Integer): byte;', Self, @TScriptLines.GetLineArg3);
  ATable.AddMethod('procedure SetLineArg3(const ld: Integer; const arg: byte);', Self,
    @TScriptLines.SetLineArg3);
  ATable.AddMethod('function GetLineArg4(const ld: Integer): byte;', Self, @TScriptLines.GetLineArg4);
  ATable.AddMethod('procedure SetLineArg4(const ld: Integer; const arg: byte);', Self,
    @TScriptLines.SetLineArg4);
  ATable.AddMethod('function GetLineArg5(const ld: Integer): byte;', Self, @TScriptLines.GetLineArg5);
  ATable.AddMethod('procedure SetLineArg5(const ld: Integer; const arg: byte);', Self,
    @TScriptLines.SetLineArg5);
  // Hexen has no tag on its lines (it has arguments) and no transparent lines
  if FGame <> sgHexen then
  begin
    ATable.AddMethod('function GetLineTag(const ld: Integer): integer;', Self,
      @TScriptLines.GetLineTag);
    ATable.AddMethod('procedure SetLineTag(const ld: Integer; const tag: integer);', Self,
      @TScriptLines.SetLineTag);
    ATable.AddMethod('function GetLineTransparent(const ld: Integer): Boolean;', Self,
      @TScriptLines.GetLineTransparent);
    ATable.AddMethod('procedure SetLineTransparent(const ld: Integer; const x: Boolean);', Self,
      @TScriptLines.SetLineTransparent);
  end;
  ATable.AddMethod('function GetLineIsBlocking(const ld: Integer): Boolean;', Self,
    @TScriptLines.GetLineIsBlocking);
  ATable.AddMethod('procedure SetLineIsBlocking(const ld: Integer; const x: Boolean);', Self,
    @TScriptLines.SetLineIsBlocking);
  ATable.AddMethod('function GetLineIsBlockingMonsters(const ld: Integer): Boolean;', Self,
    @TScriptLines.GetLineIsBlockingMonsters);
  ATable.AddMethod('procedure SetLineIsBlockingMonsters(const ld: Integer; const x: Boolean);', Self,
    @TScriptLines.SetLineIsBlockingMonsters);
  ATable.AddMethod('function GetLineTriggerScripts(const ld: Integer): Boolean;', Self,
    @TScriptLines.GetLineTriggerScripts);
  ATable.AddMethod('procedure SetLineTriggerScripts(const ld: Integer; const x: Boolean);', Self,
    @TScriptLines.SetLineTriggerScripts);
  ATable.AddMethod('function GetLineFrontSide(const ld: Integer): integer;', Self,
    @TScriptLines.GetLineFrontSide);
  ATable.AddMethod('function GetLineBackSide(const ld: Integer): integer;', Self,
    @TScriptLines.GetLineBackSide);
  ATable.AddMethod('function GetLineFrontSector(const ld: Integer): integer;', Self,
    @TScriptLines.GetLineFrontSector);
  ATable.AddMethod('function GetLineBackSector(const ld: Integer): integer;', Self,
    @TScriptLines.GetLineBackSector);
  ATable.AddMethod('function IsValidLine(const ld: Integer): boolean;', Self,
    @TScriptLines.IsValidLine);
  ATable.AddMethod('function GetLineCount: Integer;', Self, @TScriptLines.GetLineCount);
  if FGame <> sgHexen then
    ATable.AddMethod('function FindLinesFromTag(const tag: integer): TIntegerArray;', Self,
      @TScriptLines.FindLinesFromTag);
end;

function TScriptLines.HasBothSides(const ALine: Integer): Boolean;
var
  LSide: Integer;
begin
  LSide := FWorld.LineSideNumber(ALine, False);
  if (LSide < 0) or (LSide >= FWorld.SideCount) then
  begin
    Result := False;
    Exit;
  end;
  LSide := FWorld.LineSideNumber(ALine, True);
  Result := (LSide >= 0) and (LSide < FWorld.SideCount);
end;

function TScriptLines.TLine(const AId: Integer): Integer;
begin
  if IsValidLine(AId) then
    Result := AId + 1
  else
    Result := SCRIPT_INVALID_ID;
end;

function TScriptLines.GetLineVertex1(const ALine: Integer): Integer;
begin
  if IsValidLine(ALine) then
    Result := FWorld.LineVertex(ALine, False)
  else
    Result := SCRIPT_INVALID_ID;
end;

function TScriptLines.GetLineVertex2(const ALine: Integer): Integer;
begin
  if IsValidLine(ALine) then
    Result := FWorld.LineVertex(ALine, True)
  else
    Result := SCRIPT_INVALID_ID;
end;

function TScriptLines.GetLineSpecial(const ALine: Integer): Integer;
begin
  if IsValidLine(ALine) then
    Result := FWorld.LineSpecial(ALine)
  else
    Result := 0;
end;

procedure TScriptLines.SetLineSpecial(const ALine: Integer; const ASpecial: Integer);
begin
  if IsValidLine(ALine) then
    FWorld.SetLineSpecial(ALine, ASpecial);
end;

function TScriptLines.GetLineDX(const ALine: Integer): Integer;
begin
  if IsValidLine(ALine) then
    Result := FWorld.LineDeltaX(ALine)
  else
    Result := 0;
end;

function TScriptLines.GetLineDY(const ALine: Integer): Integer;
begin
  if IsValidLine(ALine) then
    Result := FWorld.LineDeltaY(ALine)
  else
    Result := 0;
end;

function TScriptLines.GetLineArgument(const ALine: Integer; const AArgument: Integer): Byte;
begin
  if IsValidLine(ALine) then
    // the games that keep an argument in an integer give its low byte, as the old assignment did
    Result := Byte(FWorld.LineArgument(ALine, AArgument))
  else
    Result := 0;
end;

procedure TScriptLines.SetLineArgument(const ALine: Integer; const AArgument: Integer;
  const AValue: Byte);
begin
  if IsValidLine(ALine) then
    FWorld.SetLineArgument(ALine, AArgument, AValue);
end;

function TScriptLines.GetLineTag(const ALine: Integer): Integer;
begin
  if IsValidLine(ALine) then
    Result := FWorld.LineTag(ALine)
  else
    Result := 0;
end;

procedure TScriptLines.SetLineTag(const ALine: Integer; const ATag: Integer);
begin
  if IsValidLine(ALine) then
    FWorld.SetLineTag(ALine, ATag);
end;

function TScriptLines.GetLineFlag(const ALine: Integer; const AFlag: TScriptLineFlag): Boolean;
begin
  if IsValidLine(ALine) then
    Result := FWorld.LineHasFlag(ALine, AFlag)
  else
    Result := False;
end;

procedure TScriptLines.SetLineFlag(const ALine: Integer; const AFlag: TScriptLineFlag;
  const AValue: Boolean);
begin
  if not IsValidLine(ALine) then
    Exit;
  // the scripts of the old code could not change these flags of a line that has not two sides
  if (AFlag <> slfTriggerScripts) and not HasBothSides(ALine) then
    Exit;
  FWorld.SetLineFlag(ALine, AFlag, AValue);
end;

function TScriptLines.GetLineFrontSide(const ALine: Integer): Integer;
begin
  if IsValidLine(ALine) then
    Result := FWorld.LineSideNumber(ALine, False)
  else
    Result := SCRIPT_INVALID_ID;
end;

function TScriptLines.GetLineBackSide(const ALine: Integer): Integer;
begin
  if IsValidLine(ALine) then
    Result := FWorld.LineSideNumber(ALine, True)
  else
    Result := SCRIPT_INVALID_ID;
end;

function TScriptLines.GetLineFrontSector(const ALine: Integer): Integer;
begin
  if IsValidLine(ALine) then
    Result := FWorld.LineSectorId(ALine, False)
  else
    Result := SCRIPT_WORLD_NO_SECTOR;
  if Result < 0 then
    Result := SCRIPT_INVALID_ID;
end;

function TScriptLines.GetLineBackSector(const ALine: Integer): Integer;
begin
  if IsValidLine(ALine) then
    Result := FWorld.LineSectorId(ALine, True)
  else
    Result := SCRIPT_WORLD_NO_SECTOR;
  if Result < 0 then
    Result := SCRIPT_INVALID_ID;
end;

function TScriptLines.IsValidLine(const ALine: Integer): Boolean;
begin
  Result := (ALine >= 0) and (ALine < FWorld.LineCount);
end;

function TScriptLines.GetLineCount: Integer;
begin
  Result := FWorld.LineCount;
end;

function TScriptLines.GetLineArg1(const ALine: Integer): Byte;
begin
  Result := GetLineArgument(ALine, 0);
end;

procedure TScriptLines.SetLineArg1(const ALine: Integer; const AValue: Byte);
begin
  SetLineArgument(ALine, 0, AValue);
end;

function TScriptLines.GetLineArg2(const ALine: Integer): Byte;
begin
  Result := GetLineArgument(ALine, 1);
end;

procedure TScriptLines.SetLineArg2(const ALine: Integer; const AValue: Byte);
begin
  SetLineArgument(ALine, 1, AValue);
end;

function TScriptLines.GetLineArg3(const ALine: Integer): Byte;
begin
  Result := GetLineArgument(ALine, 2);
end;

procedure TScriptLines.SetLineArg3(const ALine: Integer; const AValue: Byte);
begin
  SetLineArgument(ALine, 2, AValue);
end;

function TScriptLines.GetLineArg4(const ALine: Integer): Byte;
begin
  Result := GetLineArgument(ALine, 3);
end;

procedure TScriptLines.SetLineArg4(const ALine: Integer; const AValue: Byte);
begin
  SetLineArgument(ALine, 3, AValue);
end;

function TScriptLines.GetLineArg5(const ALine: Integer): Byte;
begin
  Result := GetLineArgument(ALine, 4);
end;

procedure TScriptLines.SetLineArg5(const ALine: Integer; const AValue: Byte);
begin
  SetLineArgument(ALine, 4, AValue);
end;

function TScriptLines.GetLineTransparent(const ALine: Integer): Boolean;
begin
  Result := GetLineFlag(ALine, slfTransparent);
end;

procedure TScriptLines.SetLineTransparent(const ALine: Integer; const AValue: Boolean);
begin
  SetLineFlag(ALine, slfTransparent, AValue);
end;

function TScriptLines.GetLineIsBlocking(const ALine: Integer): Boolean;
begin
  Result := GetLineFlag(ALine, slfBlocking);
end;

procedure TScriptLines.SetLineIsBlocking(const ALine: Integer; const AValue: Boolean);
begin
  SetLineFlag(ALine, slfBlocking, AValue);
end;

function TScriptLines.GetLineIsBlockingMonsters(const ALine: Integer): Boolean;
begin
  Result := GetLineFlag(ALine, slfBlockMonsters);
end;

procedure TScriptLines.SetLineIsBlockingMonsters(const ALine: Integer; const AValue: Boolean);
begin
  SetLineFlag(ALine, slfBlockMonsters, AValue);
end;

function TScriptLines.GetLineTriggerScripts(const ALine: Integer): Boolean;
begin
  Result := GetLineFlag(ALine, slfTriggerScripts);
end;

procedure TScriptLines.SetLineTriggerScripts(const ALine: Integer; const AValue: Boolean);
begin
  SetLineFlag(ALine, slfTriggerScripts, AValue);
end;

function TScriptLines.FindLinesFromTag(const ATag: Integer): TArray<Integer>;
var
  LIndex: Integer;
  LCount: Integer;
begin
  SetLength(Result, 0);
  LCount := 0;
  for LIndex := 0 to FWorld.LineCount - 1 do
    if FWorld.LineTag(LIndex) = ATag then
    begin
      SetLength(Result, LCount + 1);
      Result[LCount] := LIndex;
      Inc(LCount);
    end;
end;

end.
