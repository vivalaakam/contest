import { ethers } from "hardhat";
import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";

const CONTEST_NAME = "test name";
const AMOUNT = ethers.utils.parseEther("1");

describe("ContestV2", function () {
  async function deployOneYearLockFixture() {
    const endTime = (await time.latest()) + 60;
    const [
      owner,
      participant1,
      participant2,
      participant3,
      participant4,
      participant5,
    ] = await ethers.getSigners();

    const ticketPrise = ethers.utils.parseEther("1");

    const Contest = await ethers.getContractFactory("ContestV2");
    const contest = await Contest.deploy(
      10,
      CONTEST_NAME,
      endTime,
      ticketPrise
    );

    return {
      contest,
      endTime,
      owner,
      participant1,
      participant2,
      participant3,
      participant4,
      participant5,
    };
  }

  it("should get name and description", async () => {
    const { contest, endTime } = await loadFixture(deployOneYearLockFixture);
    const balance0ETH = await contest.provider.getBalance(contest.address);
    expect(await contest.name()).to.be.equal("test name");
    expect(await contest.endTime()).to.be.equal(endTime);
    expect(balance0ETH.toHexString()).to.be.equal("0x00");
  });

  it("should provide to participate", async () => {
    const { contest, participant1, participant2 } = await loadFixture(
      deployOneYearLockFixture
    );
    expect(
      await contest.connect(participant1).participate({
        value: AMOUNT,
      })
    ).to.be.exist;

    expect(
      await contest.connect(participant1).participate({
        value: AMOUNT,
      })
    ).to.be.exist;

    expect(
      await contest.connect(participant2).participate({
        value: AMOUNT,
      })
    ).to.be.exist;

    expect(await contest.balance(participant1.getAddress())).to.be.equal(2);
    expect(await contest.balance(participant2.getAddress())).to.be.equal(1);

    const participant1Balance = await contest.provider.getBalance(
      participant1.getAddress()
    );

    const participant2Balance = await contest.provider.getBalance(
      participant2.getAddress()
    );

    await contest.getWinners();

    expect(await contest.getWinnersLength()).to.be.equal(3);

    const participant1BalanceAfter = await contest.provider.getBalance(
      participant1.getAddress()
    );

    expect(participant1BalanceAfter.toHexString()).to.be.equal(
      participant1Balance.add(AMOUNT.mul(2)).toHexString()
    );

    const participant2BalanceAfter = await contest.provider.getBalance(
      participant2.getAddress()
    );

    expect(participant2BalanceAfter.toHexString()).to.be.equal(
      participant2Balance.add(AMOUNT).toHexString()
    );
  });

  it("should select winners", async () => {
    const {
      contest,
      participant1,
      participant2,
      participant3,
      participant4,
      participant5,
    } = await loadFixture(deployOneYearLockFixture);

    for (let i = 0; i < 3; i += 1) {
      await contest.connect(participant1).participate({
        value: ethers.utils.parseEther("1"),
      });
      await contest.connect(participant2).participate({
        value: ethers.utils.parseEther("1"),
      });
      await contest.connect(participant3).participate({
        value: ethers.utils.parseEther("1"),
      });
      await contest.connect(participant4).participate({
        value: ethers.utils.parseEther("1"),
      });
      await contest.connect(participant5).participate({
        value: ethers.utils.parseEther("1"),
      });
    }

    expect(await contest.balance(participant1.getAddress())).to.be.equal(3);
    expect(await contest.balance(participant2.getAddress())).to.be.equal(3);
    expect(await contest.balance(participant3.getAddress())).to.be.equal(3);
    expect(await contest.balance(participant4.getAddress())).to.be.equal(3);
    expect(await contest.balance(participant5.getAddress())).to.be.equal(3);

    expect(await contest.getWinners()).to.be.exist;
    expect(await contest.getWinnersLength()).to.be.equal(10);
  });

  it("should not apply participant if date is end", async () => {
    const endTime = (await time.latest()) - 60;

    const [owner, participant1] = await ethers.getSigners();

    const Contest = await ethers.getContractFactory("Contest");
    const contest = await Contest.deploy(
      10,
      CONTEST_NAME,
      endTime,
      ethers.utils.parseEther("1")
    );

    await expect(
      contest.connect(participant1).participate({
        value: ethers.utils.parseEther("1"),
      })
    ).to.be.revertedWith("Contest closed");
  });

  it("should apply participant if date is 0", async () => {
    const [owner, participant1] = await ethers.getSigners();

    const Contest = await ethers.getContractFactory("Contest");
    const contest = await Contest.deploy(
      10,
      CONTEST_NAME,
      0,
      ethers.utils.parseEther("1")
    );

    await contest.connect(participant1).participate({
      value: ethers.utils.parseEther("1"),
    });
    expect(await contest.balance(participant1.getAddress())).to.be.equal(1);
  });
});
