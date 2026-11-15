// a second set of item weights: a different bot (the same weights as goal_i.c, so that two bots can interbreed)
weight "item_armor_body" return 120;
weight "item_health" { switch(2) { case 80: return 90; default: return balance(30, 10, 60); } }
weight "weapon_rocketlauncher" return 600;
weight "item_quad" return 10;
weight "ammo_rockets" return 70;
weight "item_botroam" return 20;
