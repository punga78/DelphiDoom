{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - what the readers of the blocks have in common}
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Reader.Base;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Dehacked.Types, DelphiDoom.Dehacked.Section,
  DelphiDoom.Dehacked.Intf;

type
  /// <summary>The words, the log and the section: the readers of the blocks write the rest</summary>
  TDehackedReaderBase = class(TInterfacedObject, IDehackedSectionReader)
  private
    FKeywords: TArray<string>;
    FLog: ILog;
  protected
    procedure Warn(const AFormat: string; const AArguments: array of const);
    /// <summary>The section of the line that the source gave last</summary>
    function CreateSection(AKind: TDehackedSectionKind; const AKeyword, ATitle: string;
      const ASource: IDehackedLineSource): TDehackedSection;
  public
    /// <param name="ALog">May be nil</param>
    constructor Create(const AKeywords: TArray<string>; const ALog: ILog);
    function Keywords: TArray<string>;
    function Read(const AKeyword, ARest: string;
      const ASource: IDehackedLineSource): TDehackedSection; virtual; abstract;
  end;

implementation

uses
  System.SysUtils;

{ TDehackedReaderBase }

constructor TDehackedReaderBase.Create(const AKeywords: TArray<string>; const ALog: ILog);
begin
  inherited Create;
  FKeywords := AKeywords;
  FLog := ALog;
end;

function TDehackedReaderBase.Keywords: TArray<string>;
begin
  Result := FKeywords;
end;

procedure TDehackedReaderBase.Warn(const AFormat: string; const AArguments: array of const);
begin
  if Assigned(FLog) then
    FLog.Warning(Format(AFormat, AArguments));
end;

function TDehackedReaderBase.CreateSection(AKind: TDehackedSectionKind; const AKeyword,
  ATitle: string; const ASource: IDehackedLineSource): TDehackedSection;
begin
  Result := TDehackedSection.Create(AKind, ASource.LineNumber, AKeyword, ATitle);
end;

end.
