{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the factory: the composition root           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Factory;

interface

uses
  DelphiDoom.Logging.Intf,
  DelphiDoom.Models.Intf,
  DelphiDoom.Models.Definition.Intf;

type
  /// <summary>The only place that knows the classes behind the interfaces of the models library</summary>
  TModelsFactory = class
  public
    /// <summary>The reader of MD2 files</summary>
    class function CreateMd2Parser: IMd2Parser; static;
    /// <summary>An empty list of commands of a procedural model</summary>
    class function CreateCommandStream: IModelCommandStream; static;
    /// <summary>The reader of the MODELDEF lump; the problems of the text are warnings to the log</summary>
    class function CreateDefinitionParser(const ALookup: IModelDefinitionLookup;
      const ALog: ILog): IModelDefinitionParser; static;
  end;

implementation

uses
  DelphiDoom.Models.Md2Parser,
  DelphiDoom.Models.CommandStream,
  DelphiDoom.Models.Definition.Parser;

{ TModelsFactory }

class function TModelsFactory.CreateMd2Parser: IMd2Parser;
begin
  Result := TMd2Parser.Create;
end;

class function TModelsFactory.CreateCommandStream: IModelCommandStream;
begin
  Result := TModelCommandStream.Create;
end;

class function TModelsFactory.CreateDefinitionParser(const ALookup: IModelDefinitionLookup;
  const ALog: ILog): IModelDefinitionParser;
begin
  Result := TModelDefinitionParser.Create(ALookup, ALog);
end;

end.
