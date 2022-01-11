pragma solidity ^0.6.6;

import 'https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol';
import 'https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol';
// 'https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol';
import 'https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol';
import 'https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IERC20.sol';

contract FlashLoaner {
  address immutable factory;
  uint constant deadline = 2000;
  IUniswapV2Router02 immutable sushiRouter;

  constructor(address _factory, address _sushiRouter) public {
    factory = _factory;  
    sushiRouter = IUniswapV2Router02(_sushiRouter);
  }

  function startArbitrage(address token0, address token1, uint amount0, uint amount1) external {
    address pairAddress = IUniswapV2Factory(factory).getPair(token0, token1);
    require(pairAddress != address(0), 'There is no such pool');
    IUniswapV2Pair(pairAddress).swap(amount0, amount1, address(this), bytes('not empty'));
  }  

  function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
      address[] memory path = new address[](2);
      uint amountToken = _amount0 == 0 ? _amount1 : _amount0;
      
      address token0 = IUniswapV2Pair(msg.sender).token0();
      address token1 = IUniswapV2Pair(msg.sender).token1();

      require(msg.sender == UniswapV2Library.pairFor(factory, token0, token1), "Unauthorized"); 
      require(_amount0 == 0 || _amount1 == 0);

      path[0] = _amount0 == 0 ? token1 : token0;
      path[1] = _amount0 == 0 ? token0 : token1;

      IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
      
      token.approve(address(sushiRouter), amountToken);

      // no need for require() check, if amount required is not sent sushiRouter will revert
      uint amountRequired = UniswapV2Library.getAmountsIn(factory, amountToken, path)[0];
      uint d_line = block.timestamp + deadline;
      uint amountReceived = sushiRouter.swapExactTokensForTokens(amountToken, amountRequired, path, msg.sender, d_line)[1];

      // YEAHH PROFIT
      token.transfer(_sender, amountReceived - amountRequired);
    
  }
}
