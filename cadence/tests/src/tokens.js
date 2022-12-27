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

export const setupGnftAccount = async (account) => {
  const name = "../transactions/tokens/setup_gnft_account";
  const signers = [account];

  return await sendTransaction({ name, signers});
};

export const setupFlowAccount = async (signer) => {
  const name = "../transactions/tokens/setup_flow_account";
  const signers = [signer];

  return await sendTransaction({ name, signers });
};

export const setupFusdAccount = async (signer) => {
  const name = "../transactions/tokens/setup_fusd_account";
  const signers = [signer];

  return await sendTransaction({ name, signers });
};

export const mintGnft = async (to, amount) => {
  const name = "../transactions/tokens/mint_gnft";
  const args = [to, amount];
  const signers = [to];

  return await sendTransaction({ name, args, signers });
};

export const mintFusd = async (to, amount) => {
  const name = "../transactions/tokens/mint_fusd";
  const args = [to, amount];
  const signers = [to];

  return await sendTransaction({ name, args, signers });
};

export const transferGnft = async (amount, to) => {
  const GhostAdmin = await getGhostAdminAddress();
  const name = "../transactions/tokens/transfer_gnft";
  const args = [amount, to];
  const signers = [GhostAdmin];

  return await sendTransaction({ name, args, signers });
};

export const getGnftBalance = async (account) => {
  const name = "../scripts/tokens/get_gnft_balance";
  const args = [account];
  const signers = [account];

  return await executeScript({ name, args, signers });
}

export const getFlowBalance = async (account) => {
  const name = "../scripts/tokens/get_flow_balance";
  const args = [account];
  const signers = [account];

  return await executeScript({ name, args, signers });
}

export const getFusdBalance = async (account) => {
  const name = "../scripts/tokens/get_fusd_balance";
  const args = [account];
  const signers = [account];

  return await executeScript({ name, args, signers });
}