// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    //create fake new address
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function test_MinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function test_OwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function test_PriceFeedVersionIsAccurate() public view {
        uint version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function test_FundFailsWithoutEnoughEth() public {
        vm.expectRevert(); //expecting to fail
        fundMe.fund();
    }

    function test_FundsUpdatesDataStucture() public {
        vm.prank(USER); //use user for this next transaction
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function test_AddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function test_WithdrawCanOnlyBeUsedByOwner() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function test_WithdrawWithASingleFunder() public funded {
        //Arrange

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act
        uint256 startingGus = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 finishedGus = gasleft();

        uint256 usedGas = (startingGus - finishedGus) * tx.gasprice;
        console.log("used gas : ", usedGas);
        //Assert
        uint256 afterWithdrawFundMeBalance = address(fundMe).balance;
        assertEq(afterWithdrawFundMeBalance, 0);
        uint256 afterWithdrawOwnerBalance = fundMe.getOwner().balance;
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            afterWithdrawOwnerBalance
        );
    }

    function test_WithdrawWithMultipleFunders() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        uint256 numberOfFunders = 10;
        for (uint160 i = 1; i < numberOfFunders; i++) {
            //starts from address 1 because 0 may have problems
            hoax(address(i), STARTING_BALANCE); //sets up an address with money and does the next transaction
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert
        uint256 afterWithdrawFundMeBalance = address(fundMe).balance;
        assertEq(afterWithdrawFundMeBalance, 0);
        uint256 afterWithdrawOwnerBalance = fundMe.getOwner().balance;
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            afterWithdrawOwnerBalance
        );
    }

    function test_CheaperWithdrawWithMultipleFunders() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        uint256 numberOfFunders = 10;
        for (uint160 i = 1; i < numberOfFunders; i++) {
            //starts from address 1 because 0 may have problems
            hoax(address(i), STARTING_BALANCE); //sets up an address with money and does the next transaction
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //Assert
        uint256 afterWithdrawFundMeBalance = address(fundMe).balance;
        assertEq(afterWithdrawFundMeBalance, 0);
        uint256 afterWithdrawOwnerBalance = fundMe.getOwner().balance;
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            afterWithdrawOwnerBalance
        );
    }
}
