// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RatingVote {
    address public payoutRecipient;
    uint256 public totalAmount;
    address[] public voters;
    mapping(address => bool) public isVoter;
    mapping(address => bool) public hasVoted;
    mapping(address => uint256) public votes;
    
    uint256 public voteCount = 0;
    bool public payoutExecuted = false;
    
    event VoteCast(address voter, uint256 rating);
    event PayoutExecuted(address recipient, uint256 amount);
    event StateReset();
    
    constructor(address _payoutRecipient, address[] memory _voters, uint256 _totalAmount) payable {
        require(msg.value == _totalAmount, "Must fund contract with the total amount");
        require(_voters.length > 0, "Must have at least one voter");
        
        payoutRecipient = _payoutRecipient;
        totalAmount = _totalAmount;
        
        for (uint256 i = 0; i < _voters.length; i++) {
            address voter = _voters[i];
            require(!isVoter[voter], "Duplicate voter address");
            
            voters.push(voter);
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
        
        emit VoteCast(msg.sender, rating);
        
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
    
    function resetState() external payable {
        require(payoutExecuted, "Payout must be executed before reset");
        require(msg.value == totalAmount, "Must fund contract with the total amount");
        
        // Reset voter state
        for (uint256 i = 0; i < voters.length; i++) {
            hasVoted[voters[i]] = false;
            votes[voters[i]] = 0;
        }
        
        voteCount = 0;
        payoutExecuted = false;
        
        emit StateReset();
    }
    
    function getVoterCount() external view returns (uint256) {
        return voters.length;
    }
    
    function getVoteStatus() external view returns (uint256 totalVotes, uint256 remainingVotes) {
        totalVotes = voters.length;
        remainingVotes = totalVotes - voteCount;
    }
} 