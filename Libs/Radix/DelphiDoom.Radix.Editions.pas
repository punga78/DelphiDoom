{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixEditions                                  }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of radixversioninfo and RX_*FromCrc32 of radix_version.pas: which      }
{  release of the game a RADIX.DAT is, told by the CRC-32 of the whole file    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Editions;

interface

type
  /// <summary>The releases of RADIX.DAT that Rad-X knew, in the order of its table</summary>
  TRadixEdition = (
    reV10Shareware, reV10Registered,
    reV11Shareware, reV11Registered,
    reV20Shareware, reV20Registered,
    reUnknown
  );

  /// <summary>The table of the known files RADIX.DAT</summary>
  TRadixEditions = class
  public
    /// <summary>The release with that CRC-32 of the file; reUnknown when the table does not have it</summary>
    class function FromCrc32(ACrc: Cardinal): TRadixEdition; static;
    /// <summary>The CRC-32 of the file of a release; 0 for reUnknown</summary>
    class function Crc32Of(AEdition: TRadixEdition): Cardinal; static;
    /// <summary>True for the three registered releases (three episodes); false for the shareware and the unknown</summary>
    class function IsRegistered(AEdition: TRadixEdition): Boolean; static;
    /// <summary>False only for reUnknown</summary>
    class function IsKnown(AEdition: TRadixEdition): Boolean; static;
    /// <summary>"Radix v2.0 Remix Shareware"...; "Game mode indeterminate" for reUnknown, as the old code printed</summary>
    class function Title(AEdition: TRadixEdition): string; static;
  end;

implementation

type
  TEditionInfo = record
    Crc: Cardinal;
    Registered: Boolean;
    Title: string;
  end;

const
  SUnknownTitle = 'Game mode indeterminate';

  Editions: array[reV10Shareware..reV20Registered] of TEditionInfo = (
    (Crc: $745CF789; Registered: False; Title: 'Radix v1.0 Shareware'),
    (Crc: $F7D737A5; Registered: True; Title: 'Radix v1.0 Registered'),
    (Crc: $681B6BE8; Registered: False; Title: 'Radix v1.1 Shareware'),
    (Crc: $4947EB68; Registered: True; Title: 'Radix v1.1 Registered'),
    (Crc: $593759BE; Registered: False; Title: 'Radix v2.0 Remix Shareware'),
    (Crc: $67F5000C; Registered: True; Title: 'Radix v2.0 Remix Registered')
  );

{ TRadixEditions }

class function TRadixEditions.FromCrc32(ACrc: Cardinal): TRadixEdition;
var
  LEdition: TRadixEdition;
begin
  for LEdition := Low(Editions) to High(Editions) do
    if Editions[LEdition].Crc = ACrc then
      Exit(LEdition);
  Result := reUnknown;
end;

class function TRadixEditions.Crc32Of(AEdition: TRadixEdition): Cardinal;
begin
  if AEdition = reUnknown then
    Result := 0
  else
    Result := Editions[AEdition].Crc;
end;

class function TRadixEditions.IsRegistered(AEdition: TRadixEdition): Boolean;
begin
  Result := (AEdition <> reUnknown) and Editions[AEdition].Registered;
end;

class function TRadixEditions.IsKnown(AEdition: TRadixEdition): Boolean;
begin
  Result := AEdition <> reUnknown;
end;

class function TRadixEditions.Title(AEdition: TRadixEdition): string;
begin
  if AEdition = reUnknown then
    Result := SUnknownTitle
  else
    Result := Editions[AEdition].Title;
end;

end.
