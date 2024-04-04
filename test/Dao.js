const { time, loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("DAO Contract", function () {
  async function deployDAOFixture() {
    const DAO = await ethers.getContractFactory("DAO");
    const dao = await DAO.deploy();
    return { dao };
  }

  describe("Proposal Submission", function () {
    it("Should allow submission of a proposal", async function () {
      const { dao } = await loadFixture(deployDAOFixture);

      // Call the submitProposal function with sample parameters
      await dao.submitProposal("Sample Proposal", 100, 30);

      // Check if the proposal count has increased
      expect(await dao.getProposalsLength()).to.equal(1);
    });
  });

  describe("Voting", function () {
    it("Should allow voting on a proposal", async function () {
      const { dao } = await loadFixture(deployDAOFixture);

      // Submit a sample proposal
      await dao.submitProposal("Sample Proposal", 100, 30);

      // Get the proposal index
      const proposalIndex = 0;

      // Vote on the proposal
      await dao.vote(proposalIndex, true);

      // Check if the vote was successful
      expect(await dao.hasVoted(await ethers.getSigners()[0].address, proposalIndex)).to.equal(true);
    });
  });

  describe("Proposal Execution", function () {
    it("Should allow execution of a proposal", async function () {
      const { dao } = await loadFixture(deployDAOFixture);

      // Submit a sample proposal
      await dao.submitProposal("Sample Proposal", 100, 30);

      // Get the proposal index
      const proposalIndex = 0;

      // Vote on the proposal
      await dao.vote(proposalIndex, true);

      // Fast-forward time to end the voting period
      await time.increase(5 * 60); // 5 minutes

      // Execute the proposal
      await dao.executeProposal(proposalIndex, "Approved");

      // Check if the proposal status is now Approved
      const { status } = await dao.getProposal(proposalIndex);
      expect(status).to.equal(1); // ProposalStatus.Approved
    });
  });
});
