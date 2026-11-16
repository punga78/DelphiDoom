{******************************************************************************}
{                                                                              }
{  DD_IDE: the pk3 (zip) file of Windows for the ide library                   }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Win.Archive;

interface

uses
  System.SysUtils,
  DelphiDoom.Ide.Intf,
  ide_zipfile;

type
  /// <summary>An archive on the zip writer of the ide (TZipFile)</summary>
  TZipIdeArchive = class(TInterfacedObject, IIdeArchive)
  strict private
    FZip: TZipFile;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddFile(const AName: string; const AData: AnsiString; const ADate: TDateTime);
    procedure SaveToFile(const AFileName: string);
  end;

implementation

{ TZipIdeArchive }

constructor TZipIdeArchive.Create;
begin
  inherited Create;
  FZip := TZipFile.Create;
end;

destructor TZipIdeArchive.Destroy;
begin
  FZip.Free;
  inherited Destroy;
end;

procedure TZipIdeArchive.AddFile(const AName: string; const AData: AnsiString; const ADate: TDateTime);
var
  LIndex: Integer;
begin
  LIndex := FZip.AddFile(AName);
  FZip.Data[LIndex] := string(AData);
  FZip.DateTime[LIndex] := ADate;
end;

procedure TZipIdeArchive.SaveToFile(const AFileName: string);
begin
  FZip.SaveToFile(AFileName);
end;

end.
