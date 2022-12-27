import path from "path";

import {
  emulator,
  init,
  getAccountAddress,
  shallPass,
  shallResolve,
  shallRevert,
  deployContractByName,
  getContractAddress,
  mintFlow,
} from "@onflow/flow-js-testing";

import { getGhostAdminAddress, toUFix64 } from "../src/common";

import {
  deployWeaponItems,
  getWeaponItemCount,
  getWeaponItemSupply,
  mintWeaponItem,
  setupWeaponItemsOnAccount,
  transferWeaponItem,
} from "../src/weapon-items";

import {
  deployNftRentalRegular,
  getOneRentInfo,
  listForRent,
  rentFrom,
} from "../src/nft-rental-regular";

import {
  setupGnftAccount,
  setupFusdAccount,
  mintGnft,
  mintFusd,
  getFlowBalance,
  getFusdBalance,
} from "../src/tokens";

// Increase timeout if your tests failing due to timeout
jest.setTimeout(20000);

describe("nft-rental-regular", () => {
  var r, e;
  var flowBalance = 1000.0
  var fusdBalance = 2000.0
  var gnftBalance = 3000.0
  var Alice, Bob;

  beforeEach(async () => {
    const basePath = path.resolve(__dirname, "../../");
    await init(basePath);
    await emulator.start();

    Alice = await getAccountAddress("Alice");
    Bob = await getAccountAddress("Bob");
    await deployNftRentalRegular();
    await shallPass(setupWeaponItemsOnAccount(Alice));
    await shallPass(setupGnftAccount(Alice));
    await shallPass(setupFusdAccount(Alice));
    await shallPass(setupFusdAccount(Bob));
    await shallPass(mintGnft(Alice, gnftBalance));
    await shallPass(mintFusd(Alice, fusdBalance))
    await shallPass(mintFusd(Bob, fusdBalance));
    await shallPass(mintFlow(Alice, flowBalance));
    await shallPass(mintFlow(Bob, flowBalance));
    await shallPass(mintWeaponItem(Alice));

    return await new Promise((r) => setTimeout(r, 1000));
  });

  // Stop emulator, so it could be restarted
  afterEach(async () => {
    await emulator.stop();
    return await new Promise((r) => setTimeout(r, 1000));
  });

  it("Test rent info", async () => {

    var rent = 51.0

    const tokenId = 0;
    const endTime = 1669428215.0;
    const rentFeePerDay = 0.1;
    const rentTokenType = "FUSD";
    const guarantee = 100.0;

    var [balance0, e] = await getFusdBalance(Bob);
    expect(Number(balance0)).toBe(fusdBalance);

    await shallPass(listForRent(tokenId, endTime, rentFeePerDay, rentTokenType, guarantee));
    [r, e] = await shallResolve(getOneRentInfo(tokenId));
    // console.log(r);
    await shallPass(rentFrom(0, "Bob", rentTokenType, rent));
    [r, e] = await shallResolve(getOneRentInfo(tokenId));
    // console.log(r);

    var [balance1, e] = await getFusdBalance(Bob);
    expect(Number(balance1)).toBe(fusdBalance - rent);
  });

  it("Test rent info", async () => {

  });
});
