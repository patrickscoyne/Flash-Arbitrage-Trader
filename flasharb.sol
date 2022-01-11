pragma solidity ^0.6.6;

import 'https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol';
import 'https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol';
import 'https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Callee.sol';
import 'https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol';
import 'https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IERC20.sol';

//interface IUniswapV2Callee {
    //function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
//}

contract TestUniswapFlashSwap is IUniswapV2Callee {
    address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    function testFlashSwap(address _tokenBorrow, uint _amount) external {
        address pair = IUniswapV2Factory(FACTORY).getPair(_tokenBorrow, WETH);
        require(pair != address(0), "Pair!");
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint amount1Out = _tokenBorrow == token1 ? _amount : 0;
        bytes memory data = abi.encode(_tokenBorrow, _amount);
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }
    function uniswapV2Call (address _sender, uint _anount0, uint _amount1, bytes calldata _data) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(FACTORY).getPair(token0, token1);
        require(msg.sender == pair, "Pair!");
        (address tokenBorrow, uint amount) = abi.decode(_data, (address, uint));

        //fee
        uint fee = ((amount * 3) / 997) + 1;
        uint amountToRepay = amount + fee;

        IERC20(tokenBorrow).transfer(pair, amountToRepay);
    }

}



