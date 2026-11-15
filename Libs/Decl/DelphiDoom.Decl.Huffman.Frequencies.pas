{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - the character frequencies of the text     }
{  of the decls (Huffman)                                                      }
{                                                                              }
{  Port of huffmanFrequencies, ClearHuffmanFrequencies and                     }
{  ListHuffmanFrequencies_f of framework\DeclManager.cpp (id Software, GPL     }
{  v3). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.      }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository    }
{  as a whole is GPL v2 or later.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Huffman.Frequencies;

interface

uses
  DelphiDoom.IdLib.Core.Intf;

const
  /// <summary>MAX_HUFFMAN_SYMBOLS: one symbol for every byte</summary>
  MAX_HUFFMAN_SYMBOLS = 256;

type
  /// <summary>
  ///   The frequency of each byte in the text of the decls, which the original builds its Huffman code
  ///   from. The table starts with the one that ships with Doom 3 (counted on its decls, compression ratio 64%).
  ///   <c>Clear</c> and <c>Count</c> are what the original does when it is built with
  ///   <c>GET_HUFFMAN_FREQUENCIES</c>: every frequency to 1, then one more for every byte of every text set.
  ///   The text of the decls is not compressed here, so the totals of the compression ratio are zero and
  ///   <c>List</c> says 100% as <c>listHuffmanFrequencies</c> does in a build that does not compress.
  /// </summary>
  TDeclHuffmanFrequencies = class
  strict private
    FFrequencies: array[0..MAX_HUFFMAN_SYMBOLS - 1] of Integer;
    FTotalUncompressedLength: Integer;
    FTotalCompressedLength: Integer;
    function GetFrequency(const ASymbol: Integer): Integer;
  public
    constructor Create;
    /// <summary>ClearHuffmanFrequencies: every frequency to 1</summary>
    procedure Clear;
    /// <summary>The counting of <c>SetTextLocal</c> under GET_HUFFMAN_FREQUENCIES: one more for each byte</summary>
    procedure Count(const AText: AnsiString);
    /// <summary>The frequency of a byte; <c>EArgumentOutOfRangeException</c> outside 0..255</summary>
    property Frequencies[const ASymbol: Integer]: Integer read GetFrequency; default;
    /// <summary>Sets the sizes the compression ratio is made from (the totals of the original)</summary>
    procedure SetTotals(const AUncompressed, ACompressed: Integer);
    /// <summary>ListHuffmanFrequencies_f: the ratio and the table as C++ source, to the log</summary>
    procedure List(const ALog: IIdLibLog);
  end;

implementation

uses
  System.SysUtils;

const
  SHIPPED: array[0..MAX_HUFFMAN_SYMBOLS - 1] of Integer = (
    $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001,
    $00000001, $00078fb6, $000352a7, $00000002, $00000001, $0002795e, $00000001, $00000001,
    $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001,
    $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001,
    $00049600, $000000dd, $00018732, $0000005a, $00000007, $00000092, $0000000a, $00000919,
    $00002dcf, $00002dda, $00004dfc, $0000039a, $000058be, $00002d13, $00014d8c, $00023c60,
    $0002ddb0, $0000d1fc, $000078c4, $00003ec7, $00003113, $00006b59, $00002499, $0000184a,
    $0000250b, $00004e38, $000001ca, $00000011, $00000020, $000023da, $00000012, $00000091,
    $0000000b, $00000b14, $0000035d, $0000137e, $000020c9, $00000e11, $000004b4, $00000737,
    $000006b8, $00001110, $000006b3, $000000fe, $00000f02, $00000d73, $000005f6, $00000be4,
    $00000d86, $0000014d, $00000d89, $0000129b, $00000db3, $0000015a, $00000167, $00000375,
    $00000028, $00000112, $00000018, $00000678, $0000081a, $00000677, $00000003, $00018112,
    $00000001, $000441ee, $000124b0, $0001fa3f, $00026125, $0005a411, $0000e50f, $00011820,
    $00010f13, $0002e723, $00003518, $00005738, $0002cc26, $0002a9b7, $0002db81, $0003b5fa,
    $000185d2, $00001299, $00030773, $0003920d, $000411cd, $00018751, $00005fbd, $000099b0,
    $00009242, $00007cf2, $00002809, $00005a1d, $00000001, $00005a1d, $00000001, $00000001,
    $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001,
    $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001,
    $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001,
    $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001,
    $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001,
    $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001,
    $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001,
    $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001,
    $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001,
    $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001,
    $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001,
    $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001,
    $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001,
    $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001,
    $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001,
    $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001, $00000001
  );

{ TDeclHuffmanFrequencies }

constructor TDeclHuffmanFrequencies.Create;
begin
  inherited Create;
  Move(SHIPPED, FFrequencies, SizeOf(FFrequencies));
end;

procedure TDeclHuffmanFrequencies.Clear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to MAX_HUFFMAN_SYMBOLS - 1 do
  begin
    FFrequencies[LIndex] := 1;
  end;
end;

procedure TDeclHuffmanFrequencies.Count(const AText: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AText) do
  begin
    Inc(FFrequencies[Byte(AText[LIndex])]);
  end;
end;

function TDeclHuffmanFrequencies.GetFrequency(const ASymbol: Integer): Integer;
begin
  if (ASymbol < 0) or (ASymbol >= MAX_HUFFMAN_SYMBOLS) then
    raise EArgumentOutOfRangeException.Create('ASymbol');
  Result := FFrequencies[ASymbol];
end;

procedure TDeclHuffmanFrequencies.SetTotals(const AUncompressed, ACompressed: Integer);
begin
  FTotalUncompressedLength := AUncompressed;
  FTotalCompressedLength := ACompressed;
end;

procedure TDeclHuffmanFrequencies.List(const ALog: IIdLibLog);
var
  LCompression: Integer;
  LIndex: Integer;
  LColumn: Integer;
  LLine: string;
begin
  if not Assigned(ALog) then
    Exit;
  // (int)( 100 * totalCompressedLength / totalUncompressedLength ): integer division, then the float cast
  if FTotalUncompressedLength = 0 then
    LCompression := 100
  else
    LCompression := (100 * FTotalCompressedLength) div FTotalUncompressedLength;
  ALog.Printf(Format('// compression ratio = %d%%'#10, [LCompression]));
  ALog.Printf('static int huffmanFrequencies[] = {'#10);
  LIndex := 0;
  while LIndex < MAX_HUFFMAN_SYMBOLS do
  begin
    LLine := #9;
    for LColumn := 0 to 7 do
    begin
      LLine := LLine + Format('0x%.8x,', [FFrequencies[LIndex + LColumn]]);
      if LColumn < 7 then
        LLine := LLine + ' ';
    end;
    ALog.Printf(LLine + #10);
    Inc(LIndex, 8);
  end;
  ALog.Printf('}'#10);
end;

end.