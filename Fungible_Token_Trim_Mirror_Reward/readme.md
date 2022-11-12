# Read the instruction to deploy and interact with the smart contract

Smart contracts are usually developed with remix code editor / truffle suite / hardhat. To check the smart contracts easily, the best option is remix editor as it doesn't require any framework setup and tools

### Note:
Usually most of the complex string manipulation are handled in the client side / off chain, complex string manipulation in smart contract will increase the gas and string manipulation is not recommended while creating an production level smart contracts.

## How to deploy and interact with smart contract

1. Go to https://remix.ethereum.org/ website and create new folder as Fungible Token Contract
2. You can either use a multi file smart contracts / flattned smart contract to deploy and interact with it
3. Copy paste your preferred smart contract type into remix editor and save the contract
4. Go to solidity compiler in the left toolbar and choose the contract version as 0.8.4 ( https://prnt.sc/d43fhcJJV_B0 )
5. Click the compile button to compile the smart contracts ( https://prnt.sc/d43fhcJJV_B0 )
6. Once the contract is successfully compiled without any errors, go to the Deploy and run transaction tab ( https://prnt.sc/UqI6zQQShHg4 )
7. Choose the environment based on your requirement ( Javascript VM, web3 injector etc. ) ( https://prnt.sc/UqI6zQQShHg4 )
8. Choose the fungible token contract and type the token name and token symbol in deploy field ( https://prnt.sc/GqfLcEJIWMQd )
9. Click deploy button to deploy the contract and a new contract instance will be opened below ( https://prnt.sc/Nv5dfaRe0oO1 )
10. Use the new contract instance to interact with the smart contract ( https://prnt.sc/HC5N2p7Jv-d7 )
