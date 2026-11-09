{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the radix library - a RADIX.DAT made in memory         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.DatBuilder;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  DelphiDoom.GameData.Types, DelphiDoom.GameData.Intf, DelphiDoom.GameData.Factory,
  DelphiDoom.Radix.Types, DelphiDoom.Radix.Context;

type
  /// <summary>
  ///   Writes a container of Radix: the header (25 bytes), the data of the lumps one after the
  ///   other and the directory at the end. Add returns the position of the data, so that a table
  ///   written later can point at what was added before
  /// </summary>
  TRadixDatBuilder = class
  strict private
    FData: TBytesStream;
    FNames: TList<string>;
    FPositions: TList<Integer>;
    FLengths: TList<Integer>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Adds a lump; returns the absolute position of its data</summary>
    function Add(const AName: string; const ABytes: TBytes): Integer;
    /// <summary>The position that the next lump will have</summary>
    function NextPosition: Integer;
    function ToBytes: TBytes;
    /// <summary>The lump "WallBitmaps" for bitmaps of the given sizes, filled with a pattern</summary>
    procedure AddWallBitmaps(const ASizes: array of Integer);
    class function Words(AValue: Integer): TBytes; static;
    class function Pattern(ACount, ASeed: Integer): TBytes; static;
  end;

  /// <summary>Runs one step of the translation on a container made in memory</summary>
  TRadixPartRunner = class
  public
    /// <param name="APalette">The base palette (768 bytes, 0..255) the step finds; empty for none</param>
    /// <param name="AAliases">The lines that the step wrote for the PK3 entry</param>
    class function Run(const APart: IRadixPart; const ADat: TBytes; const APalette: TBytes;
      out AAliases: TArray<string>): IGameWadComposer; static;
  end;

implementation

uses
  DelphiDoom.Radix.Factory;

const
  HeaderSize = 25;

{ TRadixPartRunner }

class function TRadixPartRunner.Run(const APart: IRadixPart; const ADat: TBytes;
  const APalette: TBytes; out AAliases: TArray<string>): IGameWadComposer;
var
  LContext: TRadixTranslationContext;
begin
  Result := TGameDataFactory.CreateWadComposer;
  LContext := TRadixTranslationContext.Create(TRadixFactory.OpenContainerBytes(ADat), Result,
    TGameDataFactory.CreatePatchBuilder(TGamePatchOptions.Radix));
  try
    if Length(APalette) = 768 then
      LContext.SetPalette(APalette);
    APart.Build(LContext);
    AAliases := LContext.Aliases.ToArray;
  finally
    LContext.Free;
  end;
end;

{ TRadixDatBuilder }

constructor TRadixDatBuilder.Create;
begin
  inherited Create;
  FData := TBytesStream.Create;
  FNames := TList<string>.Create;
  FPositions := TList<Integer>.Create;
  FLengths := TList<Integer>.Create;
end;

destructor TRadixDatBuilder.Destroy;
begin
  FLengths.Free;
  FPositions.Free;
  FNames.Free;
  FData.Free;
  inherited Destroy;
end;

function TRadixDatBuilder.NextPosition: Integer;
begin
  Result := HeaderSize + Integer(FData.Size);
end;

function TRadixDatBuilder.Add(const AName: string; const ABytes: TBytes): Integer;
begin
  Result := NextPosition;
  FNames.Add(AName);
  FPositions.Add(Result);
  FLengths.Add(Length(ABytes));
  if Length(ABytes) > 0 then
    FData.WriteBuffer(ABytes[0], Length(ABytes));
end;

function TRadixDatBuilder.ToBytes: TBytes;
var
  LHeader: TRadixHeaderRecord;
  LRecord: TRadixLumpRecord;
  LIndex: Integer;
  LCharacter: Integer;
  LOutput: TBytesStream;
begin
  FillChar(LHeader, SizeOf(LHeader), 0);
  for LCharacter := 1 to Length(RADIX_SIGNATURE) do
    LHeader.Id[LCharacter - 1] := AnsiChar(RADIX_SIGNATURE[LCharacter]);
  LHeader.NumLumps := FNames.Count;
  LHeader.Start := NextPosition;
  LOutput := TBytesStream.Create;
  try
    LOutput.WriteBuffer(LHeader, SizeOf(LHeader));
    if FData.Size > 0 then
      LOutput.WriteBuffer(FData.Bytes[0], FData.Size);
    for LIndex := 0 to FNames.Count - 1 do
    begin
      FillChar(LRecord, SizeOf(LRecord), 0);
      for LCharacter := 1 to Length(FNames[LIndex]) do
        LRecord.Name[LCharacter - 1] := AnsiChar(FNames[LIndex][LCharacter]);
      LRecord.Position := FPositions[LIndex];
      LRecord.Length := FLengths[LIndex];
      LOutput.WriteBuffer(LRecord, SizeOf(LRecord));
    end;
    Result := Copy(LOutput.Bytes, 0, LOutput.Size);
  finally
    LOutput.Free;
  end;
end;

class function TRadixDatBuilder.Words(AValue: Integer): TBytes;
begin
  Result := [Byte(AValue and $FF), Byte((AValue shr 8) and $FF)];
end;

class function TRadixDatBuilder.Pattern(ACount, ASeed: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
    Result[LIndex] := Byte((LIndex * 7 + ASeed * 13 + LIndex div 5) mod 251);
end;

procedure TRadixDatBuilder.AddWallBitmaps(const ASizes: array of Integer);
var
  LPixels: TList<Integer>;
  LIndex: Integer;
  LTable: TBytesStream;
  LRecord: TRadixBitmapRecord;
  LTablePosition: Integer;
  LHead: TBytes;
  LCharacter: Integer;
  LName: string;
begin
  // ASizes: width, height, width, height ...
  LPixels := TList<Integer>.Create;
  LTable := TBytesStream.Create;
  try
    for LIndex := 0 to Length(ASizes) div 2 - 1 do
      LPixels.Add(Add('Pixels' + IntToStr(LIndex), Pattern(ASizes[LIndex * 2] * ASizes[LIndex * 2 + 1], LIndex + 1)));
    for LIndex := 0 to Length(ASizes) div 2 - 1 do
    begin
      FillChar(LRecord, SizeOf(LRecord), 0);
      LName := 'Wall' + IntToStr(LIndex);
      for LCharacter := 1 to Length(LName) do
        LRecord.Name[LCharacter - 1] := AnsiChar(LName[LCharacter]);
      LRecord.Position := LPixels[LIndex];
      LRecord.Width := ASizes[LIndex * 2];
      LRecord.Height := ASizes[LIndex * 2 + 1];
      LTable.WriteBuffer(LRecord, SizeOf(LRecord));
    end;
    LTablePosition := Add('BitmapTable', Copy(LTable.Bytes, 0, LTable.Size));
    SetLength(LHead, 6);
    LHead[0] := Byte(Length(ASizes) div 2);
    LHead[1] := 0;
    Move(LTablePosition, LHead[2], 4);
    Add('WallBitmaps', LHead);
  finally
    LTable.Free;
    LPixels.Free;
  end;
end;

end.
