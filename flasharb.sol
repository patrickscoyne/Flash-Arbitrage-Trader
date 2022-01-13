pragma solidity ^0.6.6;

import 'https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol';
import 'https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol';
import 'https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Callee.sol';
import 'https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol';
import 'https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IERC20.sol';

contract Arbitrage {
    address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    IUniswapV2Router02 public sushiRouter;

    constructor() public {
        
        address _sushiRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;  
        sushiRouter = IUniswapV2Router02(_sushiRouter);
    }

    function startArbitrage(address token0, address token1, uint amount0, uint amount1) external {
        address pairAddress = IUniswapV2Factory(factory).getPair(token0, token1);
        require(pairAddress != address(0), 'There is no such pool');
        IUniswapV2Pair(pairAddress).swap(amount0, amount1, address(this), bytes('not empty'));
    }

    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
        address[] memory path = new address[](2);
        address[] memory path2 = new address[](2);
        uint amountToken = _amount0 == 0 ? _amount1 : _amount0;
    
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();

        require(msg.sender == UniswapV2Library.pairFor(factory, token0, token1), 'Unauthorized'); 
        require(_amount0 == 0 || _amount1 == 0);

        path[0] = _amount0 == 0 ? token1 : token0;
        path[1] = _amount0 == 0 ? token0 : token1;
        path2[0] = path[1];
        path2[1] = path[0];

        IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
    
        token.approve(address(sushiRouter), amountToken);
        uint deadline = block.timestamp + 200;
        uint amt_w_fee = amountToken + ((amountToken * 3) / 997 ) + 1;
        uint amountRequired = UniswapV2Library.getAmountsIn(factory, amt_w_fee, path2)[0];
        uint amountReceived = sushiRouter.swapExactTokensForTokens(amountToken, amountRequired, path, address(this), deadline)[1];

        IERC20 otherToken = IERC20(_amount0 == 0 ? token0 : token1);
        otherToken.transfer(msg.sender, amountRequired); //Reimbursh Loan
        otherToken.transfer(tx.origin, amountReceived - amountRequired); //Keep Profit
    }




}
