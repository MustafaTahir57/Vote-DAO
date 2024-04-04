// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract DAO is Ownable {
    IERC20 public tokenAddress;
    uint256 public minTokensToVote;
    uint256 public voteFee;
    uint256 public votingDuration;

    enum ProposalStatus { Pending, Approved, Rejected }

    struct Proposal {
        string description;
        uint256 budget;
        uint256 timeline;
        ProposalStatus status;
        address proposer;
        string reason;
        mapping(address => bool) voted;
        uint256 voteCount;
        uint256 supportVotes;
        uint256 againstVotes;
        uint256 creationTime;
        uint256 endTime;
    }

    Proposal[] public proposals; // Array code 

    event ProposalSubmitted(uint256 indexed proposalIndex, string description, uint256 budget, uint256 timeline);
    event Voted(address indexed voter, uint256 indexed proposalIndex, bool inSupport);
    event ProposalExecuted(uint256 indexed proposalIndex, ProposalStatus status, string reason);
    event MinTokensToVoteSet(uint256 minTokens);
    event VoteFeeSet(uint256 fee);
    event VotingDurationSet(uint256 duration);
    event TokenAddressUpdated(address newTokenAddress);

    constructor() {
        tokenAddress = IERC20(0xddaAd340b0f1Ef65169Ae5E41A8b10776a75482d);
        minTokensToVote = 5250 * 10**18;
        voteFee = 1 * 10**18;
        votingDuration = 5 minutes;
    }

    function submitProposal(string memory _description, uint256 _budget, uint256 _timeline) external {
        uint256 proposalIndex = proposals.length;
        proposals.push();
        Proposal storage newProposal = proposals[proposalIndex];

        newProposal.description = _description;
        newProposal.budget = _budget;
        newProposal.timeline = _timeline;
        newProposal.status = ProposalStatus.Pending;
        newProposal.proposer = msg.sender;
        newProposal.voteCount = 0;
        newProposal.supportVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.creationTime = block.timestamp;
        newProposal.endTime = block.timestamp + votingDuration;


        emit ProposalSubmitted(proposalIndex, _description, _budget, _timeline);
    }

    function vote(uint256 _proposalIndex, bool _inSupport) external {
        Proposal storage proposal = proposals[_proposalIndex];
        require(!proposal.voted[msg.sender], "Already voted");
        require(block.timestamp < proposal.endTime, "Voting period has ended");
        require(msg.sender != proposal.proposer, "Proposer cannot vote on their own proposal");
        require(tokenAddress.balanceOf(msg.sender) >= minTokensToVote, "Insufficient tokens to vote");

        proposal.voted[msg.sender] = true;
        proposal.voteCount++;

        if (_inSupport) {
            proposal.supportVotes++;
        } else {
            proposal.againstVotes++;
        }

        require(tokenAddress.transferFrom(msg.sender, address(this), voteFee), "Token transfer failed");

        emit Voted(msg.sender, _proposalIndex, _inSupport);
    }

    function executeProposal(uint256 _proposalIndex, string memory _reason) external onlyOwner {
        Proposal storage proposal = proposals[_proposalIndex];
        require(block.timestamp >= proposal.endTime, "Voting period has not ended yet");
        require(proposal.status == ProposalStatus.Pending, "Proposal status is not pending");

        if (proposal.supportVotes > proposal.againstVotes) {
            proposal.status = ProposalStatus.Approved;
            proposal.reason = _reason;
            emit ProposalExecuted(_proposalIndex, ProposalStatus.Approved, _reason);
        } else {
            proposal.status = ProposalStatus.Rejected;
            proposal.reason = _reason;
            emit ProposalExecuted(_proposalIndex, ProposalStatus.Rejected, _reason);
        }
    }

    function setMinTokensToVote(uint256 _minTokens) external onlyOwner {
        minTokensToVote = _minTokens;
        emit MinTokensToVoteSet(_minTokens);
    }

    function setVoteFee(uint256 _fee) external onlyOwner {
        voteFee = _fee;
        emit VoteFeeSet(_fee);
    }

    function setVotingDuration(uint256 _duration) external onlyOwner {
        votingDuration = _duration;
        emit VotingDurationSet(_duration);
    }

    function withdrawTokens(address _recipient, uint256 _amount) external onlyOwner {
        require(tokenAddress.balanceOf(address(this)) >= _amount, "Insufficient balance");
        require(tokenAddress.transfer(_recipient, _amount), "Token transfer failed");
    }

    function getProposal(uint256 _proposalIndex) external view returns (
        string memory description,
        uint256 budget,
        uint256 timeline,
        ProposalStatus status,
        uint256 voteCount,
        uint256 supportVotes,
        uint256 againstVotes,
        uint256 creationTime,
        uint256 endTime,
        string memory reason
    ) {
        Proposal storage proposal = proposals[_proposalIndex];
        return (
            proposal.description,
            proposal.budget,
            proposal.timeline,
            proposal.status,
            proposal.voteCount,
            proposal.supportVotes,
            proposal.againstVotes,
            proposal.creationTime,
            proposal.endTime,
            proposal.reason
        );
    }

    function getProposalsLength() external view returns (uint256) {
        return proposals.length;
    }

    function hasVoted(address _voter, uint256 _proposalIndex) external view returns (bool) {
        return proposals[_proposalIndex].voted[_voter];
    }

    function getProposalsByProposer(address _proposer) external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].proposer == _proposer) {
                count++;
            }
        }
        
        uint256[] memory indices = new uint256[](count);
        
        uint256 index = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].proposer == _proposer) {
                indices[index] = i;
                index++;
            }
        }
        return indices;
    }

    function getProposalVotes(uint256 _proposalIndex) external view returns (uint256 supportVotes, uint256 againstVotes) {
        Proposal storage proposal = proposals[_proposalIndex];
        return (proposal.supportVotes, proposal.againstVotes);
    }
}