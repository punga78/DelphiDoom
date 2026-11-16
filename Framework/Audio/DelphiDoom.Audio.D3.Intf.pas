{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - 3D sound of Doom 3, contracts                   }
{                                                                              }
{  The part of idRenderWorld that sound uses (PointInArea, NumPortalsInArea,   }
{  GetPortal), as a small interface.                                           }
{  Based on the Doom 3 GPL Source Code (id Software); GPL v3 with the          }
{  additional terms of the Doom 3 Source Code License, as                      }
{  DelphiDoom.Audio.D3.Types. Copyright (C) 1999-2011 id Software LLC.        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.D3.Intf;

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.Audio.D3.Types;

type
  /// <summary>The portals of the render world as the sound world reads them</summary>
  ID3PortalWorld = interface
    ['{8B21C7E4-5D93-4F0A-A6B8-3E7D1C94F052}']
    /// <summary>PointInArea: the area that holds the point, -1 if it is outside the world</summary>
    function PointInArea(const APoint: TIdVec3): Integer;
    /// <summary>NumPortalsInArea</summary>
    function NumPortalsInArea(AArea: Integer): Integer;
    /// <summary>GetPortal</summary>
    function GetPortal(AArea, AIndex: Integer): TD3ExitPortal;
  end;

implementation

end.
