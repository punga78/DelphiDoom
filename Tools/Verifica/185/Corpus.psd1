@{
  # Il corpus di demo della parita' (issue #185, fase 0).
  #   Demo = una demo interna del WAD (si riproduce con -timedemo <nome>)
  #   Auto = una demo registrata dal motore con il pilota automatico (Registra-Demo.ps1):
  #          Warp (argomenti di -warp), Skill, Seed e Tics del pilota (-autodemo), Extra (altre opzioni);
  #          il file sta in Tests\Data\Parity\<Gioco>\<Nome>.lmp (solo ticcmd: nessun dato del gioco)
  Entries = @(
    # ---- Doom ------------------------------------------------------------------------------------------------
    @{ Game = 'Doom'; Name = 'd1_demo1'; Iwad = 'DOOM1.WAD'; Demo = 'demo1' }
    @{ Game = 'Doom'; Name = 'd1_demo2'; Iwad = 'DOOM1.WAD'; Demo = 'demo2' }
    @{ Game = 'Doom'; Name = 'd1_demo3'; Iwad = 'DOOM1.WAD'; Demo = 'demo3' }
    @{ Game = 'Doom'; Name = 'f2_demo1'; Iwad = 'FREEDOOM2.WAD'; Demo = 'demo1' }
    @{ Game = 'Doom'; Name = 'f2_demo2'; Iwad = 'FREEDOOM2.WAD'; Demo = 'demo2' }
    @{ Game = 'Doom'; Name = 'f2_demo3'; Iwad = 'FREEDOOM2.WAD'; Demo = 'demo3' }
    @{ Game = 'Doom'; Name = 'f2_demo4'; Iwad = 'FREEDOOM2.WAD'; Demo = 'demo4' }
    @{ Game = 'Doom'; Name = 'a_d1_e1m1'; Iwad = 'DOOM1.WAD'; Auto = @{ Warp = '1 1'; Skill = 3; Seed = 11; Tics = 3000 } }
    @{ Game = 'Doom'; Name = 'a_d1_e1m2'; Iwad = 'DOOM1.WAD'; Auto = @{ Warp = '1 2'; Skill = 1; Seed = 12; Tics = 3000 } }
    @{ Game = 'Doom'; Name = 'a_d1_e1m3'; Iwad = 'DOOM1.WAD'; Auto = @{ Warp = '1 3'; Skill = 2; Seed = 13; Tics = 3000 } }
    @{ Game = 'Doom'; Name = 'a_d1_e1m4'; Iwad = 'DOOM1.WAD'; Auto = @{ Warp = '1 4'; Skill = 3; Seed = 14; Tics = 3000 } }
    @{ Game = 'Doom'; Name = 'a_d1_e1m5'; Iwad = 'DOOM1.WAD'; Auto = @{ Warp = '1 5'; Skill = 3; Seed = 15; Tics = 3000 } }
    @{ Game = 'Doom'; Name = 'a_d1_e1m6'; Iwad = 'DOOM1.WAD'; Auto = @{ Warp = '1 6'; Skill = 1; Seed = 16; Tics = 3000 } }
    @{ Game = 'Doom'; Name = 'a_d1_e1m8'; Iwad = 'DOOM1.WAD'; Auto = @{ Warp = '1 8'; Skill = 1; Seed = 18; Tics = 3000 } }
    @{ Game = 'Doom'; Name = 'a_f2_map01'; Iwad = 'FREEDOOM2.WAD'; Auto = @{ Warp = '1'; Skill = 3; Seed = 21; Tics = 3000 } }
    @{ Game = 'Doom'; Name = 'a_f2_map02'; Iwad = 'FREEDOOM2.WAD'; Auto = @{ Warp = '2'; Skill = 1; Seed = 22; Tics = 3000 } }
    @{ Game = 'Doom'; Name = 'a_f2_map05'; Iwad = 'FREEDOOM2.WAD'; Auto = @{ Warp = '5'; Skill = 3; Seed = 25; Tics = 3000 } }
    @{ Game = 'Doom'; Name = 'a_f2_map07'; Iwad = 'FREEDOOM2.WAD'; Auto = @{ Warp = '7'; Skill = 3; Seed = 27; Tics = 3000 } }
    @{ Game = 'Doom'; Name = 'a_f2_map10'; Iwad = 'FREEDOOM2.WAD'; Auto = @{ Warp = '10'; Skill = 1; Seed = 30; Tics = 3000 } }
    @{ Game = 'Doom'; Name = 'a_f2_map15'; Iwad = 'FREEDOOM2.WAD'; Auto = @{ Warp = '15'; Skill = 3; Seed = 35; Tics = 3000 } }
    @{ Game = 'Doom'; Name = 'a_f2_map30'; Iwad = 'FREEDOOM2.WAD'; Auto = @{ Warp = '30'; Skill = 3; Seed = 40; Tics = 3000 } }
    # ---- Heretic ---------------------------------------------------------------------------------------------
    @{ Game = 'Heretic'; Name = 'a_h_e1m1'; Iwad = 'HERETIC1.WAD'; Auto = @{ Warp = '1 1'; Skill = 3; Seed = 51; Tics = 3000 } }
    @{ Game = 'Heretic'; Name = 'a_h_e1m2'; Iwad = 'HERETIC1.WAD'; Auto = @{ Warp = '1 2'; Skill = 1; Seed = 52; Tics = 3000 } }
    @{ Game = 'Heretic'; Name = 'a_h_e1m3'; Iwad = 'HERETIC1.WAD'; Auto = @{ Warp = '1 3'; Skill = 3; Seed = 53; Tics = 3000 } }
    @{ Game = 'Heretic'; Name = 'a_h_e1m4'; Iwad = 'HERETIC1.WAD'; Auto = @{ Warp = '1 4'; Skill = 3; Seed = 54; Tics = 3000 } }
    @{ Game = 'Heretic'; Name = 'a_h_e1m5'; Iwad = 'HERETIC1.WAD'; Auto = @{ Warp = '1 5'; Skill = 1; Seed = 55; Tics = 3000 } }
    @{ Game = 'Heretic'; Name = 'a_h_e1m7'; Iwad = 'HERETIC1.WAD'; Auto = @{ Warp = '1 7'; Skill = 3; Seed = 57; Tics = 3000 } }
    @{ Game = 'Heretic'; Name = 'a_h_e1m8'; Iwad = 'HERETIC1.WAD'; Auto = @{ Warp = '1 8'; Skill = 3; Seed = 58; Tics = 3000 } }
    @{ Game = 'Heretic'; Name = 'a_h_e1m6'; Iwad = 'HERETIC1.WAD'; Auto = @{ Warp = '1 6'; Skill = 1; Seed = 59; Tics = 3000 } }
    @{ Game = 'Heretic'; Name = 'a_h_e1m9'; Iwad = 'HERETIC1.WAD'; Auto = @{ Warp = '1 9'; Skill = 3; Seed = 60; Tics = 3000 } }
    # ---- Hexen -----------------------------------------------------------------------------------------------
    @{ Game = 'Hexen'; Name = 'a_x_map01_f'; Iwad = 'HEXEN.WAD'; Auto = @{ Warp = '1'; Skill = 3; Seed = 61; Tics = 3000; Extra = '-class 0' } }
    @{ Game = 'Hexen'; Name = 'a_x_map01_c'; Iwad = 'HEXEN.WAD'; Auto = @{ Warp = '1'; Skill = 1; Seed = 62; Tics = 3000; Extra = '-class 1' } }
    @{ Game = 'Hexen'; Name = 'a_x_map02_m'; Iwad = 'HEXEN.WAD'; Auto = @{ Warp = '2'; Skill = 3; Seed = 63; Tics = 3000; Extra = '-class 2' } }
    @{ Game = 'Hexen'; Name = 'a_x_map03_f'; Iwad = 'HEXEN.WAD'; Auto = @{ Warp = '3'; Skill = 1; Seed = 68; Tics = 2500; Extra = '-class 0' } }
    @{ Game = 'Hexen'; Name = 'a_x_map04_c'; Iwad = 'HEXEN.WAD'; Auto = @{ Warp = '4'; Skill = 1; Seed = 71; Tics = 2500; Extra = '-class 1' } }
    @{ Game = 'Hexen'; Name = 'a_x_map01_m'; Iwad = 'HEXEN.WAD'; Auto = @{ Warp = '1'; Skill = 1; Seed = 81; Tics = 3000; Extra = '-class 2' } }
    @{ Game = 'Hexen'; Name = 'a_x_map02_f'; Iwad = 'HEXEN.WAD'; Auto = @{ Warp = '2'; Skill = 1; Seed = 82; Tics = 3000; Extra = '-class 0' } }
    @{ Game = 'Hexen'; Name = 'a_x_map03_c'; Iwad = 'HEXEN.WAD'; Auto = @{ Warp = '3'; Skill = 1; Seed = 83; Tics = 3000; Extra = '-class 1' } }
    # ---- Strife ----------------------------------------------------------------------------------------------
    @{ Game = 'Strife'; Name = 'a_s_map32'; Iwad = 'STRIFE0.WAD'; Auto = @{ Warp = '32'; Skill = 3; Seed = 71; Tics = 3000 } }
    @{ Game = 'Strife'; Name = 'a_s_map33'; Iwad = 'STRIFE0.WAD'; Auto = @{ Warp = '33'; Skill = 1; Seed = 72; Tics = 2500 } }
    @{ Game = 'Strife'; Name = 'a_s_map32b'; Iwad = 'STRIFE0.WAD'; Auto = @{ Warp = '32'; Skill = 1; Seed = 75; Tics = 3000 } }
    @{ Game = 'Strife'; Name = 'a_s_map32c'; Iwad = 'STRIFE0.WAD'; Auto = @{ Warp = '32'; Skill = 2; Seed = 85; Tics = 3000 } }
    @{ Game = 'Strife'; Name = 'a_s_map33b'; Iwad = 'STRIFE0.WAD'; Auto = @{ Warp = '33'; Skill = 1; Seed = 86; Tics = 3000 } }
    @{ Game = 'Strife'; Name = 'a_s_map34'; Iwad = 'STRIFE0.WAD'; Auto = @{ Warp = '34'; Skill = 1; Seed = 76; Tics = 3000 } }
  )
}
