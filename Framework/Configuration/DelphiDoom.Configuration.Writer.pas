{******************************************************************************}
{                                                                              }
{  DelphiDoom: configuration library - the writer of the lines                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Configuration.Writer;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Configuration.Intf;

type
  /// <summary>The lines of a configuration file, in the order they were added</summary>
  TConfigurationWriter = class(TInterfacedObject, IConfigurationWriter)
  private
    FLines: TList<string>;
  public
    constructor Create(const AHeader: string);
    destructor Destroy; override;
    procedure AddGroup(const AName: string);
    procedure AddValue(const AName, AValue: string);
    function Lines: TArray<string>;
  end;

implementation

{ TConfigurationWriter }

constructor TConfigurationWriter.Create(const AHeader: string);
begin
  inherited Create;
  FLines := TList<string>.Create;
  FLines.Add(AHeader);
end;

destructor TConfigurationWriter.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

procedure TConfigurationWriter.AddGroup(const AName: string);
begin
  FLines.Add('');
  FLines.Add('[' + AName + ']');
end;

procedure TConfigurationWriter.AddValue(const AName, AValue: string);
begin
  FLines.Add(AName + '=' + AValue);
end;

function TConfigurationWriter.Lines: TArray<string>;
begin
  Result := FLines.ToArray;
end;

end.
