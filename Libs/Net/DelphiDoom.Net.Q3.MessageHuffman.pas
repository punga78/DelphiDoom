{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the Huffman coder of the messages of Quake III    }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): msg.c           }
{  (msg_hData, MSG_initHuffman), huffman.c. Copyright (C) 1999-2005 id         }
{  Software, Inc.                                                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Q3.MessageHuffman;

interface

uses
  System.SysUtils, DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Intf, DelphiDoom.Net.Q3.AdaptiveHuffman;

const
  /// <summary>
  ///   msg_hData: how many times each byte value is counted before the first message (the statistics of the
  ///   original game); they build the tree that every message uses and that never changes afterwards
  /// </summary>
  Q3_MESSAGE_HUFFMAN_WEIGHTS: array[0..255] of Integer = (
    250315, 41193, 6292, 7106, 3730, 3750, 6110, 23283, 33317, 6950, 7838, 9714, 9257, 17259, 3949,
    1778, 8288, 1604, 1590, 1663, 1100, 1213, 1238, 1134, 1749, 1059, 1246, 1149, 1273, 4486, 2805,
    3472, 21819, 1159, 1670, 1066, 1043, 1012, 1053, 1070, 1726, 888, 1180, 850, 960, 780, 1752,
    3296, 10630, 4514, 5881, 2685, 4650, 3837, 2093, 1867, 2584, 1949, 1972, 940, 1134, 1788, 1670,
    1206, 5719, 6128, 7222, 6654, 3710, 3795, 1492, 1524, 2215, 1140, 1355, 971, 2180, 1248, 1328,
    1195, 1770, 1078, 1264, 1266, 1168, 965, 1155, 1186, 1347, 1228, 1529, 1600, 2617, 2048, 2546,
    3275, 2410, 3585, 2504, 2800, 2675, 6146, 3663, 2840, 14253, 3164, 2221, 1687, 3208, 2739,
    3512, 4796, 4091, 3515, 5288, 4016, 7937, 6031, 5360, 3924, 4892, 3743, 4566, 4807, 5852, 6400,
    6225, 8291, 23243, 7838, 7073, 8935, 5437, 4483, 3641, 5256, 5312, 5328, 5370, 3492, 2458,
    1694, 1821, 2121, 1916, 1149, 1516, 1367, 1236, 1029, 1258, 1104, 1245, 1006, 1149, 1025, 1241,
    952, 1287, 997, 1713, 1009, 1187, 879, 1099, 929, 1078, 951, 1656, 930, 1153, 1030, 1262, 1062,
    1214, 1060, 1621, 930, 1106, 912, 1034, 892, 1158, 990, 1175, 850, 1121, 903, 1087, 920, 1144,
    1056, 3462, 2240, 4397, 12136, 7758, 1345, 1307, 3278, 1950, 886, 1023, 1112, 1077, 1042, 1061,
    1071, 1484, 1001, 1096, 915, 1052, 995, 1070, 876, 1111, 851, 1059, 805, 1112, 923, 1103, 817,
    1899, 1872, 976, 841, 1127, 956, 1159, 950, 7791, 954, 1289, 933, 1127, 3207, 1020, 927, 1355,
    768, 1040, 745, 952, 805, 1073, 740, 1013, 805, 1008, 796, 996, 1057, 11457, 13504
  );

type
  /// <summary>
  ///   msgHuff and MSG_initHuffman: the two trees (compressor and decompressor) of the messages, built
  ///   from the weights of msg_hData. The state of the original is a global initialised by the first message;
  ///   here it is an object that the messages receive, so building it is the cost of making one (about 1.1
  ///   million updates of each tree): make one and share it
  /// </summary>
  TQ3MessageHuffman = class(TInterfacedObject, IQ3HuffmanCoder)
  strict private
    FCompressor: TQ3AdaptiveHuffman;
    FDecompressor: TQ3AdaptiveHuffman;
  public
    constructor Create;
    destructor Destroy; override;
    procedure PutBit(ABit: Integer; var AData: TBytes; var AOffset: Integer);
    function GetBit(const AData: TBytes; var AOffset: Integer): Integer;
    procedure Transmit(AValue: Integer; var AData: TBytes; var AOffset: Integer);
    function Receive(const AData: TBytes; var AOffset: Integer): Integer;
  end;

implementation

{ TQ3MessageHuffman }

constructor TQ3MessageHuffman.Create;
var
  LSymbol, LCount: Integer;
begin
  inherited Create;
  FCompressor := TQ3AdaptiveHuffman.Create;
  FDecompressor := TQ3AdaptiveHuffman.Create;
  for LSymbol := 0 to 255 do
    for LCount := 1 to Q3_MESSAGE_HUFFMAN_WEIGHTS[LSymbol] do
    begin
      FCompressor.AddRef(LSymbol);
      FDecompressor.AddRef(LSymbol);
    end;
end;

destructor TQ3MessageHuffman.Destroy;
begin
  FDecompressor.Free;
  FCompressor.Free;
  inherited Destroy;
end;

procedure TQ3MessageHuffman.PutBit(ABit: Integer; var AData: TBytes; var AOffset: Integer);
begin
  TQ3AdaptiveHuffman.PutBit(ABit, AData, AOffset);
end;

function TQ3MessageHuffman.GetBit(const AData: TBytes; var AOffset: Integer): Integer;
begin
  Result := TQ3AdaptiveHuffman.GetBit(AData, AOffset);
end;

procedure TQ3MessageHuffman.Transmit(AValue: Integer; var AData: TBytes; var AOffset: Integer);
begin
  FCompressor.OffsetTransmit(AValue, AData, AOffset);
end;

function TQ3MessageHuffman.Receive(const AData: TBytes; var AOffset: Integer): Integer;
begin
  Result := FDecompressor.OffsetReceive(AData, AOffset);
end;

end.
