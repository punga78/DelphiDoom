{******************************************************************************}
{                                                                              }
{  DelphiDoom: configuration library - the format of the file                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Configuration.Format;

interface

uses
  System.SysUtils, DelphiDoom.Configuration.Intf;

type
  /// <summary>The format of the configuration file of the engine</summary>
  TConfigurationFormat = class(TInterfacedObject, IConfigurationFormat)
  private
    function VersionText(AVersionNumber: Integer): string;
  public
    function FormatHeader(const AApplicationTitle: string; AVersionNumber: Integer): string;
    function AcceptsHeader(const AHeader: string; ACurrentVersion: Integer): Boolean;
    function Parse(const ALines: TArray<string>): IConfigurationDocument;
    function CreateWriter(const AHeader: string): IConfigurationWriter;
    function ParseInteger(const AText: string): Integer;
    function ParseBoolean(const AText: string): Boolean;
    function FormatInteger(AValue: Integer): string;
    function FormatBoolean(AValue: Boolean): string;
  end;

implementation

uses
  DelphiDoom.Configuration.Types, DelphiDoom.Configuration.Document,
  DelphiDoom.Configuration.Writer, DelphiDoom.Configuration.Values;

{ TConfigurationFormat }

function TConfigurationFormat.VersionText(AVersionNumber: Integer): string;
begin
  Result := Format('ver %d.%.2d', [AVersionNumber div 100, AVersionNumber mod 100]);
end;

function TConfigurationFormat.FormatHeader(const AApplicationTitle: string;
  AVersionNumber: Integer): string;
begin
  Result := '[' + AApplicationTitle + ' ' + VersionText(AVersionNumber) + ']';
end;

function TConfigurationFormat.AcceptsHeader(const AHeader: string; ACurrentVersion: Integer): Boolean;
var
  LVersion: Integer;
begin
  // a file written by the next build of the engine is read too
  for LVersion := ACurrentVersion + 1 downto CONFIGURATION_OLDEST_VERSION do
    if Pos(VersionText(LVersion), AHeader) > 0 then
      Exit(True);
  Result := False;
end;

function TConfigurationFormat.Parse(const ALines: TArray<string>): IConfigurationDocument;
begin
  Result := TConfigurationDocument.Create(ALines);
end;

function TConfigurationFormat.CreateWriter(const AHeader: string): IConfigurationWriter;
begin
  Result := TConfigurationWriter.Create(AHeader);
end;

function TConfigurationFormat.ParseInteger(const AText: string): Integer;
begin
  Result := TConfigurationValues.ParseInteger(AText);
end;

function TConfigurationFormat.ParseBoolean(const AText: string): Boolean;
begin
  Result := TConfigurationValues.ParseBoolean(AText);
end;

function TConfigurationFormat.FormatInteger(AValue: Integer): string;
begin
  Result := TConfigurationValues.FormatInteger(AValue);
end;

function TConfigurationFormat.FormatBoolean(AValue: Boolean): string;
begin
  Result := TConfigurationValues.FormatBoolean(AValue);
end;

end.
