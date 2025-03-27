// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RatingVote {
    address public payoutRecipient = 0x449f92952d0eca6c194483fc002fB01FBd5E2c68;
    uint256 public totalAmount = 100;
    address[] public voters = [0xA4B7F1fB03B9FA2AeF9D7d7e730AD41c879e9812];
    mapping(address => bool) public isVoter;
    mapping(address => bool) public hasVoted;
    mapping(address => uint256) public votes;
    
    uint256 public voteCount = 0;
    bool public payoutExecuted = false;
    
    event VoteCast(address voter, uint256 rating);
    event PayoutExecuted(address recipient, uint256 amount);
    
    constructor() payable {
        
        for (uint256 i = 0; i < voters.length; i++) {
            address voter = voters[i];
            isVoter[voter] = true;
        }
    }
    
    function vote(uint256 rating) external {
        require(isVoter[msg.sender], "Not authorized to vote");
        require(!hasVoted[msg.sender], "Already voted");
        require(rating <= 10, "Rating must be between 0 and 10");
        
        votes[msg.sender] = rating;
        hasVoted[msg.sender] = true;
        voteCount++;
        
        // emit VoteCast(msg.sender, rating);
        
        if (voteCount == voters.length) {
            executePayout();
        }
    }
    
    function executePayout() internal {
        require(!payoutExecuted, "Payout already executed");
        require(voteCount == voters.length, "Not all votes have been cast");
        
        uint256 totalRating = 0;
        for (uint256 i = 0; i < voters.length; i++) {
            totalRating += votes[voters[i]];
        }
        
        uint256 averageRating = totalRating / voters.length;
        uint256 payoutAmount = (totalAmount * averageRating) / 10;
        
        payoutExecuted = true;
        
        (bool success, ) = payoutRecipient.call{value: payoutAmount}("");
        require(success, "Payout failed");
        
        // Return any remaining funds to the contract creator
        if (payoutAmount < totalAmount) {
            uint256 remainingAmount = totalAmount - payoutAmount;
            (bool refundSuccess, ) = payable(msg.sender).call{value: remainingAmount}("");
            require(refundSuccess, "Refund failed");
        }
        
        emit PayoutExecuted(payoutRecipient, payoutAmount);
    }
    
    function getVoterCount() external view returns (uint256) {
        return voters.length;
    }
    
    function getVoteStatus() external view returns (uint256 totalVotes, uint256 remainingVotes) {
        totalVotes = voters.length;
        remainingVotes = totalVotes - voteCount;
    }
} 