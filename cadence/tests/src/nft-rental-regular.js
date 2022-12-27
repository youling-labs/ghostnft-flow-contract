import path from "path";

import {
  mintFlow,
  executeScript,
  sendTransaction,
  deployContractByName,
  getContractAddress,
  getAccountAddress,
} from "@onflow/flow-js-testing";

import { getGhostAdminAddress, toUFix64 } from "./common";

import {
  setupGnftAccount,
  setupFlowAccount,
  setupFusdAccount,
  mintGnft,
  transferGnft,
  transferFlow1,
} from "./tokens";

export const deployNftRentalRegular = async () => {
  const GhostAdmin = await getGhostAdminAddress();

  var res, err;
  [res, err] = await deployContractByName({
    to: GhostAdmin,
    name: "FungibleToken",
  });
  [res, err] = await deployContractByName({
    to: GhostAdmin,
    name: "NonFungibleToken",
  });
  [res, err] = await deployContractByName({
    to: GhostAdmin,
    name: "MetadataViews",
  });
  [res, err] = await deployContractByName({
    to: GhostAdmin,
    name: "WeaponItems",
  });
  [res, err] = await deployContractByName({
    to: GhostAdmin,
    name: "GnftToken",
  });
  [res, err] = await deployContractByName({
    to: GhostAdmin,
    name: "FlowToken",
  });
  [res, err] = await deployContractByName({ to: GhostAdmin, name: "FUSD" });

  const AppWallet = await getAccountAddress("AppWallet");
  const PlatformWallet = await getAccountAddress("paltformWallet");
  await setupGnftAccount(AppWallet)
  await setupGnftAccount(PlatformWallet)
  await setupFlowAccount(AppWallet)
  await setupFlowAccount(PlatformWallet)
  await setupFusdAccount(AppWallet)
  await setupFusdAccount(PlatformWallet)

  const name = "NFTRentalRegular";
  const nftName = "nft";
  const appName = "app";
  const platformFeeRate = 0.01;
  const minRentPeriod = 3600.0;
  const guarantee = 100.0;
  const claimerPercent = 0.2;
  const appPercent = 0.4;

  const args = [
    platformFeeRate,
    minRentPeriod,
    guarantee,
    claimerPercent,
    appPercent,
    AppWallet,
    PlatformWallet,
    nftName,
    appName,
  ];
  [res, err] = await deployContractByName({
    GhostAdmin,
    name,
    args,
  });
};

export const listForRent = async (
  tokenId,
  endTime,
  rentFee,
  rentTokenType,
  guarantee
) => {
  const Alice = await getAccountAddress("Alice");
  const name = "NFTRentalRegular/list_for_rent";
  const args = [tokenId, endTime, rentFee, rentTokenType, guarantee];
  const signers = [Alice];

  return sendTransaction({ name, args, signers });
};

export const rentFrom = async (tokenId, userName, rentTokenType, fee) => {
  const user = await getAccountAddress(userName);

  const name = "NFTRentalRegular/rent_from";
  const args = [tokenId, rentTokenType, fee];
  const signers = [user];

  return sendTransaction({ name, args, signers });
};

export const getOneRentInfo = async (tokenId) => {
  const Alice = await getAccountAddress("Alice");

  const name = "NFTRentalRegular/get_one_rent_info";
  const args = [tokenId];
  const signers = [Alice];

  return executeScript({ name, args, signers });
};
