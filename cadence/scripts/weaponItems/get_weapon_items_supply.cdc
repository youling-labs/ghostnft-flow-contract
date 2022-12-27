import WeaponItems from "../../contracts/WeaponItems.cdc"

// This scripts returns the number of KittyItems currently in existence.

pub fun main(): UInt64 {    
    return WeaponItems.totalSupply
}
