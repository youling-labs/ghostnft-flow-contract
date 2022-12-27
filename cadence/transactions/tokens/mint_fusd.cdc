import FungibleToken from "../../contracts/FungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"

/// This transaction is what the minter Account uses to mint new tokens
/// They provide the recipient address and amount to mint, and the tokens
/// are transferred to the address after minting

transaction(recipient: Address, amount: UFix64) {

    /// Reference to the Example Token Admin Resource object
    // let tokenAdmin: &FUSD.Administrator
    let tokenAdmin: @FUSD.Administrator

    /// Reference to the Fungible Token Receiver of the recipient
    let tokenReceiver: &{FungibleToken.Receiver}

    /// The total supply of tokens before the burn
    let supplyBefore: UFix64

    prepare(signer: AuthAccount) {
        self.supplyBefore = FUSD.totalSupply

        // Borrow a reference to the admin object
        // self.tokenAdmin = signer.borrow<&FUSD.Administrator>(from: /storage/flowTokenAdmin1)
            // ?? panic("Signer is not the token admin")
        self.tokenAdmin <- FUSD.getAdmin()

        // Get the account of the recipient and borrow a reference to their receiver
        self.tokenReceiver = getAccount(recipient)
            .getCapability(/public/fusdReceiver)
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Unable to borrow receiver reference")
    }

    execute {

        // Create a minter and mint tokens
        let minter <- self.tokenAdmin.createNewMinter()
        let mintedVault <- minter.mintTokens(amount: amount)

        // Deposit them to the receiever
        self.tokenReceiver.deposit(from: <-mintedVault)

        destroy minter
        destroy self.tokenAdmin
    }

    post {
        FUSD.totalSupply == self.supplyBefore + amount: "The total supply must be increased by the amount"
    }
}