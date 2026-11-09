{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom surface library - the script of the parity     }
{  scenarios                                                                    }
{                                                                              }
{  A script (Tests\Data\XcomSurface\surface.script.txt) is a list of operations }
{  on up to six surfaces and on sprite fonts; the file surface.golden.txt has    }
{  what the real OpenXcom Surface and Font, linked with the real SDL 1.2, gave  }
{  for it (harness outside the repository, compiled with MinGW g++).             }
{  Random fills use the Mersenne Twister of the C++ standard library            }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSurface.Script;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Xcom.Types,
  DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Shade,
  DelphiDoom.XcomSurface.Font;

type
  /// <summary>std::mt19937</summary>
  TMersenneTwister = class
  strict private
    FState: array[0..623] of Cardinal;
    FIndex: Integer;
  public
    constructor Create(ASeed: Cardinal);
    function Next: Cardinal;
  end;

  /// <summary>Runs a script and gives the lines that the C++ harness printed for it</summary>
  TXcomSurfaceScript = class
  strict private
    FSurfaces: array[0..7] of TXcomSurface;
    FOutput: TStringList;
    procedure Report(AId: Integer);
    procedure MakeSurface(AId, AWidth, AHeight, AX, AY: Integer; ASeed: Cardinal; AZeroPercent: Integer);
    procedure MakePalette(AId: Integer; ASeed: Cardinal; ALevels: Integer);
    procedure RunFont(const AParts: TArray<string>);
    function Hash(ASurface: TXcomSurface): UInt64;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Runs every line; the result is the lines of the golden file</summary>
    function Run(const AScript: TStrings): TStringList;
  end;

implementation

{ TMersenneTwister }

constructor TMersenneTwister.Create(ASeed: Cardinal);
var
  LIndex: Integer;
begin
  inherited Create;
  FState[0] := ASeed;
  for LIndex := 1 to 623 do
    FState[LIndex] := Cardinal(UInt64(1812433253) * UInt64(FState[LIndex - 1] xor (FState[LIndex - 1] shr 30)) + UInt64(LIndex));
  FIndex := 624;
end;

function TMersenneTwister.Next: Cardinal;
var
  LIndex: Integer;
  LValue: Cardinal;
begin
  if FIndex >= 624 then
  begin
    for LIndex := 0 to 623 do
    begin
      LValue := (FState[LIndex] and $80000000) or (FState[(LIndex + 1) mod 624] and $7FFFFFFF);
      FState[LIndex] := FState[(LIndex + 397) mod 624] xor (LValue shr 1);
      if (LValue and 1) <> 0 then
        FState[LIndex] := FState[LIndex] xor $9908B0DF;
    end;
    FIndex := 0;
  end;
  Result := FState[FIndex];
  Inc(FIndex);
  Result := Result xor (Result shr 11);
  Result := Result xor ((Result shl 7) and $9D2C5680);
  Result := Result xor ((Result shl 15) and $EFC60000);
  Result := Result xor (Result shr 18);
end;

{ TXcomSurfaceScript }

constructor TXcomSurfaceScript.Create;
begin
  inherited Create;
  FOutput := TStringList.Create;
end;

destructor TXcomSurfaceScript.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FSurfaces) do
    FSurfaces[LIndex].Free;
  FOutput.Free;
  inherited Destroy;
end;

function TXcomSurfaceScript.Hash(ASurface: TXcomSurface): UInt64;
var
  LX, LY: Integer;
begin
  Result := 1469598103934665603;
  for LY := 0 to ASurface.Height - 1 do
    for LX := 0 to ASurface.Width - 1 do
    begin
      Result := Result xor UInt64(ASurface.GetPixel(LX, LY));
      Result := Result * UInt64(1099511628211);
    end;
end;

procedure TXcomSurfaceScript.Report(AId: Integer);
var
  LSurface: TXcomSurface;
begin
  LSurface := FSurfaces[AId];
  FOutput.Add(Format('%d %d %d %d %d %s', [AId, LSurface.Width, LSurface.Height, LSurface.X, LSurface.Y,
    UIntToStr(Hash(LSurface))]));
end;

procedure TXcomSurfaceScript.MakeSurface(AId, AWidth, AHeight, AX, AY: Integer; ASeed: Cardinal;
  AZeroPercent: Integer);
var
  LRandom: TMersenneTwister;
  LX, LY: Integer;
  LValue: Cardinal;
begin
  FreeAndNil(FSurfaces[AId]);
  FSurfaces[AId] := TXcomSurface.Create(AWidth, AHeight, AX, AY);
  LRandom := TMersenneTwister.Create(ASeed);
  try
    for LY := 0 to AHeight - 1 do
      for LX := 0 to AWidth - 1 do
      begin
        LValue := LRandom.Next;
        if (LValue mod 100) < Cardinal(AZeroPercent) then
          FSurfaces[AId].SetPixel(LX, LY, 0)
        else
          FSurfaces[AId].SetPixel(LX, LY, Byte((LValue shr 8) mod 256));
      end;
  finally
    LRandom.Free;
  end;
end;

procedure TXcomSurfaceScript.MakePalette(AId: Integer; ASeed: Cardinal; ALevels: Integer);
var
  LRandom: TMersenneTwister;
  LColors: array[0..255] of TXcomColor;
  LIndex, LStep: Integer;
begin
  LStep := 255 div (ALevels - 1);
  LRandom := TMersenneTwister.Create(ASeed);
  try
    for LIndex := 0 to 255 do
    begin
      LColors[LIndex].Red := Byte((LRandom.Next mod Cardinal(ALevels)) * Cardinal(LStep));
      LColors[LIndex].Green := Byte((LRandom.Next mod Cardinal(ALevels)) * Cardinal(LStep));
      LColors[LIndex].Blue := Byte((LRandom.Next mod Cardinal(ALevels)) * Cardinal(LStep));
      LColors[LIndex].Alpha := 0;
    end;
  finally
    LRandom.Free;
  end;
  FSurfaces[AId].SetColors(LColors);
end;

procedure TXcomSurfaceScript.RunFont(const AParts: TArray<string>);
const
  PROBES: array[0..12] of Integer = (0, 1, 2, 9, 10, 32, 33, 63, 65, 90, 160, 161, 200);
var
  LMono, LCellWidth, LCellHeight, LColumns, LRows, LSpacing, LZeroPercent, LCount: Integer;
  LSeed: Cardinal;
  LCodes: TArray<Cardinal>;
  LAll: TArray<Cardinal>;
  LFont: TXcomFont;
  LSurface: TXcomSurface;
  LRandom: TMersenneTwister;
  LIndex, LX, LY: Integer;
  LValue: Cardinal;
  LSize: TXcomRect;
  LChar: TXcomFontChar;
  LHas: Boolean;
begin
  LMono := StrToInt(AParts[1]);
  LCellWidth := StrToInt(AParts[2]);
  LCellHeight := StrToInt(AParts[3]);
  LColumns := StrToInt(AParts[4]);
  LRows := StrToInt(AParts[5]);
  LSpacing := StrToInt(AParts[6]);
  LSeed := Cardinal(StrToUInt64(AParts[7]));
  LZeroPercent := StrToInt(AParts[8]);
  LCount := StrToInt(AParts[9]);
  SetLength(LCodes, LCount);
  for LIndex := 0 to LCount - 1 do
    LCodes[LIndex] := Cardinal(StrToInt(AParts[10 + LIndex]));
  LFont := TXcomFont.Create;
  try
    LFont.Monospace := LMono <> 0;
    LSurface := TXcomSurface.Create(LCellWidth * LColumns, LCellHeight * LRows);
    LFont.AddImage(LCellWidth, LCellHeight, LSpacing, LSurface);
    LRandom := TMersenneTwister.Create(LSeed);
    try
      for LY := 0 to LCellHeight * LRows - 1 do
        for LX := 0 to LCellWidth * LColumns - 1 do
        begin
          LValue := LRandom.Next;
          if (LValue mod 100) < Cardinal(LZeroPercent) then
            LSurface.SetPixel(LX, LY, 0)
          else
            LSurface.SetPixel(LX, LY, Byte(1 + (LValue shr 8) mod 255));
        end;
    finally
      LRandom.Free;
    end;
    LFont.Init(0, LCodes);
    LAll := Copy(LCodes);
    for LIndex := 0 to High(PROBES) do
    begin
      SetLength(LAll, Length(LAll) + 1);
      LAll[High(LAll)] := Cardinal(PROBES[LIndex]);
    end;
    for LIndex := 0 to High(LAll) do
    begin
      LSize := LFont.GetCharSize(LAll[LIndex]);
      LHas := LFont.TryGetChar(LAll[LIndex], LChar);
      if not LHas then
        LChar.Rect := TXcomRect.Make(0, 0, 0, 0);
      FOutput.Add(Format('f %d %d %d %d %d %d %d %d %d %d', [LAll[LIndex], Ord(LHas), LChar.Rect.X, LChar.Rect.Y,
        LChar.Rect.W, LChar.Rect.H, LSize.W, LSize.H, LSize.X, LSize.Y]));
    end;
    FOutput.Add(Format('fw %d %d %d', [LFont.Width, LFont.Height, LFont.Spacing]));
  finally
    LFont.Free;
  end;
end;

function TXcomSurfaceScript.Run(const AScript: TStrings): TStringList;
var
  LLine: string;
  LParts: TArray<string>;
  LOp: Char;
  A, B: Integer;
  LSurface: TXcomSurface;
  LCopy: TXcomSurface;
  function P(AIndex: Integer): Integer;
  begin
    Result := StrToInt(LParts[AIndex]);
  end;
begin
  for LLine in AScript do
  begin
    if LLine = '' then
      Continue;
    LParts := LLine.Split([' ']);
    LOp := LParts[0][1];
    if LOp = 'F' then
    begin
      RunFont(LParts);
      Continue;
    end;
    A := P(1);
    case LOp of
      'S':
        begin
          MakeSurface(A, P(2), P(3), P(4), P(5), Cardinal(StrToUInt64(LParts[6])), P(7));
          Report(A);
        end;
      'P':
        begin
          MakePalette(A, Cardinal(StrToUInt64(LParts[2])), P(3));
          Report(A);
        end;
      'R':
        begin
          FSurfaces[A].DrawRect(P(2), P(3), P(4), P(5), Byte(P(6) and $FF));
          Report(A);
        end;
      'C':
        begin
          FSurfaces[A].Clear(Cardinal(P(2)));
          Report(A);
        end;
      'O':
        begin
          FSurfaces[A].Offset(P(2), P(3), P(4), P(5));
          Report(A);
        end;
      'B':
        begin
          FSurfaces[A].OffsetBlock(P(2), P(3), P(4));
          Report(A);
        end;
      'V':
        begin
          FSurfaces[A].Invert(Byte(P(2)));
          Report(A);
        end;
      'Y':
        begin
          B := P(2);
          FSurfaces[A].Copy(FSurfaces[B]);
          Report(A);
          if B <> A then
            Report(B);
        end;
      'K':
        begin
          FSurfaces[A].Crop := TXcomRect.Make(P(2), P(3), P(4), P(5));
          Report(A);
        end;
      'T':
        begin
          FSurfaces[A].X := P(2);
          FSurfaces[A].Y := P(3);
          Report(A);
        end;
      'H':
        begin
          FSurfaces[A].Hidden := P(2) <> 0;
          Report(A);
        end;
      'L':
        begin
          B := P(2);
          FSurfaces[A].Blit(FSurfaces[B]);
          Report(A);
          if B <> A then
            Report(B);
        end;
      'N':
        begin
          B := P(2);
          TXcomSurfaceShader.Blit(FSurfaces[A], FSurfaces[B], P(3), P(4), P(5), P(6) <> 0, P(7));
          Report(A);
          if B <> A then
            Report(B);
        end;
      'G':
        begin
          B := P(2);
          TXcomSurfaceShader.Blit(FSurfaces[A], FSurfaces[B], P(3), P(4), P(5),
            TXcomGraphSubset.Make(P(6), P(7), P(8), P(9)));
          Report(A);
          if B <> A then
            Report(B);
        end;
      'Z':
        begin
          FSurfaces[A].SetWidth(P(2));
          FSurfaces[A].SetHeight(P(3));
          Report(A);
        end;
      'D':
        begin
          // D <new id> <source id>
          B := P(2);
          if A <> B then
          begin
            LCopy := FSurfaces[B].Clone;
            FSurfaces[A].Free;
            FSurfaces[A] := LCopy;
          end;
          Report(A);
        end;
      'W':
        begin
          FSurfaces[A].Draw;
          Report(A);
        end;
    else
      raise Exception.CreateFmt('Unknown operation %s', [LLine]);
    end;
  end;
  Result := FOutput;
  LSurface := nil;
  if Assigned(LSurface) then;
end;

end.
