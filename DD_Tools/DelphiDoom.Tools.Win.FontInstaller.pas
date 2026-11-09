{******************************************************************************}
{                                                                              }
{  DD_Tools: the font files of the user                                         }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.Win.FontInstaller;

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.FontEditor.Intf;

type
  /// <summary>
  ///   IFontInstaller with AddFontResourceEx and FR_PRIVATE: the font is there for this program only and goes away
  ///   when the program ends, or when it is asked to give the fonts back (RemoveFontResourceEx)
  /// </summary>
  TWindowsFontInstaller = class(TInterfacedObject, IFontInstaller)
  strict private
    FFiles: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    function Install(const AFileName: string): Boolean;
    procedure UninstallAll;
  end;

implementation

uses
  Winapi.Windows;

{ TWindowsFontInstaller }

constructor TWindowsFontInstaller.Create;
begin
  inherited Create;
  FFiles := TStringList.Create;
end;

destructor TWindowsFontInstaller.Destroy;
begin
  UninstallAll;
  FFiles.Free;
  inherited Destroy;
end;

function TWindowsFontInstaller.Install(const AFileName: string): Boolean;
begin
  Result := AddFontResourceEx(PChar(AFileName), FR_PRIVATE, nil) > 0;
  if Result then
    FFiles.Add(AFileName);
end;

procedure TWindowsFontInstaller.UninstallAll;
var
  LFile: string;
begin
  for LFile in FFiles do
    RemoveFontResourceEx(PChar(LFile), FR_PRIVATE, nil);
  FFiles.Clear;
end;

end.
