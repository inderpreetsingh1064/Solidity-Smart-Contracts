// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./StringUtils.sol";

contract FungibleToken is Ownable, ERC20, StringUtils {
    /**
     * @dev - hash table to store the maximum reward can be distributed by delegated account
     */
    mapping(address => uint256) private maxSpendThreshold;

    /**
     * @dev - Delegated account one to distribute 100 tokens for users
     */
    address private subOwnerOne;

    /**
     * @dev - Delegated account two to distribute 1000 tokens for users
     */
    address private subOwnerTwo;

    bool private reentrancyLock;

    /**
     * @dev - set of events emitted when a certain bussiness logic is executed which can be listened on off chain and take necessary actions
     */
    event DelegratedAccountAdded(
        address indexed accountAddress,
        uint256 threshold
    );
    event DelegratedAccountUpdated(
        address indexed fromAccountAddress,
        address indexed toAccountAddress
    );
    event AllowanceIncreased(address indexed accountAddress, uint256 allowance);
    event AllowanceDecreased(address indexed accountAddress, uint256 allowance);
    event RewardDistributed(
        address indexed fromAccountAddress,
        address indexed toAccountAddress,
        uint256 reward
    );

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        _mint(owner(), 1000000);
    }

    /**
     * @dev - function modifier to check whether the provided address is valid or not
     */
    modifier isValidAddress(address _address) {
        require(
            _address != address(0),
            "Delegated account address is not valid"
        );
        _;
    }

    /**
     * @dev - function modifier to check whether the address is one of the delegated account or not
     */
    modifier isDelegatedAccount(address _address) {
        require(
            _address == subOwnerOne || _address == subOwnerTwo,
            "Provided address is not an delegated account"
        );
        _;
    }

    enum State {
        Active, // 0
        Paused  // 1
    }

    State public state = State.Active;

    /**
     * @dev - State to toggle the contract function on and off - This is an circuit breaker pattern to pause the contract functionaility if anything goes wrong
     */
    modifier isActive() {
        require(state == State.Active, "Reward system is current passed");
        _;
    }

    /**
     * @dev - Prevent a contract function from being reentrant-called.
     */
    modifier reentrancyGuard() {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    /**
     * @dev - Helps a contract to be paused and resumed
     */
    function changeState(uint128 _stateIndex) external onlyOwner {
        if (_stateIndex == 0) {
            state = State.Active;
        } else if (_stateIndex == 1) {
            state = State.Paused;
        }
    }

    /**
     * @dev - owner can add a delegated accounts to distribute the rewards
     */
    function addDelegatedAccount(
        address _accountAddress,
        uint256 _initialAllowance,
        uint256 _delegatedAccountNumber
    ) external isValidAddress(_accountAddress) onlyOwner {
        require(
            _delegatedAccountNumber >= 1 || _delegatedAccountNumber <= 2,
            "Invalid delegated account number, only two delegated accounts are allowed"
        );
        require(
            balanceOf(owner()) >= _initialAllowance,
            "Insufficient allowance balance"
        );

        require(
            _initialAllowance >= 0,
            "allowance should be greater than equal to zero"
        );

        uint256 threshold;

        if (_delegatedAccountNumber == 1) {
            threshold = 100;
            subOwnerOne = _accountAddress;
        } else {
            threshold = 1000;
            subOwnerTwo = _accountAddress;
        }

        maxSpendThreshold[_accountAddress] = threshold;
        increaseAllowance(_accountAddress, _initialAllowance);

        emit DelegratedAccountAdded(_accountAddress, threshold);
    }

    /**
     * @dev - owners can update the delegated accounts to distribute rewards
     */
    function updateDelegatedAccount(
        address _accountAddress,
        uint256 _delegatedAccountNumber
    )
        external
        isValidAddress(_accountAddress)
        isDelegatedAccount(_accountAddress)
        onlyOwner
    {
        require(
            _delegatedAccountNumber >= 1 || _delegatedAccountNumber <= 2,
            "Invalid delegated account number, only two delegated accounts are allowed"
        );

        uint256 threshold;
        address removalAccountAddress;

        if (_delegatedAccountNumber == 1) {
            threshold = 100;
            removalAccountAddress = subOwnerOne;
            subOwnerOne = _accountAddress;
        } else {
            threshold = 1000;
            removalAccountAddress = subOwnerTwo;
            subOwnerTwo = _accountAddress;
        }

        delete maxSpendThreshold[removalAccountAddress];
        uint256 previousAllowance = allowance(owner(), removalAccountAddress);
        decreaseAllowance(removalAccountAddress, previousAllowance);

        maxSpendThreshold[_accountAddress] = threshold;
        increaseAllowance(_accountAddress, previousAllowance);

        emit DelegratedAccountUpdated(removalAccountAddress, _accountAddress);
    }

    /**
     * @dev - owner can increase the allowance of the delegated accounts
     */
    function increaseAllowanceForDelegatedAccount(
        address _accountAddress,
        uint256 _allowance
    )
        external
        isValidAddress(_accountAddress)
        isDelegatedAccount(_accountAddress)
        onlyOwner
    {
        require(
            _allowance >= 0,
            "allowance should be greater than equal to zero"
        );
        uint256 previousAllowance = allowance(owner(), _accountAddress);
        require(
            balanceOf(owner()) >= previousAllowance + _allowance,
            "Insufficient allowance balance"
        );
        increaseAllowance(_accountAddress, _allowance);

        emit AllowanceIncreased(_accountAddress, _allowance);
    }

    /**
     * @dev - owner can decrease the allocated allowance
     */
    function decreaseAllowanceForDelegatedAccount(
        address _accountAddress,
        uint256 _allowance
    )
        external
        isValidAddress(_accountAddress)
        isDelegatedAccount(_accountAddress)
        onlyOwner
    {
        require(
            _allowance >= 0,
            "allowance should be greater than equal to zero"
        );
        decreaseAllowance(_accountAddress, _allowance);
        emit AllowanceDecreased(_accountAddress, _allowance);
    }

    /**
     * @dev - user can send a array of strings as a data and get reward based on the string mirror trim logic
     */
    function distributeReward(string[] calldata data)
        public
        isActive
        reentrancyGuard 
    {
        require(data.length > 0, "Input array should have atleast one word");
        address payable selectedDelegateAccount;

        bytes memory concatedWord = bytes(trimStringMirroringChars(data));
        uint256 wordLength;

        for (uint256 i = 0; i < concatedWord.length; i++) {
            if (concatedWord[i] != "") wordLength++;
        }

        uint256 allocatedThreshold;
        if (wordLength >= 0 && wordLength <= 5) {
            selectedDelegateAccount = payable(subOwnerOne);
            allocatedThreshold = maxSpendThreshold[selectedDelegateAccount];
            require(
                allocatedThreshold == 100,
                "delegated account one can only transfer 100 tokens"
            );
        } else {
            selectedDelegateAccount = payable(subOwnerTwo);
            allocatedThreshold = maxSpendThreshold[selectedDelegateAccount];
            require(
                allocatedThreshold == 1000,
                "delegated account two can only transfer 1000 tokens"
            );
        }

        require(
            allowance(owner(), selectedDelegateAccount) >= allocatedThreshold,
            "Not enough allowance to distribute the reward"
        );
        require(
            balanceOf(owner()) >= allocatedThreshold,
            "Not enough token balance to distribute the reward"
        );

        transferFrom(owner(), msg.sender, allocatedThreshold);

        emit RewardDistributed(owner(), msg.sender, allocatedThreshold);
    }
}
