// SPDX-License-Identifier: MIT

// BBBBBBBBBBBBBBBB    YYYYYYY       YYYYYYY    BBBBBBBBBBBBBBBBB
// B::::::::::::::B    Y:::::Y       Y:::::Y    B::::::::::::::BB
// B::::::BBBBBB:::::B   Y:::::Y     Y:::::Y     B::::::BBBBBB:::::B
// BB:::::B     B:::::B   Y::::::Y   Y::::::Y     BB:::::B     B:::::B
//   B::::B     B:::::B    Y:::::Y Y Y:::::Y        B::::B     B:::::B
//   B::::B     B:::::B     Y:::::Y:::::Y           B::::B     B:::::B
//   B::::BBBBBB:::::B       Y:::::::::Y             B::::BBBBBB:::::B
//   B:::::::::::::BB         Y:::::::Y              B:::::::::::::BB
//   B::::BBBBBB:::::B         Y:::::Y               B::::BBBBBB:::::B
//   B::::B     B:::::B        Y:::::Y               B::::B     B:::::B
//   B::::B     B:::::B        Y:::::Y               B::::B     B:::::B
//   B::::B     B:::::B        Y:::::Y               B::::B     B:::::B
// BB:::::BBBBBB::::::B        Y:::::Y             BB:::::BBBBBB::::::B
// B:::::::::::::::::B      YYYY:::::YYYY          B:::::::::::::::::B
// B::::::::::::::::B       Y:::::::::::Y          B::::::::::::::::B
// BBBBBBBBBBBBBBBBB         YYYYYYYYYYY           BBBBBBBBBBBBBBBBB

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ByexToken is ERC20 {

	// Total supply: 500 million tokens
    uint256 private constant TOTAL_SUPPLY = 5e8 * 1e18; 
	
	// Vesting schedule start time
    uint256 public immutable vestingStartTime; 
	
	// Vesting period duration (30 days)
    uint256 public constant VESTING_DELAY = 30 days;

    address public constant earlyInvestors = 0x08a7E215d465a70A02047178baC9E8B10dDaF3D2;
    address public constant marketPromotion = 0x247E01cD4eA233FaD80BA88bF0aF0Ae6A36eD099;
    address public constant ecosystemDevelopment = 0x78495083D921D18bB12e9E66A9C7ccE8f64fd202;
    address public constant teamIncentives = 0x2C129f32515E3d24DaBC6A51356e15fAaCa9867b;
    address public constant protectionFund = 0x3131A844A3E185F541c63A68675A42F849c0aA2F;

	// Vesting schedule structure
    struct VestingSchedule {
        uint256 totalAmount;    
        uint256 released;       
        uint256 monthlyAmount;  
        uint256 months;         
    }
	
    // Stores vesting schedules by address
    mapping(address => VestingSchedule) public vestingSchedules;
	
	// Emitted when tokens are claimed
    event TokensClaimed(address indexed beneficiary, uint256 amount);
	
    /**
	 * @dev Initializes token with allocations and vesting schedules
	 * @param name ERC20 token name
	 * @param symbol ERC20 token symbol
	 */
    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        _mint(address(this), TOTAL_SUPPLY);

        _transfer(address(this), earlyInvestors, 25 * 1e6 * 1e18);
        _transfer(address(this), marketPromotion, 25 * 1e6 * 1e18);
        _transfer(address(this), protectionFund, 75 * 1e6 * 1e18);
        _transfer(address(this), ecosystemDevelopment, 30 * 1e6 * 1e18);
        
        _setupVesting(earlyInvestors, 625 * 1e4 * 1e18, 12); 
        _setupVesting(marketPromotion, 250 * 1e4 * 1e18, 30);
        _setupVesting(ecosystemDevelopment, 250 * 1e4 * 1e18, 48);
        _setupVesting(teamIncentives, 125 * 1e4 * 1e18, 60);

        vestingStartTime = block.timestamp + VESTING_DELAY;
    }

    /**
     * @dev Creates a vesting schedule
     * @param beneficiary Tokens recipient address
     * @param monthlyAmount Tokens released per period
     * @param months Total vesting periods
     */
    function _setupVesting(address beneficiary, uint256 monthlyAmount, uint256 months) private {
        vestingSchedules[beneficiary] = VestingSchedule({
            totalAmount: monthlyAmount * months,
            released: 0,
            monthlyAmount: monthlyAmount,
            months: months
        });
    }

    /**
     * @dev Claims available vested tokens
     * @param beneficiary Address to claim tokens for
     */
    function claimVestedTokens(address beneficiary) external {
        require(block.timestamp >= vestingStartTime, "Vesting has not started yet");
		
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.totalAmount > 0, "No vesting schedule for this address");

        uint256 elapsedMonths = (block.timestamp - vestingStartTime) / VESTING_DELAY;
        uint256 releasableMonths = elapsedMonths > schedule.months ? schedule.months : elapsedMonths;
        uint256 releasableAmount = releasableMonths * schedule.monthlyAmount - schedule.released;

        require(releasableAmount > 0, "There are currently no tokens available for release");
		
        schedule.released += releasableAmount;
		
        _transfer(address(this), beneficiary, releasableAmount);
		
        emit TokensClaimed(beneficiary, releasableAmount);
    }

    /**
     * @dev Checks claimable token amount
     * @param beneficiary Address to check
     * @return uint256 Currently claimable token amount
     */
    function getReleasableAmount(address beneficiary) public view returns (uint256) {
        if (block.timestamp < vestingStartTime) return 0;
		
        VestingSchedule memory schedule = vestingSchedules[beneficiary];
        if (schedule.totalAmount == 0) return 0;

        uint256 elapsedMonths = (block.timestamp - vestingStartTime) / VESTING_DELAY;
        uint256 releasableMonths = elapsedMonths > schedule.months ? schedule.months : elapsedMonths;
        return releasableMonths * schedule.monthlyAmount - schedule.released;
    }
}
