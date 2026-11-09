{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - the .CAT containers                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.CatArchive;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Intf;

type
  /// <summary>
  ///   CatFile: the file starts with an index of (offset, size) pairs of 32 bit, and the first offset is where the index
  ///   ends, so it tells how many entries there are (offset / 8). An entry starts with a name: a length byte (at most
  ///   56) and the name, and the data follow; the size of the index is the size of the data
  /// </summary>
  TXcomCatArchive = class(TInterfacedObject, IXcomCatArchive)
  strict private
    FBytes: TBytes;
    FEntries: TArray<TXcomCatEntry>;
    function GetCount: Integer;
    function GetEntry(AIndex: Integer): TXcomCatEntry;
    function ReadCardinal(APosition: Integer): Cardinal;
  public
    /// <param name="ABytes">The whole file</param>
    constructor Create(const ABytes: TBytes);
    function Load(AIndex: Integer; AKeepName: Boolean = False): TBytes;
  end;

implementation

const
  /// <summary>No entry of a real CAT is this big: a size above it is a damaged index, not a sound</summary>
  MAX_ENTRY_BYTES = 256 * 1024 * 1024;

{ TXcomCatArchive }

constructor TXcomCatArchive.Create(const ABytes: TBytes);
var
  LAmount: Cardinal;
  LIndex: Integer;
begin
  inherited Create;
  FBytes := ABytes;
  if Length(FBytes) < 4 then
    raise EXcomDataException.CreateFmt(SXcomHeaderTooShort, ['the CAT file', 4, Length(FBytes)]);
  LAmount := ReadCardinal(0) div 8;
  if Int64(LAmount) * 8 > Length(FBytes) then
    raise EXcomDataException.CreateFmt(SXcomCatBadIndex, [LAmount, Length(FBytes)]);
  SetLength(FEntries, LAmount);
  for LIndex := 0 to Integer(LAmount) - 1 do
  begin
    FEntries[LIndex].Offset := ReadCardinal(LIndex * 8);
    FEntries[LIndex].Size := ReadCardinal(LIndex * 8 + 4);
  end;
end;

function TXcomCatArchive.ReadCardinal(APosition: Integer): Cardinal;
begin
  Result := Cardinal(FBytes[APosition]) or (Cardinal(FBytes[APosition + 1]) shl 8) or
    (Cardinal(FBytes[APosition + 2]) shl 16) or (Cardinal(FBytes[APosition + 3]) shl 24);
end;

function TXcomCatArchive.GetCount: Integer;
begin
  Result := Length(FEntries);
end;

function TXcomCatArchive.GetEntry(AIndex: Integer): TXcomCatEntry;
begin
  if (AIndex < 0) or (AIndex >= Length(FEntries)) then
    raise EXcomException.CreateFmt(SXcomCatIndexInvalid, [Length(FEntries), AIndex]);
  Result := FEntries[AIndex];
end;

function TXcomCatArchive.Load(AIndex: Integer; AKeepName: Boolean): TBytes;
var
  LEntry: TXcomCatEntry;
  LStart: Int64;
  LSize: Int64;
  LNameSize: Integer;
  LCopied: Int64;
begin
  LEntry := GetEntry(AIndex);
  LStart := LEntry.Offset;
  LSize := LEntry.Size;
  // the length byte of the name; past the end of the file peek() says EOF, that is 255 as an unsigned char
  if LStart < Length(FBytes) then
    LNameSize := FBytes[LStart]
  else
    LNameSize := 255;
  if LNameSize <= XCOM_CAT_NAME_LIMIT then
  begin
    if AKeepName then
      Inc(LSize, LNameSize + 1)
    else
      Inc(LStart, LNameSize + 1);
  end;
  if LSize > MAX_ENTRY_BYTES then
    raise EXcomDataException.CreateFmt(SXcomCatEntryTooBig, [AIndex, LSize]);
  SetLength(Result, LSize);
  // what the file does not have is zero (the C++ leaves the memory as it was)
  if LSize > 0 then
    FillChar(Result[0], LSize, 0);
  LCopied := Length(FBytes) - LStart;
  if LCopied > LSize then
    LCopied := LSize;
  if LCopied > 0 then
    Move(FBytes[LStart], Result[0], LCopied);
end;

end.
