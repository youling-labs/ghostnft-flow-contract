import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import WeaponItems from "../../contracts/WeaponItems.cdc"
import MetadataViews from "../../contracts/MetadataViews.cdc"

// This transaction configures an account to hold Kitty Items.

transaction {
    prepare(signer: AuthAccount) {
        // if the account doesn't already have a collection
        if signer.borrow<&WeaponItems.Collection>(from: WeaponItems.CollectionStoragePath) == nil {

            // create a new empty collection
            let collection <- WeaponItems.createEmptyCollection()
            
            // save it to the account
            signer.save(<-collection, to: WeaponItems.CollectionStoragePath)

            // create a public capability for the collection
            signer.link<&WeaponItems.Collection{NonFungibleToken.CollectionPublic, WeaponItems.WeaponItemsCollectionPublic, MetadataViews.ResolverCollection}>(WeaponItems.CollectionPublicPath, target: WeaponItems.CollectionStoragePath)
        }
    }
}
