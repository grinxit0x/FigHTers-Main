// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct Fighter {
    uint256 id;
    string name;
    uint32 level;
    uint32 cooldownTime;
    BattleStats battleStats;
}

struct BattleStats {
    uint16 attack;
    uint16 defense;
    uint16 magicDefense;
    uint16 strenght;
    uint16 speed;
    uint16 endurance; //aguante
    uint16 spirit;
    uint16 winCount;
    uint16 lossCount;
}
