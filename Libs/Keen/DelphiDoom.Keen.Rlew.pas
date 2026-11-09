{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - RLEW expansion                                    }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  CA_RLEWexpand of id_ca.c                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Rlew;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   Run length encoding of words: a word that is not the tag is copied, the tag is followed by a count
  ///   and a value that is written count times (a count of 0 writes nothing)
  /// </summary>
  /// <remarks>
  ///   Difference from the C (assembler, "a repeat count that produces 0xfff0 bytes can blow this"): a run
  ///   that would go past the end of the output, or data that end before it is full, raise
  ///   EKeenDataException; the C writes on the memory after the buffer or reads what is after the data.
  ///   The words are read byte by byte (little endian)
  /// </remarks>
  TKeenRlew = class(TInterfacedObject, IKeenRlew)
  public
    function Expand(const ASource: TBytes; ASourceOffset, ADestLength: Integer;
      ATag: Word): TBytes;
  end;

implementation

uses
  DelphiDoom.Keen.LittleEndian;

{ TKeenRlew }

function TKeenRlew.Expand(const ASource: TBytes; ASourceOffset, ADestLength: Integer;
  ATag: Word): TBytes;
var
  LWords: Integer;
  LWritten: Integer;
  LPosition: Integer;
  LValue: Word;
  LCount: Integer;
  LRepeated: Word;
  LIndex: Integer;
begin
  if ADestLength < 0 then
    raise EKeenDataException.CreateFmt(SKeenLengthInvalid, [ADestLength]);
  LWords := ADestLength div 2;
  SetLength(Result, LWords * 2);
  LWritten := 0;
  LPosition := ASourceOffset;
  while LWritten < LWords do
  begin
    if (LPosition < 0) or (LPosition + 2 > Length(ASource)) then
      raise EKeenDataException.CreateFmt(SKeenRlewTruncated, [LWritten, LWords]);
    LValue := TKeenLittleEndian.ReadWord(ASource, LPosition);
    Inc(LPosition, 2);
    if LValue <> ATag then
    begin
      Result[LWritten * 2] := Byte(LValue);
      Result[LWritten * 2 + 1] := Byte(LValue shr 8);
      Inc(LWritten);
    end
    else
    begin
      if LPosition + 4 > Length(ASource) then
        raise EKeenDataException.CreateFmt(SKeenRlewTruncated, [LWritten, LWords]);
      LCount := TKeenLittleEndian.ReadWord(ASource, LPosition);
      LRepeated := TKeenLittleEndian.ReadWord(ASource, LPosition + 2);
      Inc(LPosition, 4);
      if LWritten + LCount > LWords then
        raise EKeenDataException.CreateFmt(SKeenRlewOverflow, [LWords]);
      for LIndex := 0 to LCount - 1 do
      begin
        Result[LWritten * 2] := Byte(LRepeated);
        Result[LWritten * 2 + 1] := Byte(LRepeated shr 8);
        Inc(LWritten);
      end;
    end;
  end;
end;

end.
