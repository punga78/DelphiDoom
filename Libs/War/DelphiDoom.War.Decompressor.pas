{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the decompression of the records                  }
{                                                                              }
{  Port of war1 (acoto87/war1), the decompression in wfile_loadWarFile of      }
{  war_file.c (the algorithm of "The File Formats of WarCraft: Orcs & Humans", }
{  2015), (c) 2019 Alejandro Coto Gutierrez, zlib License (see                 }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Decompressor;

{$Q-}
{$R-}

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The compression of the records: a window of 4096 bytes, at the start all zero. Groups of 8 items, each
  ///   group with a mask byte read from its low bit: 1 = a literal byte, 0 = two bytes with the position in the
  ///   window (low 12 bits) and the length minus 3 (high 4 bits); the window is filled with what is written
  /// </summary>
  TWarDecompressor = class
  public
    /// <summary>
    ///   Expands APayload (the record without its 4 byte header) to ALength bytes. EWarException if the data end
    ///   before that, or if they are too short for ALength to be possible (the original read what came after
    ///   the record and left the end of the buffer unwritten)
    /// </summary>
    class function Expand(const APayload: TBytes; ALength: Cardinal; AIndex: Integer): TBytes; static;
  end;

implementation

uses
  DelphiDoom.War.Types;

{ TWarDecompressor }

class function TWarDecompressor.Expand(const APayload: TBytes; ALength: Cardinal; AIndex: Integer): TBytes;
var
  LWindow: array[0..WAR_WINDOW_SIZE - 1] of Byte;
  LInput: Integer;
  LOutput: Integer;
  LLength: Integer;
  LMask: Byte;
  LItem: Integer;
  LPosition: Word;
  LCount: Integer;
  LStep: Integer;
  LValue: Byte;
begin
  // the format cannot give more than WAR_MAX_EXPANSION bytes for each byte of input
  if Int64(ALength) > Int64(Length(APayload)) * WAR_MAX_EXPANSION then
    raise EWarException.CreateFmt(SWarImpossibleLength, [AIndex, ALength, Length(APayload)]);
  LLength := Integer(ALength);
  SetLength(Result, LLength);
  FillChar(LWindow, SizeOf(LWindow), 0);
  LInput := 0;
  LOutput := 0;
  while (LInput < Length(APayload)) and (LOutput < LLength) do
  begin
    LMask := APayload[LInput];
    Inc(LInput);
    LItem := 0;
    while (LItem < 8) and (LOutput < LLength) do
    begin
      if (LMask and 1) = 1 then
      begin
        // uncompressed byte
        if LInput >= Length(APayload) then
          raise EWarException.CreateFmt(SWarTruncatedRecord, [LOutput, LLength]);
        LValue := APayload[LInput];
        Inc(LInput);
        LWindow[LOutput mod WAR_WINDOW_SIZE] := LValue;
        Result[LOutput] := LValue;
        Inc(LOutput);
      end
      else
      begin
        // compressed block: low 12 bits the start in the window, high 4 bits the count - 3
        if LInput + 2 > Length(APayload) then
          raise EWarException.CreateFmt(SWarTruncatedRecord, [LOutput, LLength]);
        LPosition := Word(APayload[LInput]) or (Word(APayload[LInput + 1]) shl 8);
        Inc(LInput, 2);
        LCount := LPosition div WAR_WINDOW_SIZE + 3;
        LPosition := LPosition mod WAR_WINDOW_SIZE;
        LStep := 0;
        while (LStep < LCount) and (LOutput < LLength) do
        begin
          LValue := LWindow[(LPosition + LStep) mod WAR_WINDOW_SIZE];
          LWindow[LOutput mod WAR_WINDOW_SIZE] := LValue;
          Result[LOutput] := LValue;
          Inc(LOutput);
          Inc(LStep);
        end;
      end;
      LMask := LMask shr 1;
      Inc(LItem);
    end;
  end;
  if LOutput < LLength then
    raise EWarException.CreateFmt(SWarTruncatedRecord, [LOutput, LLength]);
end;

end.
