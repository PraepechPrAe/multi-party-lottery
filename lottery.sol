pragma solidity >=0.7.0 <0.9.0;

import "./CommitReveal.sol";

contract lottery is CommitReveal{
    struct User { //user status
        bytes32 hashedInput;
        address addr;
        bool isReveal;
        bool isValid;
    }
    address public owner;
    uint public  T1; //Stage 1 end time
    uint public  T2; //Stage 2 end time
    uint public  T3; //Stage 2 end time
    uint public N; //Number of Target Users
    uint public numUser = 0; //Number of Users
    uint public reward = 0; //Lotto Reward
    uint public firstJoin_time = 0;
    

    mapping (uint => User) public user; 
    mapping (address => uint) public user_idx;
    mapping (address => uint) public user_lotto;

    constructor(uint t1, uint t2, uint t3, uint n) {
        T1 = t1;
        T2 = t2;
        T3 = t3;
        N = n;
        owner = msg.sender;
    }

    function currentStateCheck() public view returns(uint) {
        if(firstJoin_time == 0) {
            return 0;
        }

        if(block.timestamp > firstJoin_time) {
            if(block.timestamp < firstJoin_time + T1) {
                return 1;
            }
            else if(block.timestamp < firstJoin_time + T1 + T2) {
                return 2;
            }
            else if(block.timestamp < firstJoin_time + T1 + T2 + T3) {
                return 3;
            }
            else {
                return 4;
            }
        }
    }

//Stage 1 : first join + T1 => go to Stage 2
//Commit Ans

    function hashInput(uint choice, uint salt) public view returns(bytes32){
        return getSaltedHash(bytes32(choice), bytes32(salt));
    }

    function joinLotto(bytes32 hashedInput) public payable {
        require(currentStateCheck() == 0 || currentStateCheck() == 1);
        require(numUser < N);
        require(msg.value == 0.001 ether);
        reward += msg.value;
        user[numUser].addr = msg.sender;
        user_idx[user[numUser].addr] = numUser;
        user[numUser].hashedInput = hashedInput;
        commit(hashedInput);
        user[numUser].isReveal = false;
        user[numUser].isValid = false;
        numUser++;
        if(firstJoin_time == 0) {
            firstJoin_time = block.timestamp;
        }
    }

//Stage 2 : After T2 s. => go to stage 3
//Reveal Ans, After T2 s. if not ignore that user ans

    function revealLotto(uint answer,uint salt) public {
        require(currentStateCheck() == 2);
        revealAnswer(bytes32(answer), bytes32(salt));
        user_lotto[msg.sender] = answer;
        user[user_idx[msg.sender]].isReveal = true;

    }

//Stage 3 : After T3 s. if owner didn't announce winner => Stage 4
//Find winner H(x xor y xor z) % 3
// if out of range 0-999 -> invalid
// winner got  0.001 ETH * numUser * 0.98
// owner got 0.001 ETH * numUser * 0.02
// if all invalid -> owner got all

    function checkValid() public {
        require(msg.sender == owner);
        for (uint i=0; i<numUser; i++) {
            if ((user_lotto[user[i].addr] >= 0 ) && (user_lotto[user[i].addr] <= 999)) {
                user[i].isValid = true;
            }
        }
    }

    function findWinner() public payable {
        require(currentStateCheck() == 3);
        require(msg.sender == owner);
        checkValid();
        uint XOR_value = 0;
        uint validUser = 0;

        for (uint i=0; i < numUser; i++) { //XOR
            if (user[i].isValid) {
                XOR_value ^= user_lotto[user[i].addr];
                validUser++;
            }
        }

        if (validUser != 0) {
            bytes32 hashXOR = getHash(bytes32(XOR_value));
            uint winnerIdx = uint(hashXOR) % validUser;
            payable(user[winnerIdx].addr).transfer(reward * 98 / 100);
            payable(owner).transfer(reward * 98 /100);
        }
        else {
            payable(owner).transfer(reward);
        }
        if (reward == 0) {
        resetParam();
        }
    }

    function refund() public {
        require(currentStateCheck() == 4);
        require(msg.sender == user[user_idx[msg.sender]].addr);
        payable(msg.sender).transfer(0.001 ether);
        if (reward == 0) {
        resetParam();
        }
    }

    function resetParam() private {
        for (uint i=0; i < numUser; i++) {
            delete commits[user[i].addr];
            delete user_lotto[user[i].addr];
            delete user_idx[user[i].addr];
            delete user[i];
        }
        numUser = 0; 
        reward = 0; 
        firstJoin_time = 0;
}
}

