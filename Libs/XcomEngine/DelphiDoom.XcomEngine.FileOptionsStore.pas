{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the options in options.cfg                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.FileOptionsStore;

interface

uses
  System.SysUtils, System.IOUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Options,
  DelphiDoom.XcomEngine.OptionsStore.Intf;

type
  /// <summary>
  ///   IXcomOptionsStore on the file options.cfg of the user folder. Only the keys that TXcomOptions has are written
  ///   (the others of an options.cfg made by OpenXcom are lost when the file is saved)
  /// </summary>
  TXcomFileOptionsStore = class(TInterfacedObject, IXcomOptionsStore)
  strict private
    FFiles: IXcomFileSystem;
    FParser: IYamlParser;
    FPath: string;
  public
    constructor Create(const AFiles: IXcomFileSystem; const AParser: IYamlParser; const AUserFolder: string);
    procedure Load(AOptions: TXcomOptions);
    procedure Save(AOptions: TXcomOptions);
  end;

implementation

constructor TXcomFileOptionsStore.Create(const AFiles: IXcomFileSystem; const AParser: IYamlParser;
  const AUserFolder: string);
begin
  inherited Create;
  FFiles := AFiles;
  FParser := AParser;
  if AUserFolder <> '' then
    FPath := TPath.Combine(AUserFolder, 'options.cfg');
end;

procedure TXcomFileOptionsStore.Load(AOptions: TXcomOptions);
begin
  if (FPath <> '') and FFiles.FileExists(FPath) then
    AOptions.Load(FParser.Load(FFiles.ReadAll(FPath)));
end;

procedure TXcomFileOptionsStore.Save(AOptions: TXcomOptions);
begin
  if FPath <> '' then
    FFiles.WriteAll(FPath, TEncoding.UTF8.GetBytes(AOptions.Save));
end;

end.
