import FungibleToken from "../../contracts/FungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import NFTRentalRegular from "../../contracts/NFTRentalRegular.cdc"

transaction(tokenId: UInt64, rentTokenType: String, feeAmount: UFix64) {
  let signer: AuthAccount
  var vaultRef: &FungibleToken.Vault?

  prepare(signer: AuthAccount) {
    self.signer = signer
    self.vaultRef = nil
    if(rentTokenType == "FLOW") {
      self.vaultRef = signer.borrow<&FungibleToken.Vault>(from: /storage/flowTokenVault) 
        ?? panic("Account has no Flow vault")
    } else if(rentTokenType == "FUSD") {
      self.vaultRef = signer.borrow<&FungibleToken.Vault>(from: /storage/fusdVault) 
        ?? panic("Account has no FUSD vault")
    } else {
      panic("Token not supported")
    }
  }

  execute {
    if(rentTokenType == "FLOW") {
      let vault <- self.vaultRef!.withdraw(amount: feeAmount)
      NFTRentalRegular.rentFrom(tokenId: tokenId, tenant: self.signer.address, rentTokenType: rentTokenType, feePayment: <- vault)
    } else if (rentTokenType == "FUSD") {
      let vault <- self.vaultRef!.withdraw(amount: feeAmount)
      NFTRentalRegular.rentFrom(tokenId: tokenId, tenant: self.signer.address, rentTokenType: rentTokenType, feePayment: <- vault)
    } else {
      panic("Token not supported")
    }
  }
}