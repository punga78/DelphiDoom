{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: the MA loader                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Ma.Loader;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Intf,
  DelphiDoom.Models.Static.Ase.Types;

type
  /// <summary>
  ///   The bytes of a .ma file to a static model: the parser and the converter in a row
  ///   (MA_Load and LoadMA). The errors of the lexer are EStaticModelException like the ones of
  ///   the loader itself.
  /// </summary>
  TMaModelLoader = class(TInterfacedObject, IStaticModelLoader)
  strict private
    FOptions: TStaticLoadOptions;
    FResolver: TStaticPathResolver;
  public
    /// <summary>The resolver turns the paths of the pictures into material names (nil keeps the path)</summary>
    constructor Create(const AOptions: TStaticLoadOptions; const AResolver: TStaticPathResolver = nil);
    function Load(const AData: TBytes; const AName: string): IStaticModel;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Exceptions,
  DelphiDoom.Models.Static.Ma.Types,
  DelphiDoom.Models.Static.Ma.Parser,
  DelphiDoom.Models.Static.Ma.Converter;

{ TMaModelLoader }

constructor TMaModelLoader.Create(const AOptions: TStaticLoadOptions; const AResolver: TStaticPathResolver);
begin
  inherited Create;
  FOptions := AOptions;
  FResolver := AResolver;
end;

function TMaModelLoader.Load(const AData: TBytes; const AName: string): IStaticModel;
var
  LParser: TMaParser;
  LConverter: TMaConverter;
  LModel: TMaModel;
  LText: AnsiString;
begin
  SetString(LText, PAnsiChar(AData), Length(AData));
  LParser := TMaParser.Create(FResolver);
  try
    try
      LModel := LParser.Parse(LText, AnsiString(AName));
    except
      on E: EIdLibException do
        raise EStaticModelException.CreateAtLine(E.Message, 0);
    end;
    try
      LConverter := TMaConverter.Create(FOptions);
      try
        Result := LConverter.Convert(LModel, AName);
      finally
        LConverter.Free;
      end;
    finally
      LModel.Free;
    end;
  finally
    LParser.Free;
  end;
end;

end.
