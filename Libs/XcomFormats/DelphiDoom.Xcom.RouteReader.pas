{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - the .RMP files of the battlescape         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.RouteReader;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Intf;

type
  /// <summary>
  ///   BattlescapeGenerator::loadRMP: records of 24 bytes (the position is Y, X, Z; five links of three bytes of which
  ///   only the first, the node, is used by the game; type, rank, flags, reserved and priority at the end).
  ///   A node that is not in the block is kept as a dummy so the numbers of the other links stay right, and
  ///   the links to it are cut. A link to a node of the file is a number of the whole battle map (nodeOffset more);
  ///   a link of 251..255 is not a node but a direction or "unused" (256 less: -5..-1)
  /// </summary>
  TXcomRouteReader = class(TInterfacedObject, IXcomRouteReader)
  public
    function Read(const ABytes: TBytes): TArray<TXcomRmpRecord>;
    function Resolve(const ARecords: TArray<TXcomRmpRecord>; ASizeX, ASizeY, ASizeZ,
      AOffsetX, AOffsetY, ANodeOffset: Integer; out ACulled: TArray<Integer>): TArray<TXcomRouteNode>;
  end;

implementation

{ TXcomRouteReader }

function TXcomRouteReader.Read(const ABytes: TBytes): TArray<TXcomRmpRecord>;
var
  LCount: Integer;
begin
  LCount := Length(ABytes) div XCOM_RMP_RECORD_BYTES;
  SetLength(Result, LCount);
  if LCount > 0 then
    Move(ABytes[0], Result[0], LCount * XCOM_RMP_RECORD_BYTES);
end;

function TXcomRouteReader.Resolve(const ARecords: TArray<TXcomRmpRecord>; ASizeX, ASizeY, ASizeZ,
  AOffsetX, AOffsetY, ANodeOffset: Integer; out ACulled: TArray<Integer>): TArray<TXcomRouteNode>;
var
  LCulled: TList<Integer>;
  LIndex: Integer;
  LLink: Integer;
  LNode: Integer;
  LConnect: Integer;
  LRecord: TXcomRmpRecord;
begin
  SetLength(Result, Length(ARecords));
  LCulled := TList<Integer>.Create;
  try
    for LIndex := 0 to High(ARecords) do
    begin
      LRecord := ARecords[LIndex];
      FillChar(Result[LIndex], SizeOf(TXcomRouteNode), 0);
      Result[LIndex].Index := ANodeOffset + LIndex;
      if (LRecord.PosX < ASizeX) and (LRecord.PosY < ASizeY) and (LRecord.PosZ < ASizeZ) then
      begin
        Result[LIndex].X := AOffsetX + LRecord.PosX;
        Result[LIndex].Y := AOffsetY + LRecord.PosY;
        Result[LIndex].Z := ASizeZ - 1 - LRecord.PosZ;
        Result[LIndex].NodeType := LRecord.NodeType;
        Result[LIndex].Rank := LRecord.Rank;
        Result[LIndex].Flags := LRecord.Flags;
        Result[LIndex].Reserved := LRecord.Reserved;
        Result[LIndex].Priority := LRecord.Priority;
        for LLink := 0 to XCOM_RMP_LINKS - 1 do
        begin
          LConnect := LRecord.Links[LLink].Target;
          // 255/-1 = unused, 254/-2 = north, 253/-3 = east, 252/-4 = south, 251/-5 = west
          if LConnect <= 250 then
            Inc(LConnect, ANodeOffset)
          else
            Dec(LConnect, 256);
          Result[LIndex].Links[LLink] := LConnect;
        end;
      end
      else
      begin
        Result[LIndex].IsDummy := True;
        LCulled.Add(LIndex);
      end;
    end;
    // the links to a node that was culled: the C++ looks at the nodes of the block from the last one down
    for LNode in LCulled do
      for LIndex := High(Result) downto 0 do
        if not Result[LIndex].IsDummy then
          for LLink := 0 to XCOM_RMP_LINKS - 1 do
            if Result[LIndex].Links[LLink] = ANodeOffset + LNode then
              Result[LIndex].Links[LLink] := XCOM_LINK_UNUSED;
    ACulled := LCulled.ToArray;
  finally
    LCulled.Free;
  end;
end;

end.
