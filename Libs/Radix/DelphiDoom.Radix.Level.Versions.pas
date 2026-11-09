{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixLevelVersions                             }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of Radix_v10_levelCRC, Radix_v11_levelCRC and Radix_v2_levelCRC of     }
{  radix_level.pas: which version of the game a level comes from               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Level.Versions;

interface

type
  TRadixLevelVersion = (rlvUnknown, rlvV10, rlvV11, rlvV2);

  /// <summary>The checksum of every level of the versions of the game that the translation knows</summary>
  TRadixLevelVersions = class
  public
    /// <summary>The version a level is of; the 2.0 is checked first, then the 1.1, then the 1.0</summary>
    class function Identify(const AName: string; ACrc: Cardinal): TRadixLevelVersion; static;
  end;

implementation

uses
  System.SysUtils;

type
  TLevelChecksums = record
    Name: string;
    V10: Cardinal;
    V11: Cardinal;
    V2: Cardinal;
  end;

const
  Checksums: array[0..26] of TLevelChecksums = (
    (Name: 'E1M1'; V10: $508E903B; V11: $9332AD1B; V2: $1E621ABE),
    (Name: 'E1M2'; V10: $6456995C; V11: $BC330015; V2: $59B387AD),
    (Name: 'E1M3'; V10: $4FCE4AC0; V11: $4FCE4AC0; V2: $D29684C0),
    (Name: 'E1M4'; V10: $D341760C; V11: $D341760C; V2: $D341760C),
    (Name: 'E1M5'; V10: $EE73818A; V11: $EE73818A; V2: $6BAF74A2),
    (Name: 'E1M6'; V10: $827D20E4; V11: $827D20E4; V2: $827D20E4),
    (Name: 'E1M7'; V10: $D30FD83B; V11: $D30FD83B; V2: $D30FD83B),
    (Name: 'E1M8'; V10: $66256496; V11: $66256496; V2: $5B4C0E64),
    (Name: 'E1M9'; V10: $CB48D934; V11: $CB48D934; V2: $CB48D934),
    (Name: 'E2M1'; V10: $5351174C; V11: $5351174C; V2: $5351174C),
    (Name: 'E2M2'; V10: $A89AA971; V11: $A89AA971; V2: $A89AA971),
    (Name: 'E2M3'; V10: $C48C5B0E; V11: $5677AFB0; V2: $76FC4E82),
    (Name: 'E2M4'; V10: $7CD6BAA6; V11: $469F7BB3; V2: $3E7EFCC7),
    (Name: 'E2M5'; V10: $39D60BA5; V11: $39D60BA5; V2: $39D60BA5),
    (Name: 'E2M6'; V10: $A01810C0; V11: $A01810C0; V2: $A01810C0),
    (Name: 'E2M7'; V10: $3BD5E170; V11: $3BD5E170; V2: $3BD5E170),
    (Name: 'E2M8'; V10: $91FF1A54; V11: $91FF1A54; V2: $91FF1A54),
    (Name: 'E2M9'; V10: $0A65F0FA; V11: $0A65F0FA; V2: $D014181F),
    (Name: 'E3M1'; V10: $0F790FDC; V11: $0F790FDC; V2: $0F790FDC),
    (Name: 'E3M2'; V10: $51B675E4; V11: $51B675E4; V2: $51B675E4),
    (Name: 'E3M3'; V10: $0D288E2B; V11: $0D288E2B; V2: $0D288E2B),
    (Name: 'E3M4'; V10: $86B0E033; V11: $86B0E033; V2: $86B0E033),
    (Name: 'E3M5'; V10: $F948451E; V11: $F948451E; V2: $714EF22B),
    (Name: 'E3M6'; V10: $3020CCF0; V11: $3020CCF0; V2: $5B73AC44),
    (Name: 'E3M7'; V10: $18F8424C; V11: $18F8424C; V2: $18F8424C),
    (Name: 'E3M8'; V10: $100FEEFD; V11: $100FEEFD; V2: $8FE243CD),
    (Name: 'E3M9'; V10: $6EDAD08A; V11: $6EDAD08A; V2: $6EDAD08A)
  );

{ TRadixLevelVersions }

class function TRadixLevelVersions.Identify(const AName: string; ACrc: Cardinal): TRadixLevelVersion;
var
  LIndex: Integer;
begin
  Result := rlvUnknown;
  for LIndex := 0 to High(Checksums) do
    if Checksums[LIndex].Name = AName then
    begin
      if Checksums[LIndex].V2 = ACrc then
        Result := rlvV2
      else if Checksums[LIndex].V11 = ACrc then
        Result := rlvV11
      else if Checksums[LIndex].V10 = ACrc then
        Result := rlvV10;
      Exit;
    end;
end;

end.
