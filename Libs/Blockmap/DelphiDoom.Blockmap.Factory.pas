{******************************************************************************}
{                                                                              }
{  DelphiDoom: blockmap - the factory: the composition root                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Blockmap.Factory;

interface

uses
  DelphiDoom.Blockmap.Intf;

type
  /// <summary>The only place that knows the classes behind the interfaces of the blockmap library</summary>
  TBlockmapFactory = class
  public
    /// <summary>The builder of the blockmap of a level</summary>
    class function CreateBuilder: IBlockmapBuilder; static;
    /// <summary>The reader of the BLOCKMAP lump</summary>
    class function CreateLumpReader: IBlockmapLumpReader; static;
    /// <summary>The correction of the slime trails</summary>
    class function CreateSlimeTrailRemover: ISlimeTrailRemover; static;
  end;

implementation

uses
  DelphiDoom.Blockmap.Builder,
  DelphiDoom.Blockmap.LumpReader,
  DelphiDoom.Blockmap.SlimeTrails;

{ TBlockmapFactory }

class function TBlockmapFactory.CreateBuilder: IBlockmapBuilder;
begin
  Result := TBlockmapBuilder.Create;
end;

class function TBlockmapFactory.CreateLumpReader: IBlockmapLumpReader;
begin
  Result := TBlockmapLumpReader.Create;
end;

class function TBlockmapFactory.CreateSlimeTrailRemover: ISlimeTrailRemover;
begin
  Result := TBlockmapSlimeTrailRemover.Create;
end;

end.
