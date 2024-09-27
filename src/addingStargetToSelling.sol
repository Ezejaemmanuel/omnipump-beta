// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import {CustomToken} from "./customToken.sol";
// import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
// import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
// import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
// import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
// import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
// // solc-ignore-next-line invalid-import
// import {ISwapRouter02} from "@uniswap/v3-swap-routers/contracts/interfaces/ISwapRouter02.sol";
// import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
// import {IWETH9} from "../test/mocks/IWETH.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IQuoterV2} from "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
// import {IV3SwapRouter} from "lib/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";
// //
// import {OftCmdHelper} from "lib/stargate-v2/packages/stg-evm-v2/test/utils/OftCmdHelper.sol";
// import {IStargate} from "lib/stargate-v2/packages/stg-evm-v2/src/interfaces/IStargate.sol";
// // lib/LayerZero-v2/packages/layerzero-v2/evm/protocol/contracts/interfaces/ILayerZeroComposer.sol
// import {ILayerZeroComposer} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroComposer.sol";
// //lib/LayerZero-v2/packages/layerzero-v2/evm/oapp/contracts/oft/libs/OFTComposeMsgCodec.sol
// import {MessagingFee, OFTReceipt, SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
// import {OFTComposeMsgCodec} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol";
// import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";

// contract MainEngine is IERC721Receiver, Ownable, ILayerZeroComposer {
//     uint256 public constant LIQUIDITY_LOCK_PERIOD = 3 days;
//     uint24 public constant poolFee = 3000; // 0.3%
//     int24 constant TICK_SPACING = 60;

//     using OptionsBuilder for bytes;

//     uint256 public immutable MIN_SEND_AMOUNT = 1e17;
//     uint256 public immutable MIN_CREATE_AMOUNT = 1e15;

//     struct TokenInfo {
//         address creator;
//         bool initialLiquidityAdded;
//         uint256 positionId;
//         uint256 lockedLiquidityPercentage;
//         uint256 withdrawableLiquidity;
//         uint256 creationTime;
//         address pool;
//         uint128 liquidity;
//     }

//     struct Deposit {
//         address owner;
//         uint128 liquidity;
//         address token0;
//         address token1;
//     }

//     mapping(address => TokenInfo) public tokenInfo;
//     mapping(uint256 => Deposit) public deposits;

//     IUniswapV3Factory public immutable factory;
//     INonfungiblePositionManager public immutable nonfungiblePositionManager;
//     ISwapRouter02 public immutable swapRouter02;
//     IQuoterV2 public immutable quoterV2;
//     address public immutable WETH9;
//     address public immutable stargatePoolNative;
//     address public immutable endpointV2;

//     event AdditionalTokenData(
//         address indexed tokenAddress,
//         string name,
//         string symbol,
//         string description,
//         string imageUrl,
//         string twitter,
//         string telegram,
//         string website,
//         uint256 timestamp
//     );

//     event TokenUpdate(
//         address indexed tokenAddress,
//         address indexed creator,
//         uint160 sqrtPriceX96,
//         uint256 tokenPrice,
//         uint128 liquidity,
//         uint256 ethReserve,
//         uint256 tokenReserve,
//         uint256 totalSupply,
//         uint256 lockedLiquidityPercentage,
//         uint256 withdrawableLiquidity,
//         uint256 liquidatedLiquidity,
//         uint256 timestamp
//     );

//     enum TradeType {
//         Buy,
//         Sell
//     }

//     event TokenTrade(
//         address indexed tokenAddress,
//         address indexed trader,
//         TradeType tradeType,
//         uint256 inputAmount,
//         uint256 outputAmount,
//         uint256 timestamp
//     );

//     error InsufficientETHSent();
//     error TokenNotCreated();
//     error NotAuthorized();
//     error ZeroAmount();
//     error InvalidDestinationChain();
//     error InvalidTransactionType();
//     error PoolAlreadyExists();
//     error PoolDoesNotExist();
//     error InsufficientETHProvided();
//     error MustSendETH();
//     error InitialLiquidityAlreadyAdded();
//     error InvalidInitialSupply();
//     error InvalidLockedLiquidityPercentage();
//     error InsufficientWithdrawableLiquidity();
//     error WithdrawalTooEarly();
//     error MustProvideBothAmounts();
//     error InvalidTokenOrder();
//     error SqrtPriceOutOfBounds();
//     error NoLiquidityMinted();
//     error InvalidToken();
//     error TransferEthFailed();
//     error InvalidTransportMode();
//     error InsufficientBalance();
//     error InsufficientEthOrAmountToLowFromSwap();

//     constructor(
//         IUniswapV3Factory _factory,
//         INonfungiblePositionManager _nonfungiblePositionManager,
//         ISwapRouter02 _swapRouter02,
//         address _WETH9,
//         address _stargatePoolNative,
//         address _endpointV2
//     ) Ownable(msg.sender) {
//         factory = _factory;
//         nonfungiblePositionManager = _nonfungiblePositionManager;
//         swapRouter02 = _swapRouter02;
//         WETH9 = _WETH9;
//         stargatePoolNative = _stargatePoolNative;
//         endpointV2 = _endpointV2;
//     }

//     modifier onlyTokenCreator(address tokenAddress) {
//         if (msg.sender != tokenInfo[tokenAddress].creator) revert NotAuthorized();
//         _;
//     }

//     function createTokenAndAddLiquidity(
//         address tokenCreator,
//         string memory name,
//         string memory symbol,
//         string memory description,
//         string memory imageUrl,
//         string memory twitter,
//         string memory telegram,
//         string memory website,
//         uint256 initialSupply,
//         uint256 lockedLiquidityPercentage
//     ) public payable returns (address tokenAddress) {
//         return _createTokenAndAddLiquidity(
//             tokenCreator,
//             name,
//             symbol,
//             description,
//             imageUrl,
//             twitter,
//             telegram,
//             website,
//             initialSupply,
//             lockedLiquidityPercentage,
//             msg.value
//         );
//     }

//     function swapExactTokensForETH(address tokenAddress, uint256 tokenAmount, uint32 dstEid)
//         external
//         returns (uint256)
//     {
//         TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), tokenAmount);
//         TransferHelper.safeApprove(tokenAddress, address(swapRouter02), tokenAmount);

//         IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
//             tokenIn: tokenAddress,
//             tokenOut: WETH9,
//             fee: poolFee,
//             recipient: address(this),
//             amountIn: tokenAmount,
//             amountOutMinimum: 0,
//             sqrtPriceLimitX96: 0
//         });

//         uint256 amountOut = swapRouter02.exactInputSingle(params);

//         IWETH9(WETH9).withdraw(amountOut);

//         if (dstEid != 0) {
//             _sendViaStargate(dstEid, amountOut, msg.sender, tokenAddress, tokenAmount);
//         } else {
//             // Transfer ETH directly to the user on the current chain
//             (bool success,) = msg.sender.call{value: amountOut}("");
//             if (!success) {
//                 revert TransferEthFailed();
//             }
//             // Get price after trade

//             emit TokenTrade(tokenAddress, msg.sender, TradeType.Sell, tokenAmount, amountOut, block.timestamp);
//             _emitTokenUpdate(tokenAddress);
//         }

//         return amountOut;
//     }

//     function swapExactETHForTokens(address tokenAddress) external payable returns (uint256) {
//         if (msg.value == 0) revert MustSendETH();
//         _swapExactETHForTokens(tokenAddress, msg.value, msg.sender);
//     }

//     function _swapExactETHForTokens(address tokenAddress, uint256 amount, address recipient)
//         internal
//         returns (uint256)
//     {
//         if (amount == 0) revert MustSendETH();
//         // Get price before trade
//         _wrapETH(amount);

//         TransferHelper.safeApprove(WETH9, address(swapRouter02), amount);

//         IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
//             tokenIn: WETH9,
//             tokenOut: tokenAddress,
//             fee: poolFee,
//             recipient: recipient,
//             amountIn: amount,
//             amountOutMinimum: 0,
//             sqrtPriceLimitX96: 0
//         });

//         uint256 amountOut = swapRouter02.exactInputSingle(params);
//         // Get price after trade
//         emit TokenTrade(tokenAddress, recipient, TradeType.Buy, amount, amountOut, block.timestamp);
//         _emitTokenUpdate(tokenAddress);

//         return amountOut;
//     }

//     function _sendViaStargate(
//         uint32 dstEid,
//         uint256 amount,
//         address recipient,
//         address tokenAddress,
//         uint256 tokenAmount
//     ) internal {
//         if (dstEid == 0) {
//             revert InvalidDestinationChain();
//         }
//         if (amount == 0) {
//             revert ZeroAmount();
//         }

//         bytes32 to = addressToBytes32(recipient);

//         bytes memory composeMsg = abi.encode(bytes1(0x02), abi.encode(tokenAddress, tokenAmount, recipient));

//         bytes memory extraOptions = OptionsBuilder.newOptions().addExecutorLzComposeOption(0, 200_000, 0);

//         SendParam memory sendParam = SendParam({
//             dstEid: dstEid,
//             to: to,
//             amountLD: amount,
//             minAmountLD: amount * 800 / 1000, // Example: 0.5% slippage tolerance
//             extraOptions: extraOptions,
//             composeMsg: composeMsg,
//             oftCmd: ""
//         });

//         MessagingFee memory messagingFee = IStargate(stargatePoolNative).quoteSend(sendParam, false);

//         uint256 amountToSend = amount - messagingFee.nativeFee;
//         // Combined check for insufficient ETH and minimum send amount
//         if (amount <= messagingFee.nativeFee || amountToSend < MIN_SEND_AMOUNT) {
//             revert InsufficientEthOrAmountToLowFromSwap();
//         }
//         sendParam.amountLD = amountToSend;
//         sendParam.minAmountLD = amountToSend * 800 / 1000; // Adjust slippage tolerance

//         IStargate(stargatePoolNative).sendToken{value: amount}(sendParam, messagingFee, recipient);

//         emit TokenTrade(tokenAddress, msg.sender, TradeType.Sell, tokenAmount, amountToSend, block.timestamp);
//         _emitTokenUpdate(tokenAddress);
//     }

//     function lzCompose(
//         address _from,
//         bytes32 _guid,
//         bytes calldata _message,
//         address _executor,
//         bytes calldata _extraData
//     ) external payable {
//         if (_from != stargatePoolNative || msg.sender != endpointV2) {
//             revert NotAuthorized();
//         }
//         uint256 amountLD = OFTComposeMsgCodec.amountLD(_message);
//         bytes memory _composeMessage = OFTComposeMsgCodec.composeMsg(_message);

//         (bytes1 transactionType, bytes memory data) = abi.decode(_composeMessage, (bytes1, bytes));

//         if (transactionType == 0x00) {
//             (
//                 address tokenCreator,
//                 string memory name,
//                 string memory symbol,
//                 string memory description,
//                 string memory imageUrl,
//                 string memory twitter,
//                 string memory telegram,
//                 string memory website,
//                 uint256 initialSupply,
//                 uint256 lockedLiquidityPercentage
//             ) = abi.decode(data, (address, string, string, string, string, string, string, string, uint256, uint256));

//             address tokenAddress = _createTokenAndAddLiquidity(
//                 tokenCreator,
//                 name,
//                 symbol,
//                 description,
//                 imageUrl,
//                 twitter,
//                 telegram,
//                 website,
//                 initialSupply,
//                 lockedLiquidityPercentage,
//                 amountLD
//             );
//         } else if (transactionType == 0x01) {
//             (address tokenAddress, address recipient) = abi.decode(data, (address, address));
//             _swapExactETHForTokens(tokenAddress, amountLD, recipient);
//         } else if (transactionType == 0x02) {
//             (address tokenAddress, uint256 tokenAmount, address recipient) =
//                 abi.decode(data, (address, uint256, address));

//             // Get price after trade

//             emit TokenTrade(tokenAddress, msg.sender, TradeType.Sell, tokenAmount, amountLD, block.timestamp);
//             _emitTokenUpdate(tokenAddress);
//         } else {
//             revert InvalidTransactionType();
//         }
//     }

//     ////////////////////////////////////////
//     ////////////////////////////////////////////
//     /////////////////////////////////////////

//     function _createToken(
//         string memory name,
//         string memory symbol,
//         string memory description,
//         string memory imageUrl,
//         string memory twitter,
//         string memory telegram,
//         string memory website,
//         uint256 initialSupply
//     ) internal returns (address tokenAddress) {
//         bytes32 salt = keccak256(abi.encodePacked(msg.sender, block.timestamp));
//         tokenAddress = Create2.deploy(
//             0,
//             salt,
//             abi.encodePacked(
//                 type(CustomToken).creationCode,
//                 abi.encode(
//                     name, symbol, description, imageUrl, twitter, telegram, website, address(this), initialSupply
//                 )
//             )
//         );

//         tokenInfo[tokenAddress] = TokenInfo({
//             creator: msg.sender,
//             initialLiquidityAdded: false,
//             positionId: 0,
//             lockedLiquidityPercentage: 0,
//             withdrawableLiquidity: 0,
//             creationTime: block.timestamp,
//             pool: address(0),
//             liquidity: 0
//         });

//         return tokenAddress;
//     }

//     function _wrapETH(uint256 amount) internal {
//         IWETH9(WETH9).deposit{value: amount}();
//     }

//     function _setupPool(address tokenAddress, uint256 ethAmount) internal {
//         if (tokenInfo[tokenAddress].pool != address(0)) {
//             revert PoolAlreadyExists();
//         }

//         // Order tokens
//         (address token0, address token1) = orderTokens(tokenAddress);

//         // Create pool
//         address pool = factory.createPool(token0, token1, poolFee);
//         tokenInfo[tokenAddress].pool = pool;

//         // Get token balances
//         uint256 tokenAmount = IERC20Metadata(tokenAddress).balanceOf(address(this));
//         uint256 wethAmount = ethAmount; // Assuming ethAmount is in Wei

//         // Get token decimals
//         uint8 decimals0 = IERC20Metadata(token0).decimals();
//         uint8 decimals1 = IERC20Metadata(token1).decimals();

//         // Calculate the initial sqrtPriceX96
//         uint160 sqrtPriceX96 = calculateInitialSqrtPrice(
//             token0,
//             token1,
//             token0 == tokenAddress ? tokenAmount : wethAmount,
//             token1 == tokenAddress ? tokenAmount : wethAmount,
//             decimals0,
//             decimals1
//         );

//         // Initialize the pool with the calculated price
//         IUniswapV3Pool(pool).initialize(sqrtPriceX96);
//     }

//     uint256 constant PRECISION = 1e8;

//     function _createTokenAndAddLiquidity(
//         address tokenCreator,
//         string memory name,
//         string memory symbol,
//         string memory description,
//         string memory imageUrl,
//         string memory twitter,
//         string memory telegram,
//         string memory website,
//         uint256 initialSupply,
//         uint256 lockedLiquidityPercentage,
//         uint256 ethAmount
//     ) internal returns (address tokenAddress) {
//         if (ethAmount < MIN_CREATE_AMOUNT) {
//             revert InsufficientETHSent();
//         }
//         // Wrap the ETH to WETH9
//         _wrapETH(ethAmount);

//         if (initialSupply == 0) {
//             revert InvalidInitialSupply();
//         }

//         if (lockedLiquidityPercentage > 100) {
//             revert InvalidLockedLiquidityPercentage();
//         }

//         tokenAddress = _createToken(name, symbol, description, imageUrl, twitter, telegram, website, initialSupply);

//         tokenInfo[tokenAddress].lockedLiquidityPercentage = lockedLiquidityPercentage;
//         tokenInfo[tokenAddress].creationTime = block.timestamp;

//         _setupPool(tokenAddress, ethAmount);

//         (uint160 sqrtPriceX96, int24 tick) = getPoolSlot0(tokenAddress);
//         uint256 currentPrice = calculatePriceFromSqrtPriceX96(sqrtPriceX96, tokenAddress);

//         (int24 lower, int24 upper) = calculateTickRange(tick, currentPrice);

//         _addInitialLiquidity(tokenAddress, initialSupply, ethAmount, lower, upper, initialSupply, ethAmount);

//         emit AdditionalTokenData(
//             tokenAddress, name, symbol, description, imageUrl, twitter, telegram, website, block.timestamp
//         );
//         _emitTokenUpdate(tokenAddress);
//         return tokenAddress;
//     }

//     function getCurrentPrice(address tokenAddress) public pure returns (uint256) {
//         (uint160 sqrtPriceX96, int24 tick) = getPoolSlot0(tokenAddress);
//         uint256 currentPrice = calculatePriceFromSqrtPriceX96(sqrtPriceX96, tokenAddress);
//         return currentPrice;
//     }

//     function calculateInitialSqrtPrice(
//         address token0,
//         address token1,
//         uint256 amount0,
//         uint256 amount1,
//         uint8 decimals0,
//         uint8 decimals1
//     ) public pure returns (uint160) {
//         if (token0 >= token1) {
//             revert InvalidTokenOrder();
//         }
//         if (amount0 == 0 || amount1 == 0) {
//             revert ZeroAmount();
//         }

//         // Calculate the price ratio
//         uint256 priceRatio = (amount1 * PRECISION) / amount0;

//         // Adjust for decimals
//         uint256 price;
//         if (decimals0 >= decimals1) {
//             price = (priceRatio * 10 ** (decimals0 - decimals1));
//         } else {
//             price = priceRatio / 10 ** (decimals1 - decimals0);
//         }

//         // Calculate sqrt(price)
//         uint256 sqrtPrice = sqrt(price);

//         // Calculate sqrt_price_x_96
//         uint256 q = 2 ** 96;
//         uint160 sqrtPriceX96 = uint160((sqrtPrice * q) / sqrt(PRECISION));
//         if (sqrtPriceX96 < TickMath.MIN_SQRT_RATIO || sqrtPriceX96 > TickMath.MAX_SQRT_RATIO) {
//             revert SqrtPriceOutOfBounds();
//         }
//         return sqrtPriceX96;
//     }

//     function sqrt(uint256 x) public pure returns (uint256 y) {
//         uint256 z = (x + 1) / 2;
//         y = x;
//         while (z < y) {
//             y = z;
//             z = (x / z + z) / 2;
//         }
//     }

//     /// @notice Internal function to add initial liquidity
//     /// @param tokenAddress The address of the token to add liquidity for
//     /// @param tokenAmount The amount of tokens to add as liquidity
//     /// @param ethAmount The amount of ETH to add as liquidity

//     function _addInitialLiquidity(
//         address tokenAddress,
//         uint256 tokenAmount,
//         uint256 ethAmount,
//         int24 tickLower,
//         int24 tickUpper,
//         uint256 amount0Desired,
//         uint256 amount1Desired
//     ) internal {
//         if (tokenInfo[tokenAddress].initialLiquidityAdded) {
//             revert InitialLiquidityAlreadyAdded();
//         }
//         if (tokenAmount == 0 || ethAmount == 0) {
//             revert ZeroAmount();
//         }

//         (address token0, address token1) = orderTokens(tokenAddress);

//         TransferHelper.safeApprove(token0, address(nonfungiblePositionManager), amount0Desired);
//         TransferHelper.safeApprove(token1, address(nonfungiblePositionManager), amount1Desired);

//         INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
//             token0: token0,
//             token1: token1,
//             fee: poolFee,
//             tickLower: tickLower,
//             tickUpper: tickUpper,
//             amount0Desired: amount0Desired,
//             amount1Desired: amount1Desired,
//             amount0Min: 0,
//             amount1Min: 0,
//             recipient: address(this),
//             deadline: block.timestamp
//         });

//         (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = nonfungiblePositionManager.mint(params);

//         if (liquidity <= 0) {
//             revert NoLiquidityMinted();
//         }

//         tokenInfo[tokenAddress].positionId = tokenId;
//         tokenInfo[tokenAddress].liquidity = liquidity;
//         tokenInfo[tokenAddress].initialLiquidityAdded = true;
//         tokenInfo[tokenAddress].withdrawableLiquidity =
//             liquidity * (100 - tokenInfo[tokenAddress].lockedLiquidityPercentage) / 100;

//         deposits[tokenId] = Deposit({owner: msg.sender, liquidity: liquidity, token0: token0, token1: token1});
//     }

//     function addressToBytes32(address _addr) internal pure returns (bytes32) {
//         return bytes32(uint256(uint160(_addr)));
//     }

//     function getPoolReserves(address tokenAddress) public view returns (uint256 tokenReserve, uint256 ethReserve) {
//         address pool = tokenInfo[tokenAddress].pool;
//         (address token0, address token1) = orderTokens(tokenAddress);

//         uint256 balance0 = IERC20(token0).balanceOf(pool);
//         uint256 balance1 = IERC20(token1).balanceOf(pool);

//         if (token0 == tokenAddress) {
//             tokenReserve = balance0;
//             ethReserve = balance1;
//         } else {
//             tokenReserve = balance1;
//             ethReserve = balance0;
//         }
//     }

//     function _emitTokenUpdate(address tokenAddress) internal {
//         address pool = tokenInfo[tokenAddress].pool;
//         (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(pool).slot0();

//         uint256 tokenPrice = calculatePriceFromSqrtPriceX96(sqrtPriceX96, tokenAddress);
//         uint128 liquidity = IUniswapV3Pool(pool).liquidity();

//         (uint256 tokenReserve, uint256 ethReserve) = getPoolReserves(tokenAddress);

//         uint256 totalSupply = IERC20(tokenAddress).totalSupply();
//         uint256 liquidatedLiquidity = tokenInfo[tokenAddress].liquidity - tokenInfo[tokenAddress].withdrawableLiquidity;
//         address creator = tokenInfo[tokenAddress].creator;
//         emit TokenUpdate(
//             tokenAddress,
//             creator,
//             sqrtPriceX96,
//             tokenPrice,
//             liquidity,
//             ethReserve,
//             tokenReserve,
//             totalSupply,
//             tokenInfo[tokenAddress].lockedLiquidityPercentage,
//             tokenInfo[tokenAddress].withdrawableLiquidity,
//             liquidatedLiquidity,
//             block.timestamp
//         );
//     }

//     function onERC721Received(address, /*operator*/ address, /*from*/ uint256, /* tokenId*/ bytes calldata)
//         external
//         pure
//         override
//         returns (bytes4)
//     {
//         // Here we can add any logic we want to execute when receiving an NFT
//         // For now, we'll just create a deposit

//         // Return the function selector to indicate successful receipt
//         return this.onERC721Received.selector;
//     }

//     function getTokenPrice(address tokenAddress) external view returns (uint256) {
//         address pool = tokenInfo[tokenAddress].pool;
//         if (pool == address(0)) revert PoolDoesNotExist();
//         (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(pool).slot0();
//         return uint256(sqrtPriceX96) ** 2 * 1e18 / 2 ** 192;
//     }

//     function orderTokens(address tokenAddress) public view returns (address token0, address token1) {
//         if (tokenAddress < WETH9) {
//             token0 = tokenAddress;
//             token1 = WETH9;
//         } else {
//             token0 = WETH9;
//             token1 = tokenAddress;
//         }
//     }

//     receive() external payable {}

//     ////////////////////////////////////////////////////////////////////////////
//     //////// THESE ARE TEST FUNCTION...WOULD BE REMOVED BEFORE DEPLOYMENTS/////
//     ///////////////////////////////////////////////////////////////////////////
//     // Add this function to the MainEngine contract

//     function getPoolAddress(address tokenAddress) public view returns (address) {
//         return tokenInfo[tokenAddress].pool;
//     }

//     function getPoolLiquidity(address tokenAddress) public view returns (uint128) {
//         return tokenInfo[tokenAddress].liquidity;
//     }

//     function getTokenBalance(address tokenAddress, address account) public view returns (uint256) {
//         return IERC20(tokenAddress).balanceOf(account);
//     }

//     function getPoolSlot0(address tokenAddress) public view returns (uint160, int24) {
//         address pool = getPoolAddress(tokenAddress);
//         uint160 sqrtPriceX96;
//         int24 tick;
//         (sqrtPriceX96, tick,,,,,) = IUniswapV3Pool(pool).slot0();
//         return (sqrtPriceX96, tick);
//     }

//     function calculateTickRange(int24 currentTick, uint256 currentPrice)
//         public
//         pure
//         returns (int24 tickLower, int24 tickUpper)
//     {
//         // Define a range around the current price (e.g., ±10%)
//         uint256 priceRange = (currentPrice * 10) / 100;

//         // Calculate tick range based on price range
//         int24 tickRange = int24(int256((priceRange * uint256(int256(TICK_SPACING))) / currentPrice)) * 1000;
//         tickLower = ((currentTick - tickRange) / TICK_SPACING) * TICK_SPACING;
//         tickUpper = ((currentTick + tickRange) / TICK_SPACING) * TICK_SPACING;

//         // Calculate and log the tick range
//         int24 tickDifference = tickUpper - tickLower;

//         return (tickLower, tickUpper);
//     }

//     function calculatePriceFromSqrtPriceX96(uint160 sqrtPriceX96, address token) public view returns (uint256) {
//         if (token == WETH9) {
//             revert InvalidToken();
//         }

//         uint8 tokenDecimals = IERC20Metadata(token).decimals();

//         uint256 q = 2 ** 96;

//         uint256 p = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96) * 10 ** 8) / (q * q);

//         uint256 precision_p = p * 10 ** tokenDecimals / 1e8;

//         return precision_p;
//     }
// }
