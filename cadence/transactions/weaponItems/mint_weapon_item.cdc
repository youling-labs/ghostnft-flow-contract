import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import WeaponItems from "../../contracts/WeaponItems.cdc"

// This transction uses the NFTMinter resource to mint a new NFT.
//
// It must be run with the account that has the minter resource
// stored at path /storage/NFTMinter.


 

transaction(recipient: Address) {

    let minter: @WeaponItems7.NFTMinter

    prepare(signer: AuthAccount) {
      if signer.borrow<&WeaponItems7.Collection>(from: WeaponItems7.CollectionStoragePath) == nil {
        let collection <- WeaponItems7.createEmptyCollection()
        signer.save(<-collection, to: WeaponItems7.CollectionStoragePath)
        signer.link<&WeaponItems7.Collection{NonFungibleToken.CollectionPublic, WeaponItems7.WeaponItems7CollectionPublic, MetadataViews.ResolverCollection}>(WeaponItems7.CollectionPublicPath, target: WeaponItems7.CollectionStoragePath)
      }
      self.minter <- WeaponItems7.getMinter()
    }

    execute {
      let recipient = getAccount(recipient)

      let receiver = recipient
          .getCapability(WeaponItems7.CollectionPublicPath)!
          .borrow<&{NonFungibleToken.CollectionPublic}>()
          ?? panic("Could not get receiver reference to the NFT Collection")

      self.minter.mintNFT(
          recipient: receiver,
          name: "weapon ".concat(WeaponItems7.totalSupply.toString()),
          attack: UInt8(unsafeRandom() % 100),
          defence: UInt8(unsafeRandom() % 100),
          url: "http://139.177.202.65:9876/view/w".concat(UInt8(unsafeRandom() % 5).toString()).concat(".png")
      )

      destroy self.minter
    }
}
