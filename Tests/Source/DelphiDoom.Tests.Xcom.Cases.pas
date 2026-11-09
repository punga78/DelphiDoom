{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the pseudo random inputs     }
{                                                                              }
{  The golden file Tests\Data\Xcom\xcom_golden.txt was written by the loaders   }
{  of OpenXcom (compiled with MinGW, harness outside the repository) on files   }
{  that a small generator makes. This unit is the same generator: the same      }
{  numbers in the same order, so the tests give the library the same files      }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.Cases;

interface

uses
  System.SysUtils;

const
  /// <summary>Cases of every format in the golden file</summary>
  XCOM_CASES = 300;

type
  /// <summary>The generator: x = x * 1664525 + 1013904223 on 32 bits, and the 16 high bits are the number</summary>
  TXcomRng = record
  strict private
    FState: Cardinal;
  public
    constructor Create(ASeed: Cardinal);
    function Next: Cardinal;
    function Below(ALimit: Cardinal): Cardinal;
  end;

  /// <summary>FNV-1a 32 bit, little endian for the numbers (as the harness does)</summary>
  TXcomFnv = record
  strict private
    FHash: Cardinal;
  public
    procedure Start;
    procedure AddByte(AValue: Byte);
    procedure AddU32(AValue: Cardinal);
    procedure AddU64(AValue: UInt64);
    function ToHex: string;
    property Hash: Cardinal read FHash;
  end;

  /// <summary>The routes of a block: the .RMP file and where the block is placed</summary>
  TXcomRouteCase = record
    Bytes: TBytes;
    SizeX, SizeY, SizeZ: Integer;
    OffsetX, OffsetY: Integer;
    NodeOffset: Integer;
  end;

  TXcomCases = class
  public
    class function Widths: TArray<Integer>; static;
    class function Heights: TArray<Integer>; static;
    /// <summary>ATab is empty for the cases that have no .TAB</summary>
    class procedure Pck(AIndex: Integer; out AWidth, AHeight: Integer; out APck, ATab: TBytes); static;
    class procedure Dat(AIndex: Integer; out AWidth, AHeight: Integer; out ABytes: TBytes); static;
    class procedure Scr(AIndex: Integer; out AWidth, AHeight: Integer; out ABytes: TBytes); static;
    class procedure Spk(AIndex: Integer; out AWidth, AHeight: Integer; out ABytes: TBytes); static;
    class procedure Bdy(AIndex: Integer; out AWidth, AHeight: Integer; out ABytes: TBytes); static;
    class procedure Pal(AIndex: Integer; out ABytes: TBytes; out ACount, AOffset: Integer); static;
    class function Cat(AIndex: Integer): TBytes; static;
    class function MapFile(AIndex: Integer): TBytes; static;
    class function Route(AIndex: Integer): TXcomRouteCase; static;
    class function Mcd(AIndex: Integer): TBytes; static;
    class function World(AIndex: Integer): TBytes; static;
    class function WordTable(AIndex: Integer): TBytes; static;
  end;

implementation

const
  WIDTH_VALUES: array[0..5] of Integer = (1, 2, 3, 5, 8, 32);
  HEIGHT_VALUES: array[0..5] of Integer = (1, 2, 3, 5, 8, 40);
  PALETTE_COUNTS: array[0..3] of Integer = (256, 128, 16, 1);

{$R-}
{$Q-}

{ TXcomRng }

constructor TXcomRng.Create(ASeed: Cardinal);
begin
  FState := ASeed;
end;

function TXcomRng.Next: Cardinal;
begin
  FState := FState * 1664525 + 1013904223;
  Result := FState shr 16;
end;

function TXcomRng.Below(ALimit: Cardinal): Cardinal;
begin
  Result := Next mod ALimit;
end;

{ TXcomFnv }

procedure TXcomFnv.Start;
begin
  FHash := 2166136261;
end;

procedure TXcomFnv.AddByte(AValue: Byte);
begin
  FHash := (FHash xor AValue) * 16777619;
end;

procedure TXcomFnv.AddU32(AValue: Cardinal);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    AddByte(Byte(AValue shr (8 * LIndex)));
end;

procedure TXcomFnv.AddU64(AValue: UInt64);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    AddByte(Byte(AValue shr (8 * LIndex)));
end;

function TXcomFnv.ToHex: string;
begin
  Result := LowerCase(IntToHex(FHash, 8));
end;

{ TXcomCases }

class function TXcomCases.Widths: TArray<Integer>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(WIDTH_VALUES));
  for LIndex := 0 to High(WIDTH_VALUES) do
    Result[LIndex] := WIDTH_VALUES[LIndex];
end;

class function TXcomCases.Heights: TArray<Integer>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(HEIGHT_VALUES));
  for LIndex := 0 to High(HEIGHT_VALUES) do
    Result[LIndex] := HEIGHT_VALUES[LIndex];
end;

class procedure TXcomCases.Pck(AIndex: Integer; out AWidth, AHeight: Integer; out APck, ATab: TBytes);
var
  LRng: TXcomRng;
  LTabKind: Integer;
  LTabLength: Integer;
  LPckLength: Integer;
  LIndex: Integer;
  LKind: Cardinal;
begin
  LRng := TXcomRng.Create(1000 + AIndex * 17);
  AWidth := WIDTH_VALUES[LRng.Below(6)];
  AHeight := HEIGHT_VALUES[LRng.Below(6)];
  LTabKind := LRng.Below(3);
  LTabLength := 4 + LRng.Below(37);
  LPckLength := LRng.Below(301);
  SetLength(ATab, LTabLength);
  for LIndex := 0 to LTabLength - 1 do
    ATab[LIndex] := Byte(LRng.Below(256));
  if LTabKind = 1 then
  begin
    ATab[0] := 0;
    ATab[1] := 0;
    ATab[2] := 0;
    ATab[3] := 0;
  end
  else if LTabKind = 2 then
  begin
    ATab[0] := 0;
    ATab[1] := 0;
    ATab[2] := Byte(1 + LRng.Below(255));
    ATab[3] := 0;
  end;
  SetLength(APck, LPckLength);
  for LIndex := 0 to LPckLength - 1 do
  begin
    LKind := LRng.Below(100);
    if LKind < 12 then
      APck[LIndex] := 254
    else if LKind < 26 then
      APck[LIndex] := 255
    else if LKind < 40 then
      APck[LIndex] := Byte(LRng.Below(4))
    else
      APck[LIndex] := Byte(LRng.Below(256));
  end;
  if LTabKind = 0 then
    ATab := nil;
end;

class procedure TXcomCases.Dat(AIndex: Integer; out AWidth, AHeight: Integer; out ABytes: TBytes);
var
  LRng: TXcomRng;
  LLength: Integer;
  LIndex: Integer;
begin
  LRng := TXcomRng.Create(2000 + AIndex * 17);
  AWidth := WIDTH_VALUES[LRng.Below(6)];
  AHeight := HEIGHT_VALUES[LRng.Below(6)];
  LLength := AWidth * AHeight + Integer(LRng.Below(Cardinal(AWidth * AHeight * 3)));
  SetLength(ABytes, LLength);
  for LIndex := 0 to LLength - 1 do
    ABytes[LIndex] := Byte(LRng.Below(256));
end;

class procedure TXcomCases.Scr(AIndex: Integer; out AWidth, AHeight: Integer; out ABytes: TBytes);
var
  LRng: TXcomRng;
  LLength: Integer;
  LIndex: Integer;
begin
  LRng := TXcomRng.Create(3000 + AIndex * 17);
  AWidth := WIDTH_VALUES[LRng.Below(6)];
  AHeight := HEIGHT_VALUES[LRng.Below(6)];
  LLength := Integer(LRng.Below(Cardinal(2 * AWidth * AHeight + 1)));
  SetLength(ABytes, LLength);
  for LIndex := 0 to LLength - 1 do
    ABytes[LIndex] := Byte(LRng.Below(256));
end;

class procedure TXcomCases.Spk(AIndex: Integer; out AWidth, AHeight: Integer; out ABytes: TBytes);
var
  LRng: TXcomRng;
  LLength: Integer;
  LCount: Integer;
  LKind: Cardinal;
begin
  LRng := TXcomRng.Create(4000 + AIndex * 17);
  AWidth := WIDTH_VALUES[LRng.Below(6)];
  AHeight := HEIGHT_VALUES[LRng.Below(6)];
  LLength := Integer(LRng.Below(120));
  SetLength(ABytes, LLength + 2);
  LCount := 0;
  while LCount < LLength do
  begin
    LKind := LRng.Below(100);
    if LKind < 25 then
    begin
      ABytes[LCount] := $FF;
      ABytes[LCount + 1] := $FF;
      Inc(LCount, 2);
    end
    else if LKind < 50 then
    begin
      ABytes[LCount] := $FE;
      ABytes[LCount + 1] := $FF;
      Inc(LCount, 2);
    end
    else
    begin
      ABytes[LCount] := Byte(LRng.Below(256));
      Inc(LCount);
    end;
  end;
  SetLength(ABytes, LLength);
end;

class procedure TXcomCases.Bdy(AIndex: Integer; out AWidth, AHeight: Integer; out ABytes: TBytes);
var
  LRng: TXcomRng;
  LLength: Integer;
  LIndex: Integer;
  LKind: Cardinal;
begin
  LRng := TXcomRng.Create(5000 + AIndex * 17);
  AWidth := WIDTH_VALUES[LRng.Below(6)];
  AHeight := HEIGHT_VALUES[LRng.Below(6)];
  LLength := Integer(LRng.Below(120));
  SetLength(ABytes, LLength);
  for LIndex := 0 to LLength - 1 do
  begin
    LKind := LRng.Below(100);
    if LKind < 20 then
      ABytes[LIndex] := Byte(129 + LRng.Below(127))
    else
      ABytes[LIndex] := Byte(LRng.Below(129));
  end;
end;

class procedure TXcomCases.Pal(AIndex: Integer; out ABytes: TBytes; out ACount, AOffset: Integer);
var
  LRng: TXcomRng;
  LLength: Integer;
  LIndex: Integer;
begin
  LRng := TXcomRng.Create(6000 + AIndex * 17);
  LLength := Integer(LRng.Below(800));
  ACount := PALETTE_COUNTS[LRng.Below(4)];
  AOffset := Integer(LRng.Below(Cardinal(LLength + 12)));
  SetLength(ABytes, LLength);
  for LIndex := 0 to LLength - 1 do
    ABytes[LIndex] := Byte(LRng.Below(256));
end;

class function TXcomCases.Cat(AIndex: Integer): TBytes;
var
  LRng: TXcomRng;
  LCount: Integer;
  LEntry: Integer;
  LIndex: Integer;
  LDataLength: Integer;
  LName: Integer;
  LOffsets: TArray<Integer>;
  LNames: TArray<Integer>;
  LSkip: Integer;
  LAvailable: Integer;
  LSize: Cardinal;
  LOffset: Cardinal;
begin
  LRng := TXcomRng.Create(7000 + AIndex * 17);
  LCount := 1 + Integer(LRng.Below(5));
  SetLength(Result, LCount * 8);
  SetLength(LOffsets, LCount);
  SetLength(LNames, LCount);
  for LEntry := 0 to LCount - 1 do
  begin
    LOffsets[LEntry] := Length(Result);
    LDataLength := Integer(LRng.Below(30));
    if LRng.Below(2) = 0 then
      LName := Integer(LRng.Below(57))
    else
      LName := Integer(57 + LRng.Below(199));
    LNames[LEntry] := LName;
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Byte(LName);
    for LIndex := 0 to LDataLength - 1 do
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Byte(LRng.Below(256));
    end;
  end;
  // 60 bytes of zeros at the end: an entry that keeps its name (up to 56 bytes) never reads past the end of the file,
  // where the C++ gives bytes that nobody wrote
  SetLength(Result, Length(Result) + 60);
  FillChar(Result[Length(Result) - 60], 60, 0);
  for LEntry := 0 to LCount - 1 do
  begin
    if LNames[LEntry] <= 56 then
      LSkip := LNames[LEntry] + 1
    else
      LSkip := 0;
    LAvailable := Length(Result) - LOffsets[LEntry] - LSkip;
    if LAvailable < 0 then
      LAvailable := 0;
    LSize := LRng.Below(Cardinal(LAvailable + 1));
    LOffset := Cardinal(LOffsets[LEntry]);
    for LIndex := 0 to 3 do
    begin
      Result[LEntry * 8 + LIndex] := Byte(LOffset shr (8 * LIndex));
      Result[LEntry * 8 + 4 + LIndex] := Byte(LSize shr (8 * LIndex));
    end;
  end;
end;

class function TXcomCases.MapFile(AIndex: Integer): TBytes;
var
  LRng: TXcomRng;
  LIndex: Integer;
  LCells: Integer;
  LExtra: Integer;
begin
  LRng := TXcomRng.Create(8000 + AIndex * 17);
  SetLength(Result, 3);
  for LIndex := 0 to 2 do
    if LRng.Below(4) = 0 then
      Result[LIndex] := Byte(LRng.Below(256))
    else
      Result[LIndex] := Byte(1 + LRng.Below(8));
  LCells := Integer(LRng.Below(40));
  LExtra := Integer(LRng.Below(4));
  SetLength(Result, 3 + LCells * 4 + LExtra);
  for LIndex := 3 to High(Result) do
    Result[LIndex] := Byte(LRng.Below(256));
end;

class function TXcomCases.Route(AIndex: Integer): TXcomRouteCase;
var
  LRng: TXcomRng;
  LRecords: Integer;
  LExtra: Integer;
  LRecord: Integer;
  LLink: Integer;
  LIndex: Integer;
  LBase: Integer;
begin
  LRng := TXcomRng.Create(9000 + AIndex * 17);
  LRecords := Integer(LRng.Below(9));
  LExtra := Integer(LRng.Below(24));
  SetLength(Result.Bytes, LRecords * 24);
  for LRecord := 0 to LRecords - 1 do
  begin
    LBase := LRecord * 24;
    Result.Bytes[LBase] := Byte(LRng.Below(7));
    Result.Bytes[LBase + 1] := Byte(LRng.Below(7));
    Result.Bytes[LBase + 2] := Byte(LRng.Below(4));
    Result.Bytes[LBase + 3] := Byte(LRng.Below(256));
    for LLink := 0 to 4 do
    begin
      if LRng.Below(3) = 0 then
        Result.Bytes[LBase + 4 + LLink * 3] := Byte(245 + LRng.Below(11))
      else
        Result.Bytes[LBase + 4 + LLink * 3] := Byte(LRng.Below(Cardinal(LRecords + 2)));
      Result.Bytes[LBase + 5 + LLink * 3] := Byte(LRng.Below(256));
      Result.Bytes[LBase + 6 + LLink * 3] := Byte(LRng.Below(256));
    end;
    for LIndex := 19 to 23 do
      Result.Bytes[LBase + LIndex] := Byte(LRng.Below(256));
  end;
  SetLength(Result.Bytes, LRecords * 24 + LExtra);
  for LIndex := LRecords * 24 to High(Result.Bytes) do
    Result.Bytes[LIndex] := Byte(LRng.Below(256));
  Result.SizeX := 1 + Integer(LRng.Below(6));
  Result.SizeY := 1 + Integer(LRng.Below(6));
  Result.SizeZ := 1 + Integer(LRng.Below(3));
  Result.OffsetX := Integer(LRng.Below(30));
  Result.OffsetY := Integer(LRng.Below(30));
  Result.NodeOffset := Integer(LRng.Below(20));
end;

class function TXcomCases.Mcd(AIndex: Integer): TBytes;
var
  LRng: TXcomRng;
  LCount: Integer;
  LExtra: Integer;
  LFix: Integer;
  LRecord: Integer;
  LIndex: Integer;
  LBase: Integer;
begin
  LRng := TXcomRng.Create(10000 + AIndex * 17);
  LCount := Integer(LRng.Below(6));
  LExtra := Integer(LRng.Below(62));
  LFix := Integer(LRng.Below(2));
  SetLength(Result, LCount * 62 + LExtra);
  for LRecord := 0 to LCount - 1 do
  begin
    LBase := LRecord * 62;
    for LIndex := 0 to 61 do
      Result[LBase + LIndex] := Byte(LRng.Below(256));
    if LFix <> 0 then
    begin
      Result[LBase + 44] := Byte(LRng.Below(Cardinal(LCount)));
      Result[LBase + 46] := Byte(LRng.Below(Cardinal(LCount)));
      Result[LBase + 42] := Byte(1 + LRng.Below(255));
    end;
  end;
  for LIndex := LCount * 62 to High(Result) do
    Result[LIndex] := Byte(LRng.Below(256));
end;

class function TXcomCases.World(AIndex: Integer): TBytes;
var
  LRng: TXcomRng;
  LCount: Integer;
  LExtra: Integer;
  LRecord: Integer;
  LIndex: Integer;
  LValues: array[0..9] of SmallInt;
  LSpecial: Cardinal;
begin
  LRng := TXcomRng.Create(11000 + AIndex * 17);
  LCount := Integer(LRng.Below(8));
  LExtra := Integer(LRng.Below(20));
  SetLength(Result, LCount * 20 + LExtra);
  for LRecord := 0 to LCount - 1 do
  begin
    for LIndex := 0 to 9 do
      LValues[LIndex] := SmallInt(Integer(LRng.Below(5760)) - 2880);
    if LRng.Below(5) < 2 then
      LValues[6] := -1;
    LSpecial := LRng.Below(20);
    if LSpecial = 0 then
      LValues[0] := 32767
    else if LSpecial = 1 then
      LValues[0] := -32768;
    for LIndex := 0 to 9 do
    begin
      Result[LRecord * 20 + LIndex * 2] := Byte(LValues[LIndex] and $FF);
      Result[LRecord * 20 + LIndex * 2 + 1] := Byte((LValues[LIndex] shr 8) and $FF);
    end;
  end;
  for LIndex := LCount * 20 to High(Result) do
    Result[LIndex] := Byte(LRng.Below(256));
end;

class function TXcomCases.WordTable(AIndex: Integer): TBytes;
var
  LRng: TXcomRng;
  LIndex: Integer;
begin
  LRng := TXcomRng.Create(12000 + AIndex * 17);
  SetLength(Result, Integer(LRng.Below(100)));
  for LIndex := 0 to High(Result) do
    Result[LIndex] := Byte(LRng.Below(256));
end;

end.
