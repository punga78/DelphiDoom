{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the texture definitions library - the corpus           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TextureDefs.Corpus;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  TCorpusPatch = record
    Index: Integer;
    OriginX: Integer;
    OriginY: Integer;
  end;

  TCorpusTexture = record
    Name: string;
    Width: Integer;
    Height: Integer;
    Masked: Integer;
    PatchCount: Integer;
    Patches: TArray<TCorpusPatch>;
  end;

  /// <summary>
  ///   One case of Tests\Data\TextureDefs\cases.txt: it builds the bytes of the lumps with
  ///   explicit offsets (it does not use the records of the library, so that the layout is
  ///   written twice). The unit is also used by the harness that wrote the golden files: it
  ///   does not depend on the library
  /// </summary>
  TTextureDefsCase = class
  private
    FName: string;
    FStrife: Boolean;
    FIsFlats: Boolean;
    FPatchNames: TArray<string>;
    FTextures: array[1..3] of TList<TCorpusTexture>;
    FEmpty: array[1..3] of Boolean;
    FBadOffset: array[1..3] of Integer;
    FPk3: TList<TCorpusTexture>;
    FFlats: TArray<string>;
    FText: string;
    function BuildTextureLump(AList: TList<TCorpusTexture>; ABadOffset: Integer): TBytes;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;
    procedure ParseLine(const ALine: string);
    function BuildPatchNames: TBytes;
    function HasTextureLump(ANumber: Integer): Boolean;
    function BuildTextureLumpNumber(ANumber: Integer): TBytes;
    function HasPk3: Boolean;
    function BuildPk3Lump: TBytes;
    property Name: string read FName;
    property IsStrife: Boolean read FStrife;
    property IsFlats: Boolean read FIsFlats;
    property PatchNames: TArray<string> read FPatchNames;
    property Flats: TArray<string> read FFlats;
    property Text: string read FText;
  end;

  TTextureDefsCorpus = class
  public
    class function Load(const AFileName: string): TObjectList<TTextureDefsCase>; static;
    /// <summary>One case from lines in the grammar of cases.txt, for the tests that need a small lump</summary>
    class function FromLines(const ALines: array of string): TTextureDefsCase; static;
    /// <summary>FNV-1a, 32 bit, of the UTF-8 bytes of the text: the digest of the dumps of the real WADs</summary>
    class function Fnv32(const AText: string): Cardinal; static;
  end;

  /// <summary>A WAD read into memory: a lump is found by name, the last one wins (as in the engine)</summary>
  TCorpusWad = class
  private
    FBytes: TBytes;
    FCount: Integer;
    FDirectory: Integer;
  public
    constructor Create(const AFileName: string);
    function TryReadLump(const AName: string; out ABytes: TBytes): Boolean;
  end;

implementation

procedure PutInt16(var ABuffer: TBytes; AOffset: Integer; AValue: Integer);
begin
  ABuffer[AOffset] := AValue and $FF;
  ABuffer[AOffset + 1] := (AValue shr 8) and $FF;
end;

procedure PutInt32(var ABuffer: TBytes; AOffset: Integer; AValue: Integer);
begin
  PutInt16(ABuffer, AOffset, AValue and $FFFF);
  PutInt16(ABuffer, AOffset + 2, (AValue shr 16) and $FFFF);
end;

procedure PutName(var ABuffer: TBytes; AOffset: Integer; const AName: string);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AName) do
    if LIndex <= 8 then
      ABuffer[AOffset + LIndex - 1] := Ord(AName[LIndex]);
end;

function Words(const ALine: string): TArray<string>;
begin
  Result := ALine.Split([' '], TStringSplitOptions.ExcludeEmpty);
end;

{ TTextureDefsCase }

constructor TTextureDefsCase.Create(const AName: string);
var
  LIndex: Integer;
begin
  inherited Create;
  FName := AName;
  for LIndex := 1 to 3 do
  begin
    FTextures[LIndex] := TList<TCorpusTexture>.Create;
    FBadOffset[LIndex] := -1;
  end;
  FPk3 := TList<TCorpusTexture>.Create;
end;

destructor TTextureDefsCase.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 3 do
    FTextures[LIndex].Free;
  FPk3.Free;
  inherited Destroy;
end;

procedure TTextureDefsCase.ParseLine(const ALine: string);
var
  LWords: TArray<string>;
  LKey: string;
  LTexture: TCorpusTexture;
  LPatch: TCorpusPatch;
  LParts: TArray<string>;
  LIndex: Integer;
begin
  LWords := Words(ALine);
  if Length(LWords) = 0 then
    Exit;
  LKey := LWords[0];
  if LKey = 'format' then
    FStrife := LWords[1] = 'strife'
  else if LKey = 'kind' then
    FIsFlats := LWords[1] = 'flats'
  else if LKey = 'pnames' then
  begin
    SetLength(FPatchNames, Length(LWords) - 1);
    for LIndex := 1 to High(LWords) do
      FPatchNames[LIndex - 1] := LWords[LIndex].Replace('~', ' ');
  end
  else if (LKey = 'tex1') or (LKey = 'tex2') or (LKey = 'tex3') then
  begin
    LTexture := Default(TCorpusTexture);
    LTexture.Name := LWords[1].Replace('~', ' ');
    LTexture.Width := StrToInt(LWords[2]);
    LTexture.Height := StrToInt(LWords[3]);
    LTexture.Masked := StrToInt(LWords[4]);
    SetLength(LTexture.Patches, Length(LWords) - 5);
    for LIndex := 5 to High(LWords) do
    begin
      LParts := LWords[LIndex].Split([',']);
      LPatch.Index := StrToInt(LParts[0]);
      LPatch.OriginX := StrToInt(LParts[1]);
      LPatch.OriginY := StrToInt(LParts[2]);
      LTexture.Patches[LIndex - 5] := LPatch;
    end;
    LTexture.PatchCount := Length(LTexture.Patches);
    FTextures[StrToInt(Copy(LKey, 4, 1))].Add(LTexture);
  end
  else if (LKey = 'empty2') or (LKey = 'empty3') then
    FEmpty[StrToInt(Copy(LKey, 6, 1))] := True
  else if LKey = 'badoffset1' then
    FBadOffset[1] := StrToInt(LWords[1])
  else if LKey = 'pk3' then
  begin
    // pk3 NAME W H PATCHCOUNT-FIELD ORIGINX ORIGINY
    LTexture := Default(TCorpusTexture);
    LTexture.Name := LWords[1];
    LTexture.Width := StrToInt(LWords[2]);
    LTexture.Height := StrToInt(LWords[3]);
    LTexture.PatchCount := StrToInt(LWords[4]);
    SetLength(LTexture.Patches, 1);
    LTexture.Patches[0].Index := 0;
    LTexture.Patches[0].OriginX := StrToInt(LWords[5]);
    LTexture.Patches[0].OriginY := StrToInt(LWords[6]);
    FPk3.Add(LTexture);
  end
  else if LKey = 'flats' then
  begin
    SetLength(FFlats, Length(LWords) - 1);
    for LIndex := 1 to High(LWords) do
      FFlats[LIndex - 1] := LWords[LIndex];
  end
  else if LKey = 'text' then
    FText := Copy(ALine, 6, MaxInt).Replace('|', #13#10);
end;

function TTextureDefsCase.BuildPatchNames: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, 4 + Length(FPatchNames) * 8);
  PutInt32(Result, 0, Length(FPatchNames));
  for LIndex := 0 to High(FPatchNames) do
    PutName(Result, 4 + LIndex * 8, FPatchNames[LIndex]);
end;

function TTextureDefsCase.HasTextureLump(ANumber: Integer): Boolean;
begin
  Result := (ANumber = 1) or FEmpty[ANumber] or (FTextures[ANumber].Count > 0);
end;

function TTextureDefsCase.BuildTextureLump(AList: TList<TCorpusTexture>; ABadOffset: Integer): TBytes;
var
  LHeader: Integer;
  LPatchSize: Integer;
  LIndex: Integer;
  LPatchIndex: Integer;
  LTotal: Integer;
  LOffset: Integer;
  LTexture: TCorpusTexture;
  LPatchOffset: Integer;
begin
  if FStrife then
  begin
    LHeader := 18;
    LPatchSize := 6;
  end
  else
  begin
    LHeader := 22;
    LPatchSize := 10;
  end;
  LTotal := 4 + AList.Count * 4;
  for LIndex := 0 to AList.Count - 1 do
    Inc(LTotal, LHeader + Length(AList[LIndex].Patches) * LPatchSize);
  SetLength(Result, LTotal);
  PutInt32(Result, 0, AList.Count);
  LOffset := 4 + AList.Count * 4;
  for LIndex := 0 to AList.Count - 1 do
  begin
    LTexture := AList[LIndex];
    if LIndex = ABadOffset then
      PutInt32(Result, 4 + LIndex * 4, LTotal + 100)
    else
      PutInt32(Result, 4 + LIndex * 4, LOffset);
    PutName(Result, LOffset, LTexture.Name);
    PutInt32(Result, LOffset + 8, LTexture.Masked);
    PutInt16(Result, LOffset + 12, LTexture.Width);
    PutInt16(Result, LOffset + 14, LTexture.Height);
    if FStrife then
      PutInt16(Result, LOffset + 16, LTexture.PatchCount)
    else
      PutInt16(Result, LOffset + 20, LTexture.PatchCount);
    for LPatchIndex := 0 to High(LTexture.Patches) do
    begin
      LPatchOffset := LOffset + LHeader + LPatchIndex * LPatchSize;
      PutInt16(Result, LPatchOffset, LTexture.Patches[LPatchIndex].OriginX);
      PutInt16(Result, LPatchOffset + 2, LTexture.Patches[LPatchIndex].OriginY);
      PutInt16(Result, LPatchOffset + 4, LTexture.Patches[LPatchIndex].Index);
    end;
    Inc(LOffset, LHeader + Length(LTexture.Patches) * LPatchSize);
  end;
end;

function TTextureDefsCase.BuildTextureLumpNumber(ANumber: Integer): TBytes;
begin
  Result := BuildTextureLump(FTextures[ANumber], FBadOffset[ANumber]);
end;

function TTextureDefsCase.HasPk3: Boolean;
begin
  Result := FPk3.Count > 0;
end;

function TTextureDefsCase.BuildPk3Lump: TBytes;
var
  LHeader: Integer;
  LEntry: Integer;
  LIndex: Integer;
  LOffset: Integer;
  LTexture: TCorpusTexture;
begin
  if FStrife then
  begin
    LHeader := 18;
    LEntry := 24;
  end
  else
  begin
    LHeader := 22;
    LEntry := 32;
  end;
  SetLength(Result, 4 + FPk3.Count * LEntry);
  PutInt32(Result, 0, FPk3.Count);
  for LIndex := 0 to FPk3.Count - 1 do
  begin
    LTexture := FPk3[LIndex];
    LOffset := 4 + LIndex * LEntry;
    PutName(Result, LOffset, LTexture.Name);
    PutInt16(Result, LOffset + 12, LTexture.Width);
    PutInt16(Result, LOffset + 14, LTexture.Height);
    if FStrife then
      PutInt16(Result, LOffset + 16, LTexture.PatchCount)
    else
      PutInt16(Result, LOffset + 20, LTexture.PatchCount);
    PutInt16(Result, LOffset + LHeader, LTexture.Patches[0].OriginX);
    PutInt16(Result, LOffset + LHeader + 2, LTexture.Patches[0].OriginY);
    PutInt16(Result, LOffset + LHeader + 4, 0);
  end;
end;

{ TTextureDefsCorpus }

class function TTextureDefsCorpus.Load(const AFileName: string): TObjectList<TTextureDefsCase>;
var
  LLines: TStringList;
  LIndex: Integer;
  LCurrent: TTextureDefsCase;
begin
  Result := TObjectList<TTextureDefsCase>.Create(True);
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(AFileName);
    LCurrent := nil;
    for LIndex := 0 to LLines.Count - 1 do
    begin
      if Copy(LLines[LIndex], 1, 4) = '=== ' then
      begin
        LCurrent := TTextureDefsCase.Create(Copy(LLines[LIndex], 5, MaxInt));
        Result.Add(LCurrent);
      end
      else if (Copy(LLines[LIndex], 1, 1) <> '#') and Assigned(LCurrent) then
        LCurrent.ParseLine(LLines[LIndex]);
    end;
  finally
    LLines.Free;
  end;
end;

class function TTextureDefsCorpus.FromLines(const ALines: array of string): TTextureDefsCase;
var
  LIndex: Integer;
begin
  Result := TTextureDefsCase.Create('inline');
  for LIndex := Low(ALines) to High(ALines) do
    Result.ParseLine(ALines[LIndex]);
end;

class function TTextureDefsCorpus.Fnv32(const AText: string): Cardinal;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  Result := $811C9DC5;
  LBytes := TEncoding.UTF8.GetBytes(AText);
  for LIndex := 0 to High(LBytes) do
    Result := Cardinal((UInt64(Result xor LBytes[LIndex]) * 16777619) and $FFFFFFFF);
end;

{ TCorpusWad }

constructor TCorpusWad.Create(const AFileName: string);
var
  LStream: TFileStream;
begin
  inherited Create;
  LStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    SetLength(FBytes, LStream.Size);
    if Length(FBytes) > 0 then
      LStream.ReadBuffer(FBytes[0], Length(FBytes));
  finally
    LStream.Free;
  end;
  Move(FBytes[4], FCount, 4);
  Move(FBytes[8], FDirectory, 4);
end;

function TCorpusWad.TryReadLump(const AName: string; out ABytes: TBytes): Boolean;
var
  LIndex: Integer;
  LEntry: Integer;
  LPosition: Integer;
  LSize: Integer;
  LName: string;
  LByte: Integer;
  LCharIndex: Integer;
begin
  Result := False;
  for LIndex := FCount - 1 downto 0 do
  begin
    LEntry := FDirectory + LIndex * 16;
    LName := '';
    for LCharIndex := 0 to 7 do
    begin
      LByte := FBytes[LEntry + 8 + LCharIndex];
      if LByte = 0 then
        Break;
      if (LByte >= Ord('a')) and (LByte <= Ord('z')) then
        Dec(LByte, 32);
      LName := LName + Char(LByte);
    end;
    if LName = AName then
    begin
      Move(FBytes[LEntry], LPosition, 4);
      Move(FBytes[LEntry + 4], LSize, 4);
      SetLength(ABytes, LSize);
      if LSize > 0 then
        Move(FBytes[LPosition], ABytes[0], LSize);
      Exit(True);
    end;
  end;
end;

end.
