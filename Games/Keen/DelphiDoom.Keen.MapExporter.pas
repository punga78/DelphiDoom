{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - a map saved as a picture                          }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.MapExporter;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf, DelphiDoom.Platform.Intf;

type
  /// <summary>Loads a map, draws it with the renderer, encodes the picture and writes the file</summary>
  TKeenMapExporter = class(TInterfacedObject, IKeenMapExporter)
  strict private
    FData: IKeenGameData;
    FRenderer: IKeenMapRenderer;
    FEncoder: IKeenImageEncoder;
    FFiles: IFileStore;
  public
    constructor Create(const AData: IKeenGameData; const ARenderer: IKeenMapRenderer;
      const AEncoder: IKeenImageEncoder; const AFiles: IFileStore);
    procedure SaveMapPicture(AMapNumber: Integer; const APath: string);
  end;

implementation

{ TKeenMapExporter }

constructor TKeenMapExporter.Create(const AData: IKeenGameData; const ARenderer: IKeenMapRenderer;
  const AEncoder: IKeenImageEncoder; const AFiles: IFileStore);
begin
  inherited Create;
  if not Assigned(AData) then
    raise EArgumentNilException.Create('AData');
  if not Assigned(ARenderer) then
    raise EArgumentNilException.Create('ARenderer');
  if not Assigned(AEncoder) then
    raise EArgumentNilException.Create('AEncoder');
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  FData := AData;
  FRenderer := ARenderer;
  FEncoder := AEncoder;
  FFiles := AFiles;
end;

procedure TKeenMapExporter.SaveMapPicture(AMapNumber: Integer; const APath: string);
var
  LBytes: TBytes;
begin
  LBytes := FEncoder.Encode(FRenderer.Render(FData.Maps.LoadMap(AMapNumber), FData.Graphics));
  if not FFiles.Write(APath, @LBytes[0], Length(LBytes)) then
    raise EKeenException.CreateFmt(SKeenFileNotWritten, [APath]);
end;

end.
