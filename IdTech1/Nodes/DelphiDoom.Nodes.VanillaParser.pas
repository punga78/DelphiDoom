{******************************************************************************}
{                                                                              }
{  DelphiDoom: Nodes library - SEGS, SSECTORS and NODES of a map               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Nodes.VanillaParser;

interface

uses
  System.SysUtils, DelphiDoom.Nodes.Types;

type
  /// <summary>
  ///   The three lumps of the nodes of the original maps as arrays of records. A lump that stops
  ///   in the middle of a record gives the whole records that it has. The engine decides what to
  ///   do with too many records (the original format cannot address more than 32767)
  /// </summary>
  TNodesVanillaParser = class sealed
  public
    class function ParseSegs(const ABytes: TBytes): TArray<TNodesVanillaSeg>; static;
    class function ParseSubsectors(const ABytes: TBytes): TArray<TNodesVanillaSubsector>; static;
    class function ParseNodes(const ABytes: TBytes): TArray<TNodesVanillaNode>; static;
  end;

implementation

{ TNodesVanillaParser }

class function TNodesVanillaParser.ParseSegs(const ABytes: TBytes): TArray<TNodesVanillaSeg>;
begin
  SetLength(Result, Length(ABytes) div SizeOf(TNodesVanillaSeg));
  if Length(Result) > 0 then
    Move(ABytes[0], Result[0], Length(Result) * SizeOf(TNodesVanillaSeg));
end;

class function TNodesVanillaParser.ParseSubsectors(const ABytes: TBytes): TArray<TNodesVanillaSubsector>;
begin
  SetLength(Result, Length(ABytes) div SizeOf(TNodesVanillaSubsector));
  if Length(Result) > 0 then
    Move(ABytes[0], Result[0], Length(Result) * SizeOf(TNodesVanillaSubsector));
end;

class function TNodesVanillaParser.ParseNodes(const ABytes: TBytes): TArray<TNodesVanillaNode>;
begin
  SetLength(Result, Length(ABytes) div SizeOf(TNodesVanillaNode));
  if Length(Result) > 0 then
    Move(ABytes[0], Result[0], Length(Result) * SizeOf(TNodesVanillaNode));
end;

end.
