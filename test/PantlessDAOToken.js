require("dotenv").config();

const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PantlessDAOToken", function () {
  let owner;
  let treasury;
  let admin;
  let minter;
  let claimer;
  let pantlessDAOToken;

  beforeEach(async function () {
    [owner, treasury, admin, minter, claimer] = await ethers.getSigners();

    const PantlessDAOToken = await ethers.getContractFactory(
      "PantlessDAOToken"
    );
    pantlessDAOToken = await PantlessDAOToken.deploy(
      process.env.TOKEN_BASE_URI,
      treasury.address
    );
    await pantlessDAOToken.deployed();
  });

  describe("claim founder tokens", function () {
    it("Should emit FounderTokenClaimed event", async function () {
      // const tokenId = await pantlessDAOToken.nextFounderTokenId();
      // const numEligibleTokens = await pantlessDAOToken.nextFounderTokenId();
      // await pantlessDAOToken.connect(owner).toggleIsActive();
      // await expect(
      //   pantlessDAOToken.connect(claimer).claimFounderToken(claimer.address, numEligibleTokens)
      // )
      //   .to.emit(pantlessDAOToken, "FounderTokenClaimed")
      //   .withArgs(claimer.address, nextClaimableTokenId);
    });

    // it('Should revert if claiming is not enabled', async function () {
    //   await expect(
    //     hexHex.connect(claimer).claim(claimer.address, claimedLootIds[0]),
    //   ).to.be.revertedWith('Claiming is not enabled');
    //   await hexHex.connect(admin).enableClaiming();
    //   await hexHex.connect(admin).disableClaiming();
    //   await expect(
    //     hexHex.connect(claimer).claim(claimer.address, claimedLootIds[0]),
    //   ).to.be.revertedWith('Claiming is not enabled');
    // });

    // it('Should revert if claimer is not the owner of given loot', async function () {
    //   await hexHex.connect(admin).enableClaiming();
    //   await expect(
    //     hexHex.connect(claimer).claim(claimer.address, ownerClaimedLootIds[0]),
    //   ).to.be.revertedWith('Not owner of the loot');
    // });

    // it('Should revert if token is already claimed by given loot', async function () {
    //   await hexHex.connect(admin).enableClaiming();
    //   await hexHex.connect(claimer).claim(claimer.address, claimedLootIds[0]),
    //     await expect(
    //       hexHex.connect(claimer).claim(claimer.address, claimedLootIds[0]),
    //     ).to.be.revertedWith('Already claimed');
    // });
  });

  // describe('mint', function () {
  //   it('Should emit Minted event', async function () {
  //     const price = await hexHex.price();
  //     let nextMintableTokenId = await hexHex.nextMintableTokenId();
  //     await hexHex.connect(admin).enableMinting();
  //     await expect(
  //       hexHex.connect(minter).mint(minter.address, { value: price }),
  //     )
  //       .to.emit(hexHex, 'Minted')
  //       .withArgs(minter.address, nextMintableTokenId);
  //     const lastMintableTokenId = nextMintableTokenId;
  //     nextMintableTokenId = await hexHex.nextMintableTokenId();
  //     await expect(nextMintableTokenId).eq(lastMintableTokenId.add(1));
  //   });

  //   it('Should transfer value to the treasury', async function () {
  //     const price = await hexHex.price();
  //     await hexHex.connect(admin).enableMinting();
  //     await expect(
  //       await hexHex.connect(minter).mint(minter.address, { value: price }),
  //     ).to.changeEtherBalances([treasury, minter], [price, price.mul(-1)]);
  //   });

  //   it('Should revert if minting is not enabled', async function () {
  //     const price = await hexHex.price();
  //     await expect(
  //       hexHex.connect(minter).mint(minter.address, { value: price }),
  //     ).to.be.revertedWith('Minting is not enabled');
  //     await hexHex.connect(admin).enableMinting();
  //     await hexHex.connect(admin).disableMinting();
  //     await expect(
  //       hexHex.connect(minter).mint(minter.address, { value: price }),
  //     ).to.be.revertedWith('Minting is not enabled');
  //   });

  //   // This test takes over 1 min to run
  //   it('Should revert if all tokens are minted', async function () {
  //     const price = await hexHex.price();
  //     const maxSupply = await hexHex.maxSupply();
  //     const maxSupplyClaimable = await hexHex.maxSupplyClaimable();
  //     await hexHex.connect(admin).enableMinting();
  //     await Promise.all(
  //       new Array(maxSupply.sub(maxSupplyClaimable).toNumber())
  //         .fill(null)
  //         .map(() =>
  //           hexHex.connect(minter).mint(minter.address, { value: price }),
  //         ),
  //     );
  //     await expect(
  //       hexHex.connect(minter).mint(minter.address, { value: price }),
  //     ).to.be.revertedWith('All tokens are minted');
  //   });

  //   it('Should revert if value is wrong', async function () {
  //     const price = await hexHex.price();
  //     await hexHex.connect(admin).enableMinting();
  //     await expect(
  //       hexHex.connect(minter).mint(minter.address, { value: price.sub(1) }),
  //     ).to.be.revertedWith('Value is wrong');
  //     await expect(
  //       hexHex.connect(minter).mint(minter.address, { value: price.add(1) }),
  //     ).to.be.revertedWith('Value is wrong');
  //   });
  // });

  // describe('setHexCodes', function () {
  //   it('Should set hex codes', async function () {
  //     const hexCodes = [
  //       [0x1f0d39, 0xca0048, 0x386f5b, 0xe16166, 0x134561, 0x73f7c7],
  //       [0x9144d3, 0xec0de4, 0xf602e9, 0x557530, 0x0af5b7, 0x236292],
  //       [0x4359fc, 0x3c829e, 0x0d5460, 0x15437a, 0x7b2430, 0xb8bd69],
  //     ];
  //     await hexHex.connect(admin).setHexCodes(hexCodes);
  //     for (let i = 0; i < hexCodes.length; ++i) {
  //       for (let j = 0; j < hexCodes[i].length; ++j) {
  //         await expect(await hexHex.hexCodes(i, j)).to.eq(hexCodes[i][j]);
  //       }
  //     }
  //   });
  // });
});
