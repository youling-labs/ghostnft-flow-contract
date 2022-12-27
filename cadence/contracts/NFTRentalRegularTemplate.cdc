import FlowToken from 0x7e60df042a9c0868
import FUSD from 0xe223d8a629e49c68
import FungibleToken from 0x9a0766d93b6608b7
import NonFungibleToken from 0x631e88ae7f1d7c20
import MetadataViews from 0x631e88ae7f1d7c20
import GnftToken from 0xbf69452890a74d8f
import CONTRACT_NAME_PLACEHOLDER from CONTRACT_ACCOUNT_PLACEHOLDER
pub contract RENT_CONTRACT_NAME {

  // Events
  pub event ListForRent(tokenId: UInt64, lessor: Address, endTime: UFix64, rentPerDay: UFix64, rentTokenType: String)
  pub event CancelList(tokenId: UInt64, lessor: Address, rentPerDay: UFix64, rentTokenType: String)
  pub event RentFrom(tokenId: UInt64, tenant: Address, totalRent: UFix64, rentTokenType: String)
  pub event Claim(tokenId: UInt64, lessor: Address, tenant: Address, claimer: Address, totalRent: UFix64, rentTokenType: String)
  pub event FinishRent(tokenId: UInt64, lessor: Address, tenant: Address, totalRent: UFix64, rentTokenType: String)

  // Named Path
  pub let flowStoragePath: StoragePath
  pub let flowPublicPath: PublicPath
  pub let fusdStoragePath: StoragePath
  pub let fusdPublicPath: PublicPath
  pub let gnftStoragePath: StoragePath
  pub let gnftPublicPath: PublicPath
  pub let promiseCollectionStoragePath: StoragePath
  pub let promiseCollectionPublicPath: PublicPath

  // 
  pub var platformFeeRate: UFix64
  pub var minRentPeriod: UFix64
  pub var guarantee: UFix64
  pub let claimerPercent: UFix64
  pub let appPercent: UFix64
  pub let appWalletAddress: Address // Capability<&{FungibleToken.Receiver}>
  pub let platformWalletAddress: Address //Capability<&{FungibleToken.Receiver}>
  pub let nftName: String
  pub let appName: String
  pub let viewTypes: {UInt64: [Type]}
  pub let views: {UInt64: {Type: AnyStruct}}


  // Structs
  pub struct NFTView {
    pub let id: UInt64
    pub let uuid: UInt64
    pub let name: String
    pub let description: String
    pub let thumbnail: String
    pub let royalties: [MetadataViews.Royalty]
    pub let externalURL: String
    pub let collectionPublicPath: PublicPath?
    pub let collectionStoragePath: StoragePath?
    pub let collectionProviderPath: PrivatePath?
    pub let collectionPublic: String
    pub let collectionPublicLinkedType: String
    pub let collectionProviderLinkedType: String
    pub let collectionName: String
    pub let collectionDescription: String
    pub let collectionExternalURL: String
    pub let collectionSquareImage: String
    pub let collectionBannerImage: String
    pub let collectionSocials: {String: String}
    pub let traits: MetadataViews.Traits?

    init(
      id: UInt64,
      uuid: UInt64,
      name: String,
      description: String,
      thumbnail: String,
      royalties: [MetadataViews.Royalty],
      externalURL: String,
      collectionPublicPath: PublicPath?,
      collectionStoragePath: StoragePath?,
      collectionProviderPath: PrivatePath?,
      collectionPublic: String,
      collectionPublicLinkedType: String,
      collectionProviderLinkedType: String,
      collectionName: String,
      collectionDescription: String,
      collectionExternalURL: String,
      collectionSquareImage: String,
      collectionBannerImage: String,
      collectionSocials: {String: String},
      traits: MetadataViews.Traits?
    ) {
      self.id = id
      self.uuid = uuid
      self.name = name
      self.description = description
      self.thumbnail = thumbnail
      self.royalties = royalties
      self.externalURL = externalURL
      self.collectionPublicPath = collectionPublicPath
      self.collectionStoragePath = collectionStoragePath
      self.collectionProviderPath = collectionProviderPath
      self.collectionPublic = collectionPublic
      self.collectionPublicLinkedType = collectionPublicLinkedType
      self.collectionProviderLinkedType = collectionProviderLinkedType
      self.collectionName = collectionName
      self.collectionDescription = collectionDescription
      self.collectionExternalURL = collectionExternalURL
      self.collectionSquareImage = collectionSquareImage
      self.collectionBannerImage = collectionBannerImage
      self.collectionSocials = collectionSocials
      self.traits = traits
    }
  }

  pub struct Promise {
    pub let tokenId: UInt64
    pub let initialOwner: Address
    pub var rented: Bool
    pub var kept: Bool
    pub var claimed: Bool
    pub var tenant: Address?
    pub let rentPerDay: UFix64
    pub var startTime: UFix64
    pub let endTime: UFix64
    pub var totalRent: UFix64
    pub let rentTokenType: String
    
    init(owner: Address, tokenId: UInt64, endTime: UFix64, rentPerDay: UFix64, rentTokenType: String) {
      self.rented = false
      self.kept = true
      self.claimed = false
      self.initialOwner = owner
      self.tenant = nil
      self.rentPerDay = rentPerDay
      self.tokenId = tokenId
      self.startTime = 0.0
      self.endTime = endTime
      self.totalRent = 0.0
      self.rentTokenType = rentTokenType
    }

    pub fun fill(tenant: Address, startTime: UFix64, totalRent: UFix64) {
      pre {
        self.tenant == nil: "Already rent out 1"
        !self.rented: "Already rent out 2"
      }
      self.tenant = tenant
      self.startTime = startTime
      self.totalRent = totalRent
      self.rented = true
    }

    pub fun whenKept() {
      pre {
        // Check if rented
        self.rented: "Not rented"

        // Check if kept
        self.kept: "Not kept"

        // Check if in rent period
        getCurrentBlock().timestamp >= self.endTime: "Still in rent period"
      }

      self.rented = false
    }

    pub fun whenBroken() {
      pre {
        // Check if rented
        self.rented: "Not in rent"
        // Check if in rent period
        getCurrentBlock().timestamp < self.endTime: "Rent time finished"
      }
      self.kept = false
      self.claimed = true
    }
  }

  // Resource interface
  pub resource interface PromiseCollectionPublic {
    access(contract) fun getPromise(tokenId: UInt64): Promise?
    access(contract) fun getAllPromises(): [Promise?]
    access(contract) fun getUserRented(user: Address): [Promise?]
    access(contract) fun makePromise(acct: AuthAccount, tokenId: UInt64, endTime: UFix64, rentPerDay: UFix64, rentTokenType: String, guaranteePayment: @GnftToken.Vault)
    access(contract) fun cancelPromise(acct: AuthAccount, tokenId: UInt64)
    access(contract) fun fillPromise(tokenId: UInt64, tenant: Address, rentTokenType: String, rentFee: @FungibleToken.Vault): UFix64
    access(contract) fun endPromise(tokenId: UInt64): Promise?
    access(contract) fun claim(tokenId: UInt64, claimerVault: Capability<&{FungibleToken.Receiver}>)
    access(contract) fun cleanPromise(tokenId: UInt64, cleanerVault: Capability<&{FungibleToken.Receiver}>)
    access(contract) fun setView(tokenId: UInt64, owner: Address)
    access(contract) fun getView(tokenId: UInt64): NFTView?
  }

  // Resources
  pub resource PromiseCollection: PromiseCollectionPublic {
    pub let platformFeeRate: UFix64
    pub let minRentPeriod: UFix64
    pub let claimerPercent: UFix64
    pub let appPercent: UFix64
    pub let appWalletAddress: Address
    pub let platformWalletAddress: Address
    pub let SECONDS_PER_DAY: UFix64

    access(self) var promises: {UInt64: Promise}
    access(self) var payments: @{UInt64: GnftToken.Vault}
    access(self) var rentFees: @{UInt64: FungibleToken.Vault}
    access(self) var userTokens: {Address: [UInt64]}
    access(self) var userRented: {Address: {UInt64: UFix64}}
    access(self) var views: {UInt64: NFTView}

    // init(platformFeeRate: UFix64, minRentPeriod: UFix64, claimerPercent: UFix64, appPercent: UFix64, appReciever: Capability<&{FungibleToken.Receiver}>, platformReciever: Capability<&{FungibleToken.Receiver}>) {
    init(platformFeeRate: UFix64, minRentPeriod: UFix64, claimerPercent: UFix64, appPercent: UFix64, appWalletAddress: Address, platformWalletAddress: Address) {
      pre {
        claimerPercent >= 0.2: "Claimer percent too small"
      }
      self.platformFeeRate = platformFeeRate
      self.minRentPeriod = minRentPeriod
      self.claimerPercent = claimerPercent
      self.appPercent = appPercent
      self.appWalletAddress = appWalletAddress
      self.platformWalletAddress = platformWalletAddress
      self.SECONDS_PER_DAY = 3600.0 * 24.0
      self.promises = {}
      self.payments <- {}
      self.rentFees <- {}
      self.userTokens = {}
      self.userRented = {}
      self.views = {}
    }

    // Read Functions
    access(contract) fun getPromise(tokenId: UInt64): Promise? {
      return self.promises[tokenId]
    }

    access(contract) fun getAllPromises(): [Promise?] {
      let promises: [Promise?] = []
      for tokenId in self.promises.keys {
        if let promise = self.getPromise(tokenId: tokenId) {
          promises.append(promise)
        }
      }

      return promises
    }

    access(contract) fun getUserRented(user: Address): [Promise?] {
      let promises: [Promise?] = []
      if self.userRented.containsKey(user) {
        for tokenId in self.userRented[user]!.keys {
          if self.userRented[user]![tokenId]! > getCurrentBlock().timestamp {
            if let promise = self.getPromise(tokenId: tokenId) {
              promises.append(promise)
            }
          }
        }
      }
      return promises
    }

    access(contract) fun getView(tokenId: UInt64): NFTView? {
      return self.views[tokenId]
    }

    access(contract) fun ownedBy(tokenId: UInt64, owner: Address): Bool {
      let collection = getAccount(owner)
        .getCapability(CONTRACT_NAME_PLACEHOLDER.CollectionPublicPath)
        .borrow<&CONTRACT_NAME_PLACEHOLDER.Collection{CONTRACT_NAME_PLACEHOLDER.CONTRACT_NAME_PLACEHOLDERCollectionPublic}>()
        ?? panic("Couldn't get collection")
      return collection.borrowNFT(id: tokenId)! != nil
    }

    // Write Functions
    access(contract) fun setView(tokenId: UInt64, owner: Address) {
      let collection = getAccount(owner)
        .getCapability(CONTRACT_NAME_PLACEHOLDER.CollectionPublicPath)
        .borrow<&{MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow a reference to the collection")
      let viewResolver = collection.borrowViewResolver(id: tokenId)!

      let nftView = MetadataViews.getNFTView(id: tokenId, viewResolver : viewResolver)

      let collectionSocials: {String: String} = {}
      if nftView.collectionDisplay != nil {
        for key in nftView.collectionDisplay!.socials.keys {
          collectionSocials[key] = nftView.collectionDisplay!.socials[key]!.url
        }
      }

      let view =  RENT_CONTRACT_NAME.NFTView(
        id: nftView.id,
        uuid: nftView.uuid,
        name: nftView.display!.name,
        description: nftView.display == nil ? "" : nftView.display!.description,
        thumbnail: nftView.display == nil ? "" : nftView.display!.thumbnail.uri(),
        royalties: nftView.royalties == nil ? [] : nftView.royalties!.getRoyalties(),
        externalURL: nftView.externalURL == nil ? "" :nftView.externalURL!.url,
        collectionPublicPath: nftView.collectionData == nil ? nil : nftView.collectionData!.publicPath,
        collectionStoragePath: nftView.collectionData == nil ? nil : nftView.collectionData!.storagePath,
        collectionProviderPath: nftView.collectionData == nil ? nil : nftView.collectionData!.providerPath,
        collectionPublic: nftView.collectionData == nil ? "" : nftView.collectionData!.publicCollection.identifier,
        collectionPublicLinkedType: nftView.collectionData == nil ? "" : nftView.collectionData!.publicLinkedType.identifier,
        collectionProviderLinkedType: nftView.collectionData == nil ? "" : nftView.collectionData!.providerLinkedType.identifier,
        collectionName: nftView.collectionDisplay == nil ? "" : nftView.collectionDisplay!.name,
        collectionDescription: nftView.collectionDisplay == nil ? "" : nftView.collectionDisplay!.description,
        collectionExternalURL: nftView.collectionDisplay == nil ? "" : nftView.collectionDisplay!.externalURL.url,
        collectionSquareImage: nftView.collectionDisplay == nil ? "" : nftView.collectionDisplay!.squareImage.file.uri(),
        collectionBannerImage: nftView.collectionDisplay == nil ? "" : nftView.collectionDisplay!.bannerImage.file.uri(),
        collectionSocials: collectionSocials,
        traits: nftView.traits == nil ? nil : nftView.traits!,
      )

      self.views[tokenId] = view
    }

    access(contract) fun makePromise(acct: AuthAccount, tokenId: UInt64, endTime: UFix64, rentPerDay: UFix64, rentTokenType: String, guaranteePayment: @GnftToken.Vault) {
      pre {
        self.promises[tokenId] == nil: "promise should be empty"
        self.payments[tokenId] == nil: "payment should be empty"
        rentTokenType == "FLOW" || rentTokenType == "FUSD": "bad token"
      }
      if(!self.ownedBy(tokenId: tokenId, owner: acct.address)) {
        panic("Can not make promise: bad user")
      }

      self.promises[tokenId] = Promise(owner: acct.address, tokenId: tokenId, endTime: endTime, rentPerDay: rentPerDay, rentTokenType: rentTokenType)
      self.payments[tokenId] <-! guaranteePayment
      if !self.userTokens.containsKey(acct.address) {
        self.userTokens.insert(key: acct.address, [])
      }
      self.userTokens[acct.address]!.append(tokenId)
      self.setView(tokenId: tokenId, owner: acct.address)
    }

    access(contract) fun cancelPromise(acct: AuthAccount, tokenId: UInt64) {
      pre {
        self.promises[tokenId] != nil: "promise should not be empty"
        self.promises[tokenId]!.initialOwner == acct.address:  "not inital owner"
        !self.promises[tokenId]!.rented! : "already rented out"
        self.promises[tokenId]!.endTime > getCurrentBlock().timestamp: "rent term ended"
      }
      if(!self.ownedBy(tokenId: tokenId, owner: acct.address)) {
        panic("Can not cancel: bad user");
      }

      let rentPerDay = self.promises[tokenId]!.rentPerDay
      let rentTokenType= self.promises[tokenId]!.rentTokenType

      // remove promises
      self.promises.remove(key: tokenId)

      // remove payments & return guarantee
      let initOwnerGnftRef = getAccount(acct.address).getCapability<&{FungibleToken.Receiver}>(/public/gnftTokenReceiver).borrow()
        ?? panic("Can not get capability")
      initOwnerGnftRef.deposit(from: <- self.payments.remove(key: tokenId)!)

      // remove userTokens
      if let idx = self.userTokens[acct.address]!.firstIndex(of: tokenId) {
        self.userTokens[acct.address]!.remove(at: idx)
      }

      // remove view
      self.views.remove(key: tokenId)

      // emit events
      emit CancelList(tokenId: tokenId, lessor: acct.address, rentPerDay: rentPerDay, rentTokenType: rentTokenType)
    }

    // pub fun fillPromise(tokenId: UInt64, tenant: Address, rentFee: @FungibleToken.Vault) {
    access(contract) fun fillPromise(tokenId: UInt64, tenant: Address, rentTokenType: String, rentFee: @FungibleToken.Vault): UFix64 {
      pre {
        self.promises[tokenId] != nil: "promise should not be empty"
        self.promises[tokenId]!.initialOwner != tenant: "wrone lessor"
        !self.promises[tokenId]!.rented! : "already rented out"
      }

      let days = UInt64((self.promises[tokenId]!.endTime - getCurrentBlock().timestamp + self.SECONDS_PER_DAY - 1.0) / self.SECONDS_PER_DAY)
      let requiredFee = self.promises[tokenId]!.rentPerDay * UFix64(days)

      self.promises[tokenId]!.fill(tenant: tenant, startTime: getCurrentBlock().timestamp, totalRent: requiredFee)

      if rentTokenType == "FLOW" {
        let capability = getAccount(self.platformWalletAddress).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        let platformReceiverRef = capability.borrow() ?? panic("can not borrow platform flow receiver")
        platformReceiverRef.deposit(from: <- rentFee.withdraw(amount: requiredFee * self.platformFeeRate))
      } else if rentTokenType == "FUSD" {
        let capability = getAccount(self.platformWalletAddress).getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
        let platformReceiverRef = capability.borrow() ?? panic("can not borrow platform fusd receiver")
        platformReceiverRef.deposit(from: <- rentFee.withdraw(amount: requiredFee * self.platformFeeRate))
      } else {
        panic("bad token")
      }

      self.rentFees[tokenId] <-! rentFee.withdraw(amount: requiredFee)
      if (!self.userRented.containsKey(tenant)) {
        self.userRented[tenant] = {}
      } else {
        for tId in self.userRented[tenant]!.keys {
          if self.userRented[tenant]![tId]! < getCurrentBlock().timestamp {
            self.userRented[tenant]!.remove(key: tId)
          }
        }
      }
      self.userRented[tenant]!.insert(key: tokenId, self.promises[tokenId]!.endTime)
      destroy rentFee
      return requiredFee
    }

    access(contract) fun endPromise(tokenId: UInt64): Promise? {
      pre {
        // Check if the promise has been made
        self.promises[tokenId] != nil: "tokenId not promised"
        self.payments[tokenId] != nil: "tokenId not paid"
        self.promises[tokenId]!.endTime < getCurrentBlock().timestamp: "rent term ended"
      }
      self.promises[tokenId]!.whenKept()
      if(!self.ownedBy(tokenId: tokenId, owner: self.promises[tokenId]!.initialOwner)) {
        panic("Wrong user")
      }

      let owner = self.promises[tokenId]!.initialOwner
      // Get back guarantee
      let ownerGnftRef = getAccount(owner).getCapability<&{FungibleToken.Receiver}>(/public/gnftTokenReceiver).borrow()
        ?? panic("Can not get capability")
      ownerGnftRef.deposit(from: <- self.payments.remove(key: tokenId)!)
      // Receive rent
      if(self.promises[tokenId]!.rentTokenType == "FLOW") {
        let ownerFlowRef = getAccount(owner)
          .getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
          .borrow() ?? panic("Can not get capability")
        ownerFlowRef.deposit(from: <- self.rentFees.remove(key: tokenId)!)
      } else {
        let ownerFlowRef = getAccount(owner)
          .getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
          .borrow() ?? panic("Can not get capability")
        ownerFlowRef.deposit(from: <- self.rentFees.remove(key: tokenId)!)
      }

      if let idx = self.userTokens[owner]!.firstIndex(of: tokenId) {
        self.userTokens[owner]!.remove(at: idx)
      }
      let tenant = self.promises[tokenId]!.tenant!
      self.userRented[tenant]!.remove(key: tokenId)
      self.views.remove(key: tokenId)

      return self.promises.remove(key: tokenId)
    }

    access(contract) fun claim(tokenId: UInt64, claimerVault: Capability<&{FungibleToken.Receiver}>) {
      pre {
        // Check if the promise has been made
        self.promises[tokenId] != nil: "tokenId not promised"
        self.payments[tokenId] != nil: "tokenId not paid"
      }
      self.promises[tokenId]!.whenBroken()
      if(self.ownedBy(tokenId: tokenId, owner: self.promises[tokenId]!.initialOwner)) {
        panic("Can not claim")
      }

      let payment <- self.payments.remove(key: tokenId)!
      // 2 percent to reward users for cleaning promises

      let rentPeriodFinished: Bool = self.promises[tokenId]!.endTime < getCurrentBlock().timestamp
      var remainPercent: UFix64 = 0.0
      if !rentPeriodFinished {
        let remainPercent = 0.02
      }
      let claimerAmount = payment.balance * (self.claimerPercent - remainPercent)
      let appAmount = payment.balance * self.appPercent
      let tenantAmount = payment.balance * (1.0 - self.claimerPercent - self.appPercent)

      // Reward claimer
      claimerVault.borrow()!.deposit(from: <- payment.withdraw(amount: claimerAmount))

      // Compensation to app
      let appReciever = getAccount(self.platformWalletAddress)
        .getCapability<&{FungibleToken.Receiver}>(/public/gnftTokenReceiver)
        .borrow() ?? panic("can not borrow platform receiver")
      appReciever.deposit(from: <- payment.withdraw(amount: appAmount))

      // Compensation to tenant
      let tenantGnftRef = getAccount(self.promises[tokenId]!.tenant!).getCapability<&{FungibleToken.Receiver}>(/public/gnftTokenReceiver)
      tenantGnftRef.borrow()!.deposit(from: <- payment.withdraw(amount: tenantAmount))

      // Return rent to tenant
      if(self.promises[tokenId]!.rentTokenType == "FLOW") {
        let tenantFlowRef = getAccount(self.promises[tokenId]!.tenant!).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        tenantFlowRef.borrow()!.deposit(from: <- self.rentFees.remove(key: tokenId)!)
      } else {
        let tenantFusdRef = getAccount(self.promises[tokenId]!.tenant!).getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
        tenantFusdRef.borrow()!.deposit(from: <- self.rentFees.remove(key: tokenId)!)
      }

      // Clean userToken status
      let owner = self.promises[tokenId]!.initialOwner
      if let idx = self.userTokens[owner]!.firstIndex(of: tokenId) {
        self.userTokens[owner]!.remove(at: idx)
      }

      if rentPeriodFinished {
        self.promises.remove(key: tokenId)
        self.views.remove(key: tokenId)
        destroy payment
      } else {
        // We don't destroy the promise here, since the rental period is not finished and the app may still use it
        self.payments[tokenId] <-! payment
      }
    }

    access(contract) fun cleanPromise(tokenId: UInt64, cleanerVault: Capability<&{FungibleToken.Receiver}>) {
      pre {
        // Promise has been broken
        !self.promises[tokenId]!.kept: "promise not been broken"
        // Been claimed
        self.promises[tokenId]!.claimed: "not been claimed"
        // Rent period finished
        self.promises[tokenId]!.endTime < getCurrentBlock().timestamp: "rent period not finished"
      }

      let payment <- self.payments.remove(key: tokenId)!
      cleanerVault.borrow()!.deposit(from: <- payment.withdraw(amount: payment.balance))
      self.promises.remove(key: tokenId)
      self.views.remove(key: tokenId)

      destroy payment
    }

    destroy () {
      destroy self.payments
      destroy self.rentFees
    }
  }

  // Functions
  // Write Functions
  pub fun listForRent(acct: AuthAccount, tokenId: UInt64, endTime: UFix64, rentPerDay: UFix64, rentTokenType: String, guaranteePayment: @GnftToken.Vault) {
    pre {
      guaranteePayment.balance >= self.guarantee: "Not enough balance"
      endTime >= getCurrentBlock().timestamp + self.minRentPeriod: "Rent period too short"
    }
    let promiseCollection = self.account
      .getCapability<&PromiseCollection{PromiseCollectionPublic}>(self.promiseCollectionPublicPath)
      .borrow() ?? panic("Can not get capability")
    promiseCollection.makePromise(acct: acct, tokenId: tokenId, endTime: endTime, rentPerDay: rentPerDay, rentTokenType: rentTokenType, guaranteePayment: <- guaranteePayment)

    if let collection = acct
      .getCapability<&CONTRACT_NAME_PLACEHOLDER.Collection{NonFungibleToken.CollectionPublic, CONTRACT_NAME_PLACEHOLDER.CONTRACT_NAME_PLACEHOLDERCollectionPublic}>(CONTRACT_NAME_PLACEHOLDER.CollectionPublicPath)
      .borrow() {
      if let item = collection.borrowWeaponItem(id: tokenId) {
        self.viewTypes[tokenId] = item.getViews()
        let views: {Type: AnyStruct?} = {}
        for t in self.viewTypes[tokenId]! {
          views[t] = item.resolveView(t)
        }
        self.views[tokenId] = views
      }
    }

    emit ListForRent(tokenId: tokenId, lessor: acct.address, endTime: endTime, rentPerDay: rentPerDay, rentTokenType: rentTokenType)
  }

  pub fun cancelList(acct: AuthAccount, tokenId: UInt64) {
    let promiseCollection = self.account
      .getCapability<&PromiseCollection{PromiseCollectionPublic}>(self.promiseCollectionPublicPath)
      .borrow() ?? panic("Can not get capability")

    promiseCollection.cancelPromise(acct: acct, tokenId: tokenId)
  }

  pub fun rentFrom(tokenId: UInt64, tenant: Address, rentTokenType: String, feePayment: @FungibleToken.Vault) {
    let promiseCollection = self.account.getCapability<&PromiseCollection{PromiseCollectionPublic}>(self.promiseCollectionPublicPath).borrow()
      ?? panic("Can not get capability")
    let promise = promiseCollection.getPromise(tokenId: tokenId) ?? panic("Token not listed")
    if !promise.rented {
      let totalRent = promiseCollection.fillPromise(tokenId: tokenId, tenant: tenant, rentTokenType: rentTokenType, rentFee: <- feePayment)
      emit RentFrom(tokenId: tokenId, tenant: tenant, totalRent: totalRent, rentTokenType: rentTokenType)
    } else {
      panic("Rent failed")
    }
  }

  pub fun finishRent(acct: AuthAccount, tokenId: UInt64) {
    let promiseCollection = self.account.getCapability<&PromiseCollection{PromiseCollectionPublic}>(self.promiseCollectionPublicPath).borrow()
      ?? panic("Can not get capability")
    let promise = promiseCollection.getPromise(tokenId: tokenId) ?? panic("Token not listed")
    promiseCollection.endPromise(tokenId: tokenId)

    emit FinishRent(tokenId: promise.tokenId, lessor: promise.initialOwner, tenant: promise.tenant!, totalRent: promise.totalRent, rentTokenType: promise.rentTokenType)
  }

  pub fun claim(tokenId: UInt64, claimerVault: Capability<&{FungibleToken.Receiver}>) {
    let promiseCollection = self.account.getCapability<&PromiseCollection{PromiseCollectionPublic}>(self.promiseCollectionPublicPath).borrow()
      ?? panic("Can not get capability")
    promiseCollection.claim(tokenId: tokenId, claimerVault: claimerVault)
    let promise = promiseCollection.getPromise(tokenId: tokenId)!

    emit Claim(tokenId: promise.tokenId, lessor: promise.initialOwner, tenant: promise.tenant!, claimer: claimerVault.address, totalRent: promise.totalRent, rentTokenType: promise.rentTokenType);
  }

  pub fun clean(tokenIds: [UInt64], cleanerVault: Capability<&{FungibleToken.Receiver}>) {
    let promiseCollection = self.account.getCapability<&PromiseCollection{PromiseCollectionPublic}>(self.promiseCollectionPublicPath).borrow()
      ?? panic("Can not get capability")
    // let cleaned: [UInt64] = []
    for tokenId in tokenIds {
      promiseCollection.cleanPromise(tokenId: tokenId, cleanerVault: cleanerVault)
    }
  }

  // Read Functions
  pub fun getOneRentInfo(tokenId: UInt64): Promise? {
    let promiseCollection = self.account.getCapability<&PromiseCollection{PromiseCollectionPublic}>(self.promiseCollectionPublicPath).borrow()
      ?? panic("Can not get capability")
    return promiseCollection.getPromise(tokenId: tokenId)
  }

  pub fun getAllRentInfo(): [Promise?] {
    let promiseCollection = self.account.getCapability<&PromiseCollection{PromiseCollectionPublic}>(self.promiseCollectionPublicPath).borrow()
      ?? panic("Can not get capability")
    return promiseCollection.getAllPromises()
  }

  pub fun getUserRented(user: Address): [Promise?] {
    let promiseCollection = self.account.getCapability<&PromiseCollection{PromiseCollectionPublic}>(self.promiseCollectionPublicPath).borrow()
      ?? panic("Can not get capability")
    return promiseCollection.getUserRented(user: user)
  }

  pub fun getViewTypes(tokenId: UInt64): [Type]? {
    return self.viewTypes[tokenId]
  }

  pub fun getViews(tokenId: UInt64): {Type: AnyStruct}? {
    return self.views[tokenId]
  }

  init(platformFeeRate: UFix64, minRentPeriod: UFix64, guarantee: UFix64, claimerPercent: UFix64, appPercent: UFix64, appWalletAddress: Address, platformWalletAddress: Address, nftName: String, appName: String) {

    self.platformFeeRate = platformFeeRate
    self.minRentPeriod = minRentPeriod
    self.guarantee = guarantee
    self.claimerPercent = claimerPercent
    self.appPercent = appPercent
    self.appWalletAddress = appWalletAddress
    self.platformWalletAddress = platformWalletAddress
    self.nftName = nftName
    self.appName = appName
    self.viewTypes = {}
    self.views = {}

    let key = nftName.concat("For").concat(appName)

    // For flow rent storage
    self.flowStoragePath = StoragePath(identifier: key.concat("FlowStorage")) ?? panic("storage path: ".concat(key).concat(" failed"))
    self.flowPublicPath = PublicPath(identifier: key.concat("FlowPublic")) ?? panic("public path: ".concat(key).concat(" failed"))
    self.account.save<@FungibleToken.Vault>(<- FlowToken.createEmptyVault(), to: self.flowStoragePath)
    self.account.link<&FlowToken.Vault{FungibleToken.Receiver, FungibleToken.Balance}>(self.flowPublicPath, target: self.flowStoragePath)

    // For fusd rent storage
    self.fusdStoragePath = StoragePath(identifier: key.concat("FusdStorage")) ?? panic("storage path: ".concat(key).concat(" failed"))
    self.fusdPublicPath = PublicPath(identifier: key.concat("FusdPublic")) ?? panic("public path: ".concat(key).concat(" failed"))
    self.account.save<@FUSD.Vault>(<- FUSD.createEmptyVault(), to: self.fusdStoragePath)
    self.account.link<&FlowToken.Vault{FungibleToken.Receiver, FungibleToken.Balance}>(self.fusdPublicPath, target: self.fusdStoragePath)

    // For guarantee storage
    self.gnftStoragePath = StoragePath(identifier: key.concat("GnftStorage")) ?? panic("storage path: ".concat(key).concat(" failed"))
    self.gnftPublicPath = PublicPath(identifier: key.concat("GnftPublic")) ?? panic("public path: ".concat(key).concat(" failed"))
    self.account.save<@FungibleToken.Vault>(<- GnftToken.createEmptyVault(), to: self.gnftStoragePath)
    self.account.link<&GnftToken.Vault{FungibleToken.Receiver, FungibleToken.Balance}>(self.gnftPublicPath, target: self.gnftStoragePath)

    // PromiseCollection resource
    self.promiseCollectionStoragePath = StoragePath(identifier: key.concat("PromiseCollectionStorage")) ?? panic("storage path: ".concat(key).concat(" failed"))
    self.promiseCollectionPublicPath = PublicPath(identifier: key.concat("PromiseCollectionPublic")) ?? panic("public path: ".concat(key).concat(" failed"))
    self.account.save(<- create PromiseCollection(platformFeeRate: platformFeeRate, minRentPeriod: minRentPeriod, claimerPercent: claimerPercent, appPercent: appPercent, appWalletAddress: appWalletAddress, platformWalletAddress: platformWalletAddress), to: self.promiseCollectionStoragePath)
    self.account.link<&PromiseCollection{PromiseCollectionPublic}>(self.promiseCollectionPublicPath, target: self.promiseCollectionStoragePath)
  }
}
 
