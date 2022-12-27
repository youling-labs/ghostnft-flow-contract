import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import WeaponItems from "../../contracts/WeaponItems.cdc"

// This script returns the size of an account's WeaponItems collection.

pub fun main(address: Address): Int {
    let account = getAccount(address)

    let collectionRef = account.getCapability(WeaponItems.CollectionPublicPath)!
        .borrow<&{NonFungibleToken.CollectionPublic}>()
        ?? panic("Could not borrow capability from public collection")
    
    return collectionRef.getIDs().length
}
