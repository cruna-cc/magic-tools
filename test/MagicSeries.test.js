const {expect, assert} = require("chai");
const DeployUtils = require("../scripts/lib/DeployUtils");
const {getBlockNumber, addr0} = require("./helpers");

describe("MagicSeries", function () {
  let deployUtils = new DeployUtils(ethers);
  let owner, sullof, twitter, bob, alice, fred, john, minter1, burner1, minter2;
  let magicSeries;

  before(async function () {
    [owner, sullof, twitter, bob, alice, fred, john, minter1, burner1, minter2] = await ethers.getSigners();
  });

  async function initAndDeploy() {
    magicSeries = await deployUtils.deploy("MagicSeries");
  }

  beforeEach(async function () {
    await initAndDeploy();
  });

  it("should create two series and verify their ID", async function () {
    const blockNumber = await getBlockNumber();

    await magicSeries
      .connect(sullof)
      .createSeries("Sullof", "A Series for Sullof", "https://twitter.com/sullof/photo", minter1.address, burner1.address);

    let sullofSeries = await magicSeries.seriesByCreator(sullof.address);
    expect(sullofSeries[0].toNumber()).to.equal(1);

    let twitterSeries = await magicSeries.seriesByCreator(twitter.address);
    expect(twitterSeries.length).to.equal(0);

    await magicSeries
      .connect(twitter)
      .createSeries("Twitter", "A Series for Twitter", "https://twitter.com/twitter/photo", addr0, addr0);
    await magicSeries
      .connect(twitter)
      .createSeries("Twitter2", "A 2nd Series for Twitter", "https://twitter.com/twitterdev/photo", minter2.address, addr0);
    twitterSeries = await magicSeries.seriesByCreator(twitter.address);
    expect(twitterSeries.length).to.equal(2);

    await expect(magicSeries.connect(sullof).mint(1, [bob.address, alice.address, fred.address], [24, 40, 36])).revertedWith(
      "NotTheSeriesMinter()"
    );

    // distribute tokens
    await magicSeries.connect(minter1).mint(1, [bob.address, alice.address, fred.address], [24, 40, 36]);
    expect(await magicSeries.balanceOf(bob.address, 1)).to.equal(24);
    expect(await magicSeries.balanceOf(alice.address, 1)).to.equal(40);
    expect(await magicSeries.balanceOf(fred.address, 1)).to.equal(36);

    await magicSeries.connect(minter1).mint(1, [bob.address, john.address], [24, 120]);
    expect(await magicSeries.balanceOf(bob.address, 1)).to.equal(48);
    expect(await magicSeries.balanceOf(john.address, 1)).to.equal(120);

    expect(magicSeries.connect(minter1).mint(1, [bob.address], [24, 120])).revertedWith("InconsistentArrays()");

    let metadata = JSON.parse(await magicSeries.metadata(1));

    // console.log(metadata);

    expect(metadata.name).to.equal("Sullof");
    expect(metadata.description).to.equal("A Series for Sullof");
    expect(metadata.image).to.equal("https://twitter.com/sullof/photo");
    expect(metadata.minter).to.equal(minter1.address.toLowerCase());
    expect(metadata.burner).to.equal(burner1.address.toLowerCase());
    expect(metadata.creator).to.equal(sullof.address.toLowerCase());
    expect(metadata.createdAtBlock > blockNumber).to.be.true;

    const seriesWithNames = await magicSeries.seriesByCreatorWithNames(twitter.address);
    expect(seriesWithNames.length).to.equal(2);
    expect(seriesWithNames[0]).to.equal("2 Twitter");
    expect(seriesWithNames[1]).to.equal("3 Twitter2");

    await magicSeries.connect(burner1).burn(1, [bob.address, john.address], [10, 120]);
    expect(await magicSeries.balanceOf(bob.address, 1)).to.equal(38);
    expect(await magicSeries.balanceOf(john.address, 1)).to.equal(0);

    // update metadata

    await expect(
      magicSeries
        .connect(sullof)
        .updateSeriesMetadata(1, "Sullof2", "A Series for Sullof2", "https://twitter.com/sullof2/photo")
    )
      .emit(magicSeries, "SeriesMetadataUpdated")
      .withArgs(1, "Sullof2", "A Series for Sullof2", "https://twitter.com/sullof2/photo");

    metadata = JSON.parse(await magicSeries.metadata(1));

    // console.log(metadata);

    expect(metadata.name).to.equal("Sullof2");
    expect(metadata.description).to.equal("A Series for Sullof2");
    expect(metadata.image).to.equal("https://twitter.com/sullof2/photo");

    // end minting

    await expect(magicSeries.connect(sullof).updateSeriesMinter(1, addr0))
      .emit(magicSeries, "SeriesMinterUpdated")
      .withArgs(1, addr0);

    metadata = JSON.parse(await magicSeries.metadata(1));
    expect(metadata.minter).to.equal("0x00");

    await expect(magicSeries.connect(minter1).mint(1, [bob.address, alice.address, fred.address], [24, 40, 36])).revertedWith(
      "MintingHasEnded()"
    );

    await expect(magicSeries.connect(sullof).updateSeriesBurner(1, addr0))
      .emit(magicSeries, "SeriesBurnerUpdated")
      .withArgs(1, addr0);

    await expect(magicSeries.connect(burner1).burn(1, [bob.address, john.address], [10, 120])).revertedWith("NotBurnable()");
  });
});
