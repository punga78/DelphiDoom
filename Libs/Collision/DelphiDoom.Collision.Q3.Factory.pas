{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model of Quake III Arena:     }
{  factory                                                                     }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Q3.Factory;

interface

uses
  System.SysUtils, DelphiDoom.MapFile.Bsp.Intf, DelphiDoom.Collision.Q3.Intf;

type
  /// <summary>The only place that knows the classes of the Quake III collision model</summary>
  TQ3CollisionFactory = class
  public
    /// <summary>
    ///   CM_LoadMap on a BSP that was read already: the lumps are checked with the validator of
    ///   Libs\MapFile (a corrupt file raises EQ3CollisionException). The patches do not
    ///   collide unless a builder is given.
    /// </summary>
    class function CreateFromBsp(const AFile: IBspFile; const AName: AnsiString = '';
      const APatchBuilder: IQ3PatchCollideBuilder = nil): IQ3CollisionModel; static;
    /// <summary>CM_LoadMap on a file read through the reader (its file system is the injected one)</summary>
    class function CreateFromFile(const AReader: IBspReader; const AFileName: AnsiString;
      const APatchBuilder: IQ3PatchCollideBuilder = nil): IQ3CollisionModel; static;
    /// <summary>CM_LoadMap on bytes already in memory</summary>
    class function CreateFromBytes(const AReader: IBspReader; const AData: TBytes; const AName: AnsiString;
      const APatchBuilder: IQ3PatchCollideBuilder = nil): IQ3CollisionModel; static;
  end;

implementation

uses
  DelphiDoom.MapFile.Bsp.Factory, DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.ClipMap,
  DelphiDoom.Collision.Q3.Loader, DelphiDoom.Collision.Q3.Model;

resourcestring
  SCouldNotLoad = 'Couldn''t load %s';

class function TQ3CollisionFactory.CreateFromBsp(const AFile: IBspFile; const AName: AnsiString;
  const APatchBuilder: IQ3PatchCollideBuilder): IQ3CollisionModel;
var
  LLoader: TQ3ClipMapLoader;
  LMap: TQ3ClipMap;
begin
  LLoader := TQ3ClipMapLoader.Create(TBspFactory.CreateValidator, APatchBuilder);
  try
    LMap := LLoader.Load(AFile, AName);
  finally
    LLoader.Free;
  end;
  Result := TQ3CollisionModel.Create(LMap);
end;

class function TQ3CollisionFactory.CreateFromFile(const AReader: IBspReader; const AFileName: AnsiString;
  const APatchBuilder: IQ3PatchCollideBuilder): IQ3CollisionModel;
var
  LFile: IBspFile;
begin
  LFile := AReader.Parse(AFileName);
  if not Assigned(LFile) then
    raise EQ3CollisionException.CreateFmt(SCouldNotLoad, [string(AFileName)]);
  Result := CreateFromBsp(LFile, AFileName, APatchBuilder);
end;

class function TQ3CollisionFactory.CreateFromBytes(const AReader: IBspReader; const AData: TBytes;
  const AName: AnsiString; const APatchBuilder: IQ3PatchCollideBuilder): IQ3CollisionModel;
begin
  Result := CreateFromBsp(AReader.ParseBytes(AData, AName), AName, APatchBuilder);
end;

end.
