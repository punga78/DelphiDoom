{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the blocks that have no body                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Reader.Marker;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Dehacked.Types, DelphiDoom.Dehacked.Section,
  DelphiDoom.Dehacked.Intf, DelphiDoom.Dehacked.Reader.Base;

type
  /// <summary>
  ///   A block that is only its header: Cheat (the old parser did nothing with it and read its lines as
  ///   headers, as this one does) and SUBMITNEWSTATES (the states of the patch so far become original ones)
  /// </summary>
  TDehackedMarkerReader = class(TDehackedReaderBase)
  private
    FKind: TDehackedSectionKind;
  public
    constructor Create(const AKeywords: TArray<string>; const ALog: ILog; AKind: TDehackedSectionKind);
    function Read(const AKeyword, ARest: string;
      const ASource: IDehackedLineSource): TDehackedSection; override;
  end;

implementation

{ TDehackedMarkerReader }

constructor TDehackedMarkerReader.Create(const AKeywords: TArray<string>; const ALog: ILog;
  AKind: TDehackedSectionKind);
begin
  inherited Create(AKeywords, ALog);
  FKind := AKind;
end;

function TDehackedMarkerReader.Read(const AKeyword, ARest: string;
  const ASource: IDehackedLineSource): TDehackedSection;
begin
  Result := CreateSection(FKind, AKeyword, ARest, ASource);
end;

end.
