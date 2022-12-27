// This script reads the balance field of an account's FlowToken Balance

import FungibleToken from "../../contracts/FungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
// import FungibleToken from 0x9a0766d93b6608b7
// import GnftToken from 0xbf69452890a74d8f

pub fun main(account: Address): UFix64 {
    let vaultRef = getAccount(account)
      .getCapability(/public/fusdBalance)
      .borrow<&FUSD.Vault{FungibleToken.Balance}>()
      ?? panic("Could not borrow Balance capability")

    return vaultRef.balance
}
