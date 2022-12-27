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
} from "@onflow/flow-js-testing";

import { getGhostAdminAddress, toUFix64 } from "../src/common";
import { deployPromises } from "../src/promises";

// Increase timeout if your tests failing due to timeout
jest.setTimeout(10000);

describe("promises-test", () => {
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, "../../");
    await init(basePath);
    await emulator.start();
    return await new Promise((r) => setTimeout(r, 1000));
  });

  // Stop emulator, so it could be restarted
  afterEach(async () => {
    await emulator.stop();
    return await new Promise((r) => setTimeout(r, 1000));
  });

  it("should be able to create a new empty NFT Collection", async () => {
    await deployPromises();
  });
});
