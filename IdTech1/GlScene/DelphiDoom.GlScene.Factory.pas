{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL scene - the factory                                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlScene.Factory;

interface

uses
  DelphiDoom.GlScene.Types,
  DelphiDoom.GlScene.DrawList;

type
  /// <summary>Creates the objects of the OpenGL scene library</summary>
  TGlSceneFactory = class
  public
    /// <summary>An empty draw list for records of the given sizes; the caller owns it and frees it</summary>
    /// <remarks>It is given as a class and not as an interface because it is called for every item of a frame</remarks>
    class function CreateDrawList(const ASizes: TGlSceneItemSizes): TGlSceneDrawList; static;
  end;

implementation

{ TGlSceneFactory }

class function TGlSceneFactory.CreateDrawList(const ASizes: TGlSceneItemSizes): TGlSceneDrawList;
begin
  Result := TGlSceneDrawList.Create(ASizes);
end;

end.
