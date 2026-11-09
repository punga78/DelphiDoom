{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the factory of the I3D models               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.I3d.Factory;

interface

uses
  DelphiDoom.Models.I3d.Intf;

type
  /// <summary>
  ///   The only place that knows the classes behind the contracts of the I3D models (the models of
  ///   Speed Haste). Apart from TModelsFactory so that the executables that do not use I3D do not
  ///   link it.
  /// </summary>
  TI3dFactory = class
  public
    /// <summary>The reader of I3D files</summary>
    class function CreateParser: II3dParser; static;
    /// <summary>The reader of the correction files of the I3D models</summary>
    class function CreateCorrectionReader: II3dCorrectionReader; static;
    /// <summary>The drawing of an I3D model on a target; it has no state</summary>
    class function CreateRenderer: II3dModelRenderer; static;
  end;

implementation

uses
  DelphiDoom.Models.I3d.Parser,
  DelphiDoom.Models.I3d.CorrectionReader,
  DelphiDoom.Models.I3d.Renderer;

{ TI3dFactory }

class function TI3dFactory.CreateParser: II3dParser;
begin
  Result := TI3dParser.Create;
end;

class function TI3dFactory.CreateCorrectionReader: II3dCorrectionReader;
begin
  Result := TI3dCorrectionReader.Create;
end;

class function TI3dFactory.CreateRenderer: II3dModelRenderer;
begin
  Result := TI3dModelRenderer.Create;
end;

end.
