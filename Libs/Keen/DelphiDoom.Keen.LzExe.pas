{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the memory image of a DOS program, packed with    }
{  LZEXE or not                                                                 }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later: the    }
{  tool that unpacks KDREAMS.EXE (LZEXE 0.91) to read its data                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.LzExe;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types;

type
  /// <summary>
  ///   The memory image of a DOS program (what is after the header of the file, with the code and the data
  ///   at the places where the program has them): an EXE that LZEXE 0.91 packed (the shareware KDREAMS.EXE) is
  ///   expanded, any other MZ file is taken as it is after its header. The addresses that the program has in its
  ///   data segment are places in this image
  /// </summary>
  TKeenLzExe = class
  public
    /// <summary>
    ///   EKeenDataException if the file is not an MZ program, if the packed data end too soon or if the packer is
    ///   not LZEXE 0.91 ("LZ91")
    /// </summary>
    class function LoadImage(const AExecutable: TBytes): TBytes; static;
    /// <summary>True if the file is an EXE that LZEXE 0.91 packed</summary>
    class function IsPacked(const AExecutable: TBytes): Boolean; static;
  end;

implementation

const
  SNotProgram = 'Keen: the file is not a DOS program (MZ)';
  SPackedEnds = 'Keen: the packed program ends too soon';
  SBadPacker = 'Keen: the packed program is not an LZEXE 0.91 one';

function Word16(const ABytes: TBytes; APosition: Integer): Integer; inline;
begin
  if (APosition < 0) or (APosition + 1 >= Length(ABytes)) then
    raise EKeenDataException.Create(SPackedEnds);
  Result := ABytes[APosition] or (ABytes[APosition + 1] shl 8);
end;

class function TKeenLzExe.IsPacked(const AExecutable: TBytes): Boolean;
begin
  Result := (Length(AExecutable) > $20) and (AExecutable[0] = Ord('M')) and (AExecutable[1] = Ord('Z')) and
    (AExecutable[$1C] = Ord('L')) and (AExecutable[$1D] = Ord('Z')) and (AExecutable[$1E] = Ord('9')) and
    (AExecutable[$1F] = Ord('1'));
end;

class function TKeenLzExe.LoadImage(const AExecutable: TBytes): TBytes;
var
  LHeaderParagraphs: Integer;
  LCs: Integer;
  LInfoBase: Integer;
  LStart: Integer;
  LPosition: Integer;
  LBitBuffer: Integer;
  LBitCount: Integer;
  LOutput: TBytes;
  LLength: Integer;
  LSpan: Integer;
  LLow: Integer;
  LHigh: Integer;
  LIndex: Integer;
  LCount: Integer;

  function GetBit: Integer;
  begin
    Result := LBitBuffer and 1;
    LBitBuffer := LBitBuffer shr 1;
    Dec(LBitCount);
    if LBitCount = 0 then
    begin
      LBitBuffer := Word16(AExecutable, LPosition);
      Inc(LPosition, 2);
      LBitCount := 16;
    end;
  end;

  function GetByte: Integer;
  begin
    if LPosition >= Length(AExecutable) then
      raise EKeenDataException.Create(SPackedEnds);
    Result := AExecutable[LPosition];
    Inc(LPosition);
  end;

  procedure Put(AValue: Byte);
  begin
    if LCount >= Length(LOutput) then
      SetLength(LOutput, (LCount + 4096) * 2);
    LOutput[LCount] := AValue;
    Inc(LCount);
  end;

begin
  if (Length(AExecutable) < $20) or (AExecutable[0] <> Ord('M')) or (AExecutable[1] <> Ord('Z')) then
    raise EKeenDataException.Create(SNotProgram);
  LHeaderParagraphs := Word16(AExecutable, 8);
  if not IsPacked(AExecutable) then
  begin
    if LHeaderParagraphs * 16 > Length(AExecutable) then
      raise EKeenDataException.Create(SNotProgram);
    Exit(Copy(AExecutable, LHeaderParagraphs * 16, Length(AExecutable)));
  end;
  // the packer leaves a block of eight words at the entry segment; the packed data end where it says
  LCs := Word16(AExecutable, 22);
  LInfoBase := (LCs + LHeaderParagraphs) * 16;
  LStart := (LCs - Word16(AExecutable, LInfoBase + 8) + LHeaderParagraphs) * 16;
  LPosition := LStart;
  LBitBuffer := Word16(AExecutable, LPosition);
  Inc(LPosition, 2);
  LBitCount := 16;
  LCount := 0;
  while True do
  begin
    if GetBit <> 0 then
    begin
      Put(Byte(GetByte));
      Continue;
    end;
    if GetBit = 0 then
    begin
      // a short match: two bits for the length, a byte for the distance
      LLength := GetBit shl 1;
      LLength := LLength or GetBit;
      Inc(LLength, 2);
      LSpan := GetByte or $FF00;
      LSpan := LSpan - $10000;
    end
    else
    begin
      LLow := GetByte;
      LHigh := GetByte;
      LSpan := LLow or (((LHigh and (not 7)) shl 5) or $E000);
      LSpan := LSpan - $10000;
      LLength := (LHigh and 7) + 2;
      if LLength = 2 then
      begin
        LLength := GetByte;
        if LLength = 0 then
          Break;
        if LLength = 1 then
          Continue;
        Inc(LLength);
      end;
    end;
    for LIndex := 1 to LLength do
    begin
      if LCount + LSpan < 0 then
        raise EKeenDataException.Create(SBadPacker);
      Put(LOutput[LCount + LSpan]);
    end;
  end;
  SetLength(LOutput, LCount);
  Result := LOutput;
end;

end.
