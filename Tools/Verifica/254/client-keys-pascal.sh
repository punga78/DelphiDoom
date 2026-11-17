#!/bin/sh
# Issue #254, fase 2c: writes IdTech4/Q3Host/DelphiDoom.Q3Host.Client.KeyNames.pas from the T lines of keys.golden.txt
# (the keynames[] table of the real cl_keys.c with the numbers of the real keycodes.h): nothing is typed by hand.
#   client-keys-pascal.sh <repository root>
set -e
ROOT=${1:-.}
GOLDEN=$ROOT/Tests/Data/Q3Host/keys.golden.txt
OUT=$ROOT/IdTech4/Q3Host/DelphiDoom.Q3Host.Client.KeyNames.pas
COUNT=$(grep -c '^T ' "$GOLDEN")
{
  cat <<EOF
{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the key names (GENERATED)               }
{                                                                              }
{  keynames[] of cl_keys.c with the key numbers of keycodes.h, written by       }
{  Tools\\Verifica\\254\\client-keys-pascal.sh from keys.golden.txt. Based on the  }
{  Quake III Arena GPL Source Code (id Software), Copyright (C) 1999-2005 Id    }
{  Software, Inc.; available under the GNU General Public License, version 2    }
{  or (at your option) any later version.                                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Client.KeyNames;

interface

type
  TQ3KeyName = record
    Name: AnsiString;
    Number: Integer;
  end;

const
  Q3_KEY_NAME_COUNT = $COUNT;

  /// <summary>keynames[]: the names that are not a lowercase ascii character or a 0xnn sequence</summary>
  Q3_KEY_NAMES: array[0..Q3_KEY_NAME_COUNT - 1] of TQ3KeyName = (
EOF
  grep '^T ' "$GOLDEN" | tr -d '\r' | awk -v n="$COUNT" '{ printf "    (Name: '"'"'%s'"'"'; Number: %s)%s\n", $2, $3, (NR < n ? "," : "") }'
  cat <<EOF
  );

implementation

end.
EOF
} > "$OUT"
