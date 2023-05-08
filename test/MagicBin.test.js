const {expect, assert} = require("chai");
const DeployUtils = require("../scripts/lib/DeployUtils");
const {getBlockNumber} = require("./helpers");

describe("MagicBin", function () {

  let deployUtils = new DeployUtils(ethers);
  let owner, sullof, twitter, bob, alice, fred, john, jane, mark;
  let magicBin;

  before(async function () {
    [owner, sullof, twitter, bob, alice, fred, john, jane, mark] = await ethers.getSigners();
  });

  async function initAndDeploy() {
    magicBin = await deployUtils.deploy("MagicBin");
  }

    beforeEach(async function () {
      await initAndDeploy();
    });

    it("should create two series and verify their ID", async function () {
      const blockNumber = await getBlockNumber();

      await magicBin.connect(sullof).createSeries("Sullof", "A Series for Sullof", "https://twitter.com/sullof/photo");

      let sullofSeries = await magicBin.seriesByCreator(sullof.address);
      expect(sullofSeries[0].toNumber()).to.equal(1);

      let twitterSeries = await magicBin.seriesByCreator(twitter.address);
      expect(twitterSeries.length).to.equal(0);


      await magicBin.connect(twitter).createSeries("Twitter", "A Series for Twitter", "https://twitter.com/twitter/photo");
      await magicBin.connect(twitter).createSeries("Twitter2", "A 2nd Series for Twitter", "https://twitter.com/twitterdev/photo");
      twitterSeries = await magicBin.seriesByCreator(twitter.address);
      expect(twitterSeries.length).to.equal(2);

      // distribute tokens
      await magicBin.connect(sullof).mint(1, [bob.address, alice.address, fred.address], [24, 40, 36]);
      expect(await magicBin.balanceOf(bob.address, 1)).to.equal(24);
      expect(await magicBin.balanceOf(alice.address, 1)).to.equal(40);
      expect(await magicBin.balanceOf(fred.address, 1)).to.equal(36);

      await magicBin.connect(sullof).mint(1, [bob.address, john.address], [24, 120]);
      expect(await magicBin.balanceOf(bob.address, 1)).to.equal(48);
      expect(await magicBin.balanceOf(john.address, 1)).to.equal(120);

      expect(magicBin.connect(sullof).mint(1, [bob.address], [24, 120])).revertedWith("InconsistentArrays()");

      const metadata = JSON.parse(await magicBin.metadata(1));
      expect(metadata.name).to.equal("Sullof");
      expect(metadata.description).to.equal("A Series for Sullof");
      expect(metadata.image).to.equal("https://twitter.com/sullof/photo");
      expect(metadata.creator).to.equal(sullof.address.toLowerCase());
      expect(metadata.createdAtBlock > blockNumber).to.be.true;

      const seriesWithNames = await magicBin.seriesByCreatorWithNames(twitter.address);
      expect(seriesWithNames.length).to.equal(2);
      expect(seriesWithNames[0]).to.equal("2 Twitter");
      expect(seriesWithNames[1]).to.equal("3 Twitter2");

      await magicBin.connect(sullof).burn(1, [bob.address, john.address], [10, 120]);
      expect(await magicBin.balanceOf(bob.address, 1)).to.equal(38);
      expect(await magicBin.balanceOf(john.address, 1)).to.equal(0);

    });

});
