{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the data of the 40 cars of Speed Haste         }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the carinfo table of speed_cars.pas (GLSpeed). The table is         }
{  generated from the original text, one row per car.                          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.CarData;

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Racing.Types;

const
  /// <summary>The 20 formula cars followed by the 20 stock cars, in the order of the original table</summary>
  RACING_CAR_DATA: array[0..RACING_CAR_COUNT - 1] of TRacingCarInfo = (
    (
      OriginalTexture1: 'f_1_4';
      Texture1: '';
      OriginalTexture2: 'f_1_5';
      Texture2: '';
      Number: 27;
      MaxSpeed: 305 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N0A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'PHOENIX ENGINE';
    ),
    (
      OriginalTexture1: 'f_1_4';
      Texture1: 'f_1_4_01_03.png';
      OriginalTexture2: 'f_1_5';
      Texture2: '';
      Number: 3;
      MaxSpeed: 310 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N0A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'SPEED-X';
    ),
    (
      OriginalTexture1: 'f_1_4';
      Texture1: 'f_1_4_02_56.png';
      OriginalTexture2: 'f_1_5';
      Texture2: '';
      Number: 56;
      MaxSpeed: 315 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N0A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'BAM BAM';
    ),
    (
      OriginalTexture1: 'f_1_4';
      Texture1: 'f_1_4_03_30.png';
      OriginalTexture2: 'f_1_5';
      Texture2: '';
      Number: 30;
      MaxSpeed: 320 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N0A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'SNAP';
    ),
    (
      OriginalTexture1: 'f_2_4';
      Texture1: '';
      OriginalTexture2: 'f_2_5';
      Texture2: '';
      Number: 1;
      MaxSpeed: 325 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N1A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'BLUE STEEL';
    ),
    (
      OriginalTexture1: 'f_2_4';
      Texture1: 'f_2_4_01_33.png';
      OriginalTexture2: 'f_2_5';
      Texture2: '';
      Number: 33;
      MaxSpeed: 330 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N1A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'SONIC';
    ),
    (
      OriginalTexture1: 'f_2_4';
      Texture1: 'f_2_4_02_12.png';
      OriginalTexture2: 'f_2_5';
      Texture2: '';
      Number: 12;
      MaxSpeed: 305 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N1A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'DORY';
    ),
    (
      OriginalTexture1: 'f_3_4';
      Texture1: '';
      OriginalTexture2: 'f_3_5';
      Texture2: '';
      Number: 4;
      MaxSpeed: 310 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N2A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'DREAM MAKER';
    ),
    (
      OriginalTexture1: 'f_3_4';
      Texture1: 'f_3_4_01_09.png';
      OriginalTexture2: 'f_3_5';
      Texture2: '';
      Number: 9;
      MaxSpeed: 315 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N2A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'DARK KNIGHT';
    ),
    (
      OriginalTexture1: 'f_3_4';
      Texture1: 'f_3_4_02_22.png';
      OriginalTexture2: 'f_3_5';
      Texture2: '';
      Number: 22;
      MaxSpeed: 320 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N2A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'PANTHER';
    ),
    (
      OriginalTexture1: 'f_3_4';
      Texture1: 'f_3_4_03_62.png';
      OriginalTexture2: 'f_3_5';
      Texture2: '';
      Number: 62;
      MaxSpeed: 325 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N2A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'ZORRO';
    ),
    (
      OriginalTexture1: 'f_4_4';
      Texture1: '';
      OriginalTexture2: 'f_4_5';
      Texture2: '';
      Number: 7;
      MaxSpeed: 330 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N3A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'FROZEN SKY';
    ),
    (
      OriginalTexture1: 'f_4_4';
      Texture1: 'f_4_4_01_18.png';
      OriginalTexture2: 'f_4_5';
      Texture2: '';
      Number: 18;
      MaxSpeed: 305 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N3A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'DIABLO';
    ),
    (
      OriginalTexture1: 'f_4_4';
      Texture1: 'f_4_4_02_54.png';
      OriginalTexture2: 'f_4_5';
      Texture2: '';
      Number: 54;
      MaxSpeed: 310 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N3A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'HERCULES';
    ),
    (
      OriginalTexture1: 'f_4_4';
      Texture1: 'f_4_4_03_88.png';
      OriginalTexture2: 'f_4_5';
      Texture2: '';
      Number: 88;
      MaxSpeed: 315 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N3A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'VAPOR';
    ),
    (
      OriginalTexture1: 'f_5_4';
      Texture1: '';
      OriginalTexture2: 'f_5_5';
      Texture2: '';
      Number: 6;
      MaxSpeed: 320 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N4A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'SPEED DEMON';
    ),
    (
      OriginalTexture1: 'f_5_4';
      Texture1: 'f_5_4_01_23.png';
      OriginalTexture2: 'f_5_5';
      Texture2: '';
      Number: 23;
      MaxSpeed: 325 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N4A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'BIG MAN';
    ),
    (
      OriginalTexture1: 'f_5_4';
      Texture1: 'f_5_4_02_45.png';
      OriginalTexture2: 'f_5_5';
      Texture2: '';
      Number: 45;
      MaxSpeed: 330 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N4A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'GREAT ZEUS';
    ),
    (
      OriginalTexture1: 'f_6_4';
      Texture1: '';
      OriginalTexture2: 'f_6_5';
      Texture2: '';
      Number: 73;
      MaxSpeed: 305 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N5A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'BLACK BULLET';
    ),
    (
      OriginalTexture1: 'f_6_4';
      Texture1: 'f_6_4_01_99.png';
      OriginalTexture2: 'f_6_5';
      Texture2: '';
      Number: 99;
      MaxSpeed: 310 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -50 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 8 * 1024;
      BaseDeceleration: 64 * 1024;
      TurnSpeed: 448 * FIXED_ONE;
      Model3d: 'CAR0N5A.I3D';
      CarType: TRacingCarType.Formula;
      MaxDrift: 20;
      Name: 'ICE CUBE';
    ),
    (
      OriginalTexture1: 'd_1_5';
      Texture1: '';
      OriginalTexture2: '';
      Texture2: '';
      Number: 15;
      MaxSpeed: 245 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N0A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'ROAD STAR';
    ),
    (
      OriginalTexture1: 'd_1_5';
      Texture1: 'd_1_5_01_17.png';
      OriginalTexture2: '';
      Texture2: '';
      Number: 17;
      MaxSpeed: 250 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N0A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'LEMON STAR';
    ),
    (
      OriginalTexture1: 'd_1_5';
      Texture1: 'd_1_5_02_19.png';
      OriginalTexture2: '';
      Texture2: '';
      Number: 19;
      MaxSpeed: 255 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N0A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'BUMBLE BEE';
    ),
    (
      OriginalTexture1: 'd_1_5';
      Texture1: 'd_1_5_03_04.png';
      OriginalTexture2: '';
      Texture2: '';
      Number: 4;
      MaxSpeed: 260 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N0A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'SUNSHINE';
    ),
    (
      OriginalTexture1: 'd_2_5';
      Texture1: '';
      OriginalTexture2: '';
      Texture2: '';
      Number: 77;
      MaxSpeed: 245 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N1A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'THE FLAME';
    ),
    (
      OriginalTexture1: 'd_2_5';
      Texture1: 'd_2_5_01_94.png';
      OriginalTexture2: '';
      Texture2: '';
      Number: 94;
      MaxSpeed: 250 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N1A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'ROAD FROG';
    ),
    (
      OriginalTexture1: 'd_2_5';
      Texture1: 'd_2_5_02_87.png';
      OriginalTexture2: '';
      Texture2: '';
      Number: 87;
      MaxSpeed: 255 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N1A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'THE HULK';
    ),
    (
      OriginalTexture1: 'd_3_5';
      Texture1: '';
      OriginalTexture2: '';
      Texture2: '';
      Number: 6;
      MaxSpeed: 260 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N2A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'SKEIN';
    ),
    (
      OriginalTexture1: 'd_3_5';
      Texture1: 'd_3_5_01_83.png';
      OriginalTexture2: '';
      Texture2: '';
      Number: 83;
      MaxSpeed: 245 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N2A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'ROAD FAME';
    ),
    (
      OriginalTexture1: 'd_3_5';
      Texture1: 'd_3_5_02_07.png';
      OriginalTexture2: '';
      Texture2: '';
      Number: 7;
      MaxSpeed: 250 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N2A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'BIG BIRD';
    ),
    (
      OriginalTexture1: 'd_3_5';
      Texture1: 'd_3_5_03_32.png';
      OriginalTexture2: '';
      Texture2: '';
      Number: 32;
      MaxSpeed: 255 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N2A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'TORCH';
    ),
    (
      OriginalTexture1: 'd_4_5';
      Texture1: '';
      OriginalTexture2: '';
      Texture2: '';
      Number: 43;
      MaxSpeed: 260 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N3A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'BLACK FURY';
    ),
    (
      OriginalTexture1: 'd_4_5';
      Texture1: 'd_4_5_01_48.png';
      OriginalTexture2: '';
      Texture2: '';
      Number: 48;
      MaxSpeed: 245 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N3A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'BURNER';
    ),
    (
      OriginalTexture1: 'd_4_5';
      Texture1: 'd_4_5_02_78.png';
      OriginalTexture2: '';
      Texture2: '';
      Number: 78;
      MaxSpeed: 250 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N3A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'SHADOW';
    ),
    (
      OriginalTexture1: 'd_5_5';
      Texture1: '';
      OriginalTexture2: '';
      Texture2: '';
      Number: 18;
      MaxSpeed: 255 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N4A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'LUCKY HORSE';
    ),
    (
      OriginalTexture1: 'd_5_5';
      Texture1: 'd_5_5_01_09.png';
      OriginalTexture2: '';
      Texture2: '';
      Number: 9;
      MaxSpeed: 260 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N4A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'DIAMOND';
    ),
    (
      OriginalTexture1: 'd_5_5';
      Texture1: 'd_5_5_02_11.png';
      OriginalTexture2: '';
      Texture2: '';
      Number: 11;
      MaxSpeed: 245 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N4A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'POLAR BEAR';
    ),
    (
      OriginalTexture1: 'd_6_5';
      Texture1: '';
      OriginalTexture2: '';
      Texture2: '';
      Number: 23;
      MaxSpeed: 250 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N5A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'THE MIRACLE';
    ),
    (
      OriginalTexture1: 'd_6_5';
      Texture1: 'd_6_5_01_54.png';
      OriginalTexture2: '';
      Texture2: '';
      Number: 54;
      MaxSpeed: 255 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N5A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'BLUEBERRY';
    ),
    (
      OriginalTexture1: 'd_6_5';
      Texture1: 'd_6_5_02_92.png';
      OriginalTexture2: '';
      Texture2: '';
      Number: 92;
      MaxSpeed: 260 * RACING_KMH_TO_FIXED;
      MaxReverseSpeed: -45 * RACING_KMH_TO_FIXED;
      BaseAcceleration: 6 * 1024;
      BaseDeceleration: 48 * 1024;
      TurnSpeed: 424 * FIXED_ONE;
      Model3d: 'CAR1N5A.I3D';
      CarType: TRacingCarType.Stock;
      MaxDrift: 45;
      Name: 'BOOM BOOM';
    )
  );

implementation

end.
