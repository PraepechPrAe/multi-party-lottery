# Multi-Party Lottery
This smart contract, writing with Solidity, enables users to place bets of 0.001 ether on numbers ranging from 0 to 99. The winner is determined using XOR and modulo operations.

## Stage 0

- The owner constructs the contract.
## Stage 1

- Users bet 0.001 ether to join the lottery and commit their initial answers. The timer starts counting.
- Other users join and commit their answers.
- After T1 seconds, the process moves to the next stage.
## Stage 2

- Each user reveals their answer.
- After T2 seconds, if any user fails to reveal their answer, their submission is ignored without a refund, and the process moves to the next stage.
## Stage 3

- The winner is determined by XORing all valid revealed answers, hashing the result, and then taking the modulo with the number of valid users.
- Answers outside the range of 0-99 are considered invalid.
- The winner receives 98% of the total reward, while the owner receives 2%.
- If all user answers are invalid, the owner receives the entire reward.
- If the owner fails to announce the winner after T3 seconds, the process proceeds to the final stage.

## Stage 4
- All users can initiate a refund transaction.


