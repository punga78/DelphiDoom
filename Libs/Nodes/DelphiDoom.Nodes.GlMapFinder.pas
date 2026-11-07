{******************************************************************************}
{                                                                              }
{  DelphiDoom: Nodes library - the GL nodes that belong to a map               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Nodes.GlMapFinder;

interface

uses
  System.SysUtils, DelphiDoom.Nodes.Intf;

type
  /// <summary>
  ///   glBSP writes before its GL lumps a label (GL_MAP01, or GL_LEVEL when the name of the map
  ///   is longer than five characters) with a text: LEVEL= (or MAPNAME=), CHECKSUM= (Adler-32 of VERTEXES and
  ///   LINEDEFS of the map). The nodes belong to the map when the checksum is the one of the map.
  ///   The finder looks at the label of that name (the last one first), then at every other lump
  ///   of that name after the map, at the GL_LEVEL ones and at the ones before the map
  /// </summary>
  TNodesGlMapFinder = class(TInterfacedObject, INodesGlMapFinder)
  strict private
    FSource: INodesLumpSource;
    function ChecksumOf(ALabel: Integer; const AGlMapName: string): Cardinal;
    function MatchesAt(ALump: Integer; const AGlMapName: string; AChecksum: Cardinal): Boolean;
  public
    constructor Create(const ASource: INodesLumpSource);
    function FindGlMapLump(AMapLump: Integer): Integer;
    /// <summary>
    ///   The checksum written in the text of a label, or 0 if it has none or the label is for
    ///   another map. AGlMapName is the name GL_xxx that is being looked for
    /// </summary>
    class function ChecksumOfText(const AText: string; const ALabelName, AGlMapName: string): Cardinal; static;
  end;

implementation

uses
  DelphiDoom.Nodes.Types, DelphiDoom.Nodes.Adler32;

const
  GL_NAME_PREFIX = 'GL_';
  KEY_CHECKSUM = 'CHECKSUM';
  KEY_MAPNAME = 'MAPNAME';
  // what glBSP writes in the label of a map with a long name (the old code looked for MAPNAME only)
  KEY_LEVEL = 'LEVEL';

function UpperAscii(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := AText;
  for LIndex := 1 to Length(Result) do
    if (Result[LIndex] >= 'a') and (Result[LIndex] <= 'z') then
      Dec(Result[LIndex], 32);
end;

function TrimControl(const AText: string): string;
var
  LFirst: Integer;
  LLast: Integer;
begin
  // as the old trimproc: everything up to the space goes
  LFirst := 1;
  LLast := Length(AText);
  while (LFirst <= LLast) and (AText[LFirst] <= ' ') do
    Inc(LFirst);
  while (LLast >= LFirst) and (AText[LLast] <= ' ') do
    Dec(LLast);
  Result := Copy(AText, LFirst, LLast - LFirst + 1);
end;

function ParseUnsigned(const AText: string): Cardinal;
var
  LCode: Integer;
  LValue: Cardinal;
begin
  // the old atoui: Val (decimal, $ and 0x), then #decimal; a bad text is 0
  Val(AText, LValue, LCode);
  if LCode = 0 then
    Exit(LValue);
  if (Length(AText) > 1) and (AText[1] = '#') then
  begin
    Val(Copy(AText, 2, Length(AText) - 1), LValue, LCode);
    if LCode = 0 then
      Exit(LValue);
  end;
  Result := 0;
end;

{ TNodesGlMapFinder }

constructor TNodesGlMapFinder.Create(const ASource: INodesLumpSource);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  FSource := ASource;
end;

class function TNodesGlMapFinder.ChecksumOfText(const AText: string; const ALabelName,
  AGlMapName: string): Cardinal;
var
  LLines: TArray<string>;
  LLine: string;
  LCurrent: string;
  LIndex: Integer;
  LCheck: Boolean;
  LKey: string;
  LValue: string;
  LSeparator: Integer;

  procedure AddLine;
  begin
    if LCurrent <> '' then
    begin
      SetLength(LLines, Length(LLines) + 1);
      LLines[High(LLines)] := LCurrent;
      LCurrent := '';
    end;
  end;

begin
  LCurrent := '';
  for LIndex := 1 to Length(AText) do
    if (AText[LIndex] = #10) or (AText[LIndex] = #13) then
      AddLine
    else if AText[LIndex] = #0 then
      // the engine read a zero byte of a text lump as a space
      LCurrent := LCurrent + ' '
    else
      LCurrent := LCurrent + UpperAscii(AText[LIndex]);
  AddLine;

  Result := 0;
  LCheck := UpperAscii(AGlMapName) = UpperAscii(ALabelName);
  for LLine in LLines do
  begin
    LSeparator := Pos('=', LLine);
    if LSeparator = 0 then
    begin
      LKey := LLine;
      LValue := '';
    end
    else
    begin
      LKey := TrimControl(Copy(LLine, 1, LSeparator - 1));
      LValue := TrimControl(Copy(LLine, LSeparator + 1, Length(LLine)));
    end;
    if LKey = KEY_CHECKSUM then
      Result := ParseUnsigned(LValue)
    else if (not LCheck) and ((LKey = KEY_MAPNAME) or (LKey = KEY_LEVEL)) then
    begin
      // another map?
      LCheck := (UpperAscii(AGlMapName) = LValue) or
        (UpperAscii(AGlMapName) = GL_NAME_PREFIX + LValue);
      if not LCheck then
        Break;
    end;
  end;

  if not LCheck then
    Result := 0;
end;

function TNodesGlMapFinder.ChecksumOf(ALabel: Integer; const AGlMapName: string): Cardinal;
var
  LBytes: TBytes;
  LText: string;
  LIndex: Integer;
begin
  if (ALabel < 0) or (ALabel >= FSource.LumpCount) then
    Exit(0);
  LBytes := FSource.ReadLump(ALabel);
  SetLength(LText, Length(LBytes));
  for LIndex := 0 to High(LBytes) do
    LText[LIndex + 1] := Char(LBytes[LIndex]);
  Result := ChecksumOfText(LText, FSource.LumpName(ALabel), AGlMapName);
end;

function TNodesGlMapFinder.MatchesAt(ALump: Integer; const AGlMapName: string;
  AChecksum: Cardinal): Boolean;
begin
  Result := ChecksumOf(ALump, AGlMapName) = AChecksum;
end;

function TNodesGlMapFinder.FindGlMapLump(AMapLump: Integer): Integer;
var
  LChecksum: Cardinal;
  LGlMapName: string;
  LFirst: Integer;
  LIndex: Integer;
begin
  Result := -1;
  LChecksum := TNodesAdler32.OfMap(FSource, AMapLump);
  if LChecksum = 0 then
    Exit;

  LGlMapName := GL_NAME_PREFIX + FSource.LumpName(AMapLump);
  if Length(LGlMapName) <= NODES_LUMP_NAME_LENGTH then
  begin
    // the last lump with the name
    LFirst := FSource.FindLump(LGlMapName);
    if MatchesAt(LFirst, LGlMapName, LChecksum) then
      Exit(LFirst);
    // every other lump with that name after the map
    for LIndex := AMapLump + NODES_MAP_BLOCKMAP + 1 to FSource.LumpCount - 1 do
      if (LIndex <> LFirst) and SameText(FSource.LumpName(LIndex), LGlMapName) and
         MatchesAt(LIndex, LGlMapName, LChecksum) then
        Exit(LIndex);
  end;

  // GL_LEVEL labels, anywhere
  for LIndex := 0 to FSource.LumpCount - 1 do
    if SameText(FSource.LumpName(LIndex), NODES_LUMP_GL_LEVEL) and
       MatchesAt(LIndex, LGlMapName, LChecksum) then
      Exit(LIndex);

  // and the ones before the map
  if Length(LGlMapName) <= NODES_LUMP_NAME_LENGTH then
    for LIndex := 0 to AMapLump - 1 do
      if SameText(FSource.LumpName(LIndex), LGlMapName) and
         MatchesAt(LIndex, LGlMapName, LChecksum) then
        Exit(LIndex);
end;

end.
