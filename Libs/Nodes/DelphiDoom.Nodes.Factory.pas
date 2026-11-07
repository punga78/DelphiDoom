{******************************************************************************}
{                                                                              }
{  DelphiDoom: Nodes library - the factory: the composition root               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Nodes.Factory;

interface

uses
  System.SysUtils, DelphiDoom.Nodes.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the nodes</summary>
  TNodesFactory = class sealed
  public
    class function CreateGlDetector(const ASource: INodesLumpSource): INodesGlDetector; static;
    class function CreateGlMapFinder(const ASource: INodesLumpSource): INodesGlMapFinder; static;
    /// <param name="AHexen">True for the Hexen engine: its maps are already in the Hexen format</param>
    class function CreateGlbspInputBuilder(const ASource: INodesLumpSource;
      AHexen: Boolean): INodesGlbspInputBuilder; static;
    /// <summary>Reads a GWA from its bytes</summary>
    /// <exception cref="ENodesException">The bytes are not a GWA</exception>
    class function ReadGwa(const ABytes: TBytes): INodesGwa; static;
  end;

implementation

uses
  DelphiDoom.Nodes.GlDetector, DelphiDoom.Nodes.GlMapFinder, DelphiDoom.Nodes.GlbspInputBuilder,
  DelphiDoom.Nodes.GwaReader;

{ TNodesFactory }

class function TNodesFactory.CreateGlDetector(const ASource: INodesLumpSource): INodesGlDetector;
begin
  Result := TNodesGlDetector.Create(ASource);
end;

class function TNodesFactory.CreateGlMapFinder(const ASource: INodesLumpSource): INodesGlMapFinder;
begin
  Result := TNodesGlMapFinder.Create(ASource);
end;

class function TNodesFactory.CreateGlbspInputBuilder(const ASource: INodesLumpSource;
  AHexen: Boolean): INodesGlbspInputBuilder;
begin
  Result := TNodesGlbspInputBuilder.Create(ASource, AHexen);
end;

class function TNodesFactory.ReadGwa(const ABytes: TBytes): INodesGwa;
begin
  Result := TNodesGwaReader.Read(ABytes);
end;

end.
